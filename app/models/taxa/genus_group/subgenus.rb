class Subgenus < GenusGroupTaxon
  belongs_to :genus
  validates_presence_of :genus
  has_many :species
  attr_accessible :subfamily, :tribe, :genus, :homonym_replaced_by

  def parent
    genus
  end

  # TODO not used
  def species_group_descendants
    Taxon.where(subgenus_id: id).where.not(type: 'Subgenus')
      .includes(:name).order('names.epithet')
  end

  def statistics; end
end
