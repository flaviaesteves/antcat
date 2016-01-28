class Protonym < ActiveRecord::Base
  include UndoTracker

  has_one :taxon # Taxon has a protnym_id
  belongs_to :authorship, class_name: 'Citation', dependent: :destroy # this model has a single authorship_id that references the "Citation" table
  validates :authorship, presence: true
  belongs_to :name
  validates :name, presence: true # Protonym has a name_id
  accepts_nested_attributes_for :name, :authorship
  has_paper_trail meta: { change_id: :get_current_change_id }

  attr_accessible :fossil, :sic, :locality, :id, :name_id, :name, :authorship, :taxon

  # allow_nil should not be needed (per `validates :authorship, presence: true`),
  # but protonym_spec.rb uses `build_stubbed`, so we need it for the moment.
  delegate :authorship_string, :authorship_html_string, :author_last_names_string, :year,
    to: :authorship, allow_nil: true

end
