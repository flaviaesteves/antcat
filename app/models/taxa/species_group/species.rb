class Species < SpeciesGroupTaxon
  include Formatters::RefactorFormatter

  has_many :subspecies
  attr_accessible :name, :protonym, :genus, :current_valid_taxon, :homonym_replaced_by, :type

  def parent
    subgenus || genus
  end

  def parent= parent_taxon
    if parent_taxon.is_a? Subgenus
      self.subgenus = parent_taxon
      self.genus = subgenus.parent
    else
      self.genus = parent_taxon
    end
  end

  def siblings
    genus.species
  end

  def children
    subspecies
  end

  def statistics
    get_statistics [:subspecies]
  end

  def become_subspecies_of species
    new_name_string = "#{species.genus.name} #{species.name.epithet} #{name.epithet}"
    if Subspecies.find_by_name new_name_string
      raise TaxonExists.new "The subspecies '#{new_name_string}' already exists."
    end

    new_name = SubspeciesName.find_by_name new_name_string
    unless new_name
      new_name = SubspeciesName.new
      new_name.update_attributes name: new_name_string,
                                 name_html: italicize(new_name_string),
                                 epithet: name.epithet,
                                 epithet_html: name.epithet_html,
                                 epithets: "#{species.name.epithet} #{name.epithet}"
      new_name.save
    end

    create_convert_species_to_subspecies_activity new_name

    self.update_columns name_id: new_name.id,
                        species_id: species.id,
                        name_cache: new_name.name,
                        name_html_cache: new_name.name_html,
                        type: 'Subspecies'
  end

  private
    def create_convert_species_to_subspecies_activity new_name
      create_activity :convert_species_to_subspecies,
        name_was: name_html_cache,
        name: new_name.name_html
    end
end
