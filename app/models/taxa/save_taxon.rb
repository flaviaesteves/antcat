# Formerly taxon_mother.rb
# A TaxonMother is responsible for creating/saving
# an object web of objects, starting with Taxon

class Taxa::SaveTaxon
  include UndoTracker

  def initialize taxon
    @taxon = taxon
  end

  # previous_combination will be a pointer to the species taxon record
  # if non-nil
  def save_taxon params, previous_combination = nil
    change_type = nil
    Taxon.transaction do
      update_name params.delete :name_attributes
      update_parent params.delete :parent_name_attributes
      update_current_valid_taxon params.delete :current_valid_taxon_name_attributes
      update_homonym_replaced_by params.delete :homonym_replaced_by_name_attributes
      update_protonym params.delete :protonym_attributes
      update_type_name params.delete :type_name_attributes
      update_name_status_flags params

      if @taxon.new_record?
        change_type = :create
        @taxon.taxon_state = TaxonState.new
        @taxon.taxon_state.deleted = false
        @taxon.taxon_state.id = @taxon.id
      else
        # we might want to get smarter about this
        change_type = :update
      end
      @taxon.taxon_state.review_state = :waiting

      change = setup_change @taxon, change_type
      change_id = change.id
      if @taxon.auto_generated
        remove_auto_generated
      end
      @taxon.save!
      # paper_trail is dumb. When a new object is created, it has no "object".
      # So, if you undo the first change, and try to reify the previous one,
      # you end up with no object! touch_with_version gives us one, but
      # Just for the taxa, not the protonym or other changable objects.
      if change_type == :create
        @taxon.touch_with_version
      end

      # TODO: The below may not be being used
      if change_type == :create
        change.user_changed_taxon_id = @taxon.id
        change.save
      end

      # for each taxon save, we need to have a change_id AND we need to create a new
      # transaction record
      if previous_combination
        # the taxon that was just saved is a new combination. Update the
        # previous combination's status, associated it with the new
        # combination, and transfer all taxon history and synonyms

        # find all taxa that list previous_combination.id as
        # current_valid_taxon_id and update them
        Taxon.where(current_valid_taxon_id: previous_combination.id).each do |taxon_to_update|
          update_elements(params, taxon_to_update, get_status_string(taxon_to_update), change_id)
        end

        # since the previous doesn't have a pointer to current_valid_taxon, it won't show up
        # in the above search. If it's the protonym, set it propertly.
        if previous_combination.id == @taxon.protonym.id
          update_elements(params, previous_combination, Status['original combination'].to_s, change_id)
        else
          update_elements(params, previous_combination, Status['obsolete combination'].to_s, change_id)
        end
      end
      save_taxon_children @taxon
    end
  end

  private
    def update_elements _params, taxon_to_update, status_string, _change_id
      taxon_to_update.status = status_string
      taxon_to_update.current_valid_taxon = @taxon
      TaxonHistoryItem.where(taxon_id: taxon_to_update.id).update_all(taxon_id: @taxon.id)
      Synonym.where(senior_synonym_id: taxon_to_update.id).update_all(senior_synonym_id: @taxon.id)
      Synonym.where(junior_synonym_id: taxon_to_update.id).update_all(junior_synonym_id: @taxon.id)
      taxon_to_update.save
    end

    def get_status_string taxon_to_update
      if Status[taxon_to_update] == Status['original combination']
        Status['original combination'].to_s
      else
        Status['obsolete combination'].to_s
      end
    end

    ####################################
    def update_name attributes
      attributes[:name_id] = attributes.delete :id
      gender = attributes.delete :gender
      @taxon.name.gender = gender.blank? ? nil : gender
      @taxon.attributes = attributes
    end

    def update_name_status_flags attributes
      attributes[:incertae_sedis_in] = nil unless attributes[:incertae_sedis_in].present?
      @taxon.attributes = attributes
      @taxon.headline_notes_taxt = Taxt.from_editable attributes.delete :headline_notes_taxt
      if attributes[:type_taxt]
        @taxon.type_taxt = Taxt.from_editable attributes.delete :type_taxt
      end
    end

    def update_parent attributes
      return unless attributes
      @taxon.update_parent Taxon.find_by_name_id attributes[:id]
    rescue Taxon::TaxonExists
      @taxon.errors[:base] = "This name is in use by another taxon"
      raise
    end

    def update_homonym_replaced_by attributes
      replacement_id = attributes[:id]
      replacement = replacement_id.present? ? Taxon.find_by_name_id(replacement_id) : nil
      @taxon.homonym_replaced_by = replacement
    end

    def update_current_valid_taxon attributes
      replacement_id = attributes[:id]
      replacement = replacement_id.present? ? Taxon.find_by_name_id(replacement_id) : nil
      @taxon.current_valid_taxon = replacement
    end

    def update_protonym attributes
      attributes[:name_id] = attributes.delete(:name_attributes)[:id]
      update_protonym_authorship attributes.delete :authorship_attributes
      @taxon.protonym.attributes = attributes
    end

    def update_protonym_authorship attributes
      return unless @taxon.protonym.authorship
      attributes[:reference_id] = attributes.delete(:reference_attributes)[:id]
      return if attributes[:reference_id].blank? and @taxon.protonym.authorship.reference.blank?
      if attributes[:notes_taxt]
        @taxon.protonym.authorship.notes_taxt = Taxt.from_editable attributes.delete :notes_taxt
      end
      @taxon.protonym.authorship.attributes = attributes
    end

    def update_type_name attributes
      # ugly way to handle optional, but possibly pre-built, subobject
      if @taxon.type_name && @taxon.type_name.new_record? && (!attributes or attributes[:id] == '')
        @taxon.type_name = nil
        return
      end
      # Why do we hit this case?
      if attributes
        attributes[:type_name_id] = attributes.delete :id
        @taxon.attributes = attributes
      end
    end

    def remove_auto_generated
      @taxon.auto_generated = false
      name = @taxon.name
      if name.auto_generated
        name.auto_generated = false
        name.save
      end
      synonyms = Synonym.where(senior_synonym_id: @taxon.id)
      synonyms.each do |synonym|
        if synonym.auto_generated
          synonym.auto_generated = false
          synonym.save
        end
      end

      synonyms = Synonym.where(junior_synonym_id: @taxon.id)
      synonyms.each do |synonym|
        if synonym.auto_generated
          synonym.auto_generated = false
          synonym.save
        end
      end
    end

    def save_taxon_children taxon
      return if taxon.kind_of?(Family) || taxon.kind_of?(Subspecies)
      taxon.children.each do |child|
        child.save
        save_taxon_children child
      end
    end
end
