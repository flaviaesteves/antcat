module TaxonHelper
  def sort_by_status_and_name taxa
    taxa.sort do |a, b|
      if a.status == b.status
        a.name.name <=> b.name.name # name ascending
      else
        b.status <=> a.status # status descending
      end
    end
  end

  def biogeographic_region_options_for_select value = nil
    options_for_select([[nil, nil]], value) <<
    options_for_select(BiogeographicRegion::REGIONS, value)
  end

  def add_taxon_button taxon, collision_resolution
    child_ranks = { family:    "subfamily",
                    subfamily: "genus",
                    tribe:     "genus",
                    genus:     "species",
                    subgenus:  "species",
                    species:   "subspecies" }

    rank_to_add = child_ranks[taxon.rank.to_sym]
    return unless rank_to_add.present?

    # Hopefully not needed, but leaving this extra check here to be on the safe side
    collision_resolution = nil if collision_resolution.blank?

    link_to "Add #{rank_to_add}", new_taxa_path(rank_to_create: rank_to_add,
      parent_id: taxon.id, collision_resolution: collision_resolution), class: "btn-new"
  end

  def add_tribe_button taxon
    return unless taxon.kind_of? Subfamily

    link_to "Add tribe", new_taxa_path(rank_to_create: 'tribe', parent_id: taxon.id),
    class: "btn-new"
  end

  def convert_to_subspecies_button taxon
    return unless taxon.kind_of? Species

    link_to 'Convert to subspecies', new_taxa_convert_to_subspecies_path(taxon),
    class: "btn-new"
  end

  def elevate_to_species_button taxon
    return unless taxon.kind_of? Subspecies

    link_to 'Elevate to species', elevate_to_species_taxa_path(taxon),
      method: :put, class: "btn-new", data: { confirm: <<-MSG.squish }
        Are you sure you want to elevate this subspecies to species?
      MSG
  end

  def delete_unreferenced_taxon_button taxon
    return unless taxon.nontaxt_references.empty? # TODO check taxt references

    link_to 'Delete', destroy_unreferenced_taxa_path(taxon), method: :delete,
      class: "btn-delete", data: { confirm: <<-MSG.squish }
        Are you sure you want to delete this taxon? Note: It may take a few
        moments to check that this taxon isn't being referenced.
      MSG
  end

  def taxon_link_or_deleted_string id, deleted_label = nil
    if Taxon.exists? id
      Taxon.find(id).decorate.link_to_taxon
    else
      deleted_label || "##{id} [deleted]"
    end
  end
end
