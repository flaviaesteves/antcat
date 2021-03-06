require_dependency 'references/reference_has_document'
require_dependency 'references/reference_search'
require_dependency 'references/reference_utility'
require_dependency 'references/reference_workflow'

class Reference < ActiveRecord::Base
  include UndoTracker
  include ReferenceComparable

  include Feed::Trackable
  tracked parameters: ->(reference) do
    { name: reference.decorate.key }
  end

  attr_accessor :publisher_string
  attr_accessor :journal_name
  has_paper_trail meta: { change_id: :get_current_change_id }

  attr_accessible :citation_year,
                  :title,
                  :journal_name,
                  :series_volume_issue,
                  :publisher_string,
                  :pages_in,
                  :nesting_reference_id,
                  :citation,
                  :document_attributes,
                  :public_notes,
                  :editor_notes,
                  :taxonomic_notes,
                  :cite_code,
                  :possess,
                  :date,
                  :author_names,
                  :author_names_suffix,
                  :pagination,
                  :review_state,
                  :doi

  before_save { |record| CleanNewlines.clean_newlines record, :editor_notes, :public_notes, :taxonomic_notes, :title, :citation }
  before_destroy :check_not_referenced

  has_many :reference_author_names, -> { order :position }

  has_many :author_names,
           -> { order 'reference_author_names.position' },
           through: :reference_author_names,
           after_add: :refresh_author_names_caches,
           after_remove: :refresh_author_names_caches
  belongs_to :journal
  belongs_to :publisher

  def nestees
    Reference.where(nesting_reference_id: id)
  end

  scope :sorted_by_principal_author_last_name, -> { order(:principal_author_last_name_cache) }
  scope :with_principal_author_last_name, lambda { |last_name| where(principal_author_last_name_cache: last_name) }

  before_validation :set_year_from_citation_year, :strip_text_fields
  validates :title, presence: true, if: Proc.new { |record| record.class.requires_title }

  def self.requires_title
    true
  end

  before_save :set_author_names_caches
  before_destroy :check_not_nested

  def to_s
    "#{author_names_string} #{citation_year}. #{id}."
  end

  def authors reload = false
    author_names(reload).map &:author
  end

  def author
    principal_author_last_name
  end

  def author_names_string
    author_names_string_cache
  end

  def author_names_string=(string)
    self.author_names_string_cache = string
  end

  def principal_author_last_name
    principal_author_last_name_cache
  end

  # TODO we should probably have #year [int] and something
  # like #non_standard_year [string] instead of this +
  # #year + #citation_year.
  def short_citation_year
    if citation_year.present?
      citation_year.gsub %r{ .*$}, ''
    else
      "[no year]"
    end
  end

  # update (including observed updates)
  def refresh_author_names_caches(*)
    string, principal_author_last_name = make_author_names_caches
    update_attribute :author_names_string_cache, string
    update_attribute :principal_author_last_name_cache, principal_author_last_name
  end

  ## utility
  # Called by controller to parse an input string for author names and suffix
  # Returns hash of parse result, or adds to the reference's errors and raises
  def parse_author_names_and_suffix author_names_string
    author_names_and_suffix = AuthorName.import_author_names_string author_names_string.dup
    if author_names_and_suffix[:author_names].empty? && author_names_string.present?
      errors.add :author_names_string, "couldn't be parsed. Please post a message on http://groups.google.com/group/antcat/, and we'll fix it!"
      self.author_names_string = author_names_string
      raise ActiveRecord::RecordInvalid.new self
    end
    author_names_and_suffix
  end

  def check_for_duplicate
    duplicates = DuplicateMatcher.new.match self
    return unless duplicates.present?

    duplicate = Reference.find duplicates.first[:match].id
    errors.add :base, "This may be a duplicate of #{duplicate.decorate.format} #{duplicate.id}.<br>To save, click \"Save Anyway\"".html_safe
    true
  end

  def self.citation_year_to_year citation_year
    if citation_year.blank?
      nil
    elsif match = citation_year.match(/\["(\d{4})"\]/)
      match[1]
    else
      citation_year.to_i
    end
  end

  def self.approve_all
    count = Reference.where.not(review_state: "reviewed").count

    Feed::Activity.without_tracking do
      Reference.where.not(review_state: "reviewed").find_each do |reference|
        reference.approve
      end
    end

    Feed::Activity.create_activity :approve_all_references, count: count
  end

  # TODO merge into Workflow
  # Only for .approve_all, which approves all unreviewed
  # references of any state (which Workflow doesn't allow).
  def approve
    review_state = "reviewed"
    save!
    Feed::Activity.with_tracking do
      create_activity :finish_reviewing
    end
  end

  private
    def check_not_referenced
      return true unless has_any_references?

      # TODO list which items
      errors.add :base, "This reference can't be deleted, as there are other references to it."
      return false
    end

    def check_not_nested
      nesting_reference = NestedReference.find_by_nesting_reference_id id
      if nesting_reference
        errors.add :base, "This reference can't be deleted because it's nested in #{nesting_reference}"
      end
      nesting_reference.nil?
    end

    def strip_text_fields
      [:title, :public_notes, :editor_notes, :taxonomic_notes, :citation].each do |field|
        value = self[field]
        next unless value.present?
        value.gsub! /(\n|\r|\n\r|\r\n)/, ' '
        value.strip!
        value.squeeze! ' '
        self[field] = value
      end
    end

    def set_year_from_citation_year
      self.year = self.class.citation_year_to_year citation_year
    end

    def set_author_names_caches(*)
      self.author_names_string_cache, self.principal_author_last_name_cache = make_author_names_caches
    end

    def make_author_names_caches
      string = author_names.map(&:name).join('; ')
      string << author_names_suffix if author_names_suffix.present?
      first_author_name = author_names.first
      last_name = first_author_name && first_author_name.last_name
      return string, last_name
    end

    # Expensive method
    def reference_references return_true_or_false: false
      return_early = return_true_or_false

      references = []
      Taxt.taxt_fields.each do |klass, fields|
        klass.send(:all).each do |record|
          fields.each do |field|
            next unless record[field]
            if record[field] =~ /{ref #{id}}/
              references << { table: klass.table_name, id: record[:id], field: field }
              return true if return_early
            end
          end
        end
      end

      Citation.where(reference_id: id).all.each do |record|
        references << { table: Citation.table_name, id: record[:id], field: :reference_id }
        return true if return_early
      end

      NestedReference.where(nesting_reference_id: id).all.each do |record|
        references << { table: 'references', id: record[:id], field: :nesting_reference_id }
        return true if return_early
      end
      return false if return_early
      references
    end

    def has_any_references?
      reference_references return_true_or_false: true
    end

    class DuplicateMatcher < ReferenceMatcher
      def min_similarity
        0.5
      end
    end
end
