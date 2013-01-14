# coding: UTF-8
class Family < Taxon
  include Updater

  def self.import data
    name = Name.import family_name: 'Formicidae'
    transaction do
      if family = find_by_name(name.name)
        family.update_data data
      else
        attributes = {
          name:                name,
          fossil:              false,
          status:              'valid',
          #protonym:            Protonym.import(data[:protonym]),
          headline_notes_taxt: Importers::Bolton::Catalog::TextToTaxt.convert(data[:note]),
        }
        attributes.merge! get_type_attributes :type_genus, data
        family = create! attributes
        data[:history].each do |item|
          family.history_items.create! taxt: item
        end
      end
      family
    end
  end

  def update_data data
    attributes = {}
    update_field 'fossil', data[:fossil], attributes
    update_field 'status', data[:status], attributes
    update_taxt_field 'headline_notes_taxt', data[:note], attributes
    type_attributes = self.class.get_type_attributes :type_genus, data
    update_name_field 'type_name', type_attributes[:type_name], attributes
    update_field 'type_taxt', type_attributes[:type_taxt], attributes
    update_field 'type_fossil', type_attributes[:type_fossil], attributes
    update_attributes attributes
    protonym.update_data data[:protonym]
    update_history data[:history]
  end

  def genera
    Genus.without_subfamily.ordered_by_name
  end

  def subfamilies
    Subfamily.ordered_by_name
  end

  def statistics
    get_statistics Subfamily, Tribe, Genus, Species, Subspecies
  end

  def get_statistics *ranks
    ranks.inject({}) do |statistics, klass|
      count = klass.count :group => [:fossil, :status]
      self.class.massage_count count, Rank[klass].to_sym(:plural), statistics
      statistics
    end
  end

end
