class Status
  def initialize hash
    @hash = hash
  end

  def to_s *options
    numeric_argument = options.find { |option| option.kind_of? Numeric }
    options << :plural if numeric_argument && numeric_argument > 1 #hmm

    if options.include?(:plural)
      @hash[:plural_label]
    else
      @hash[:label]
    end.dup
  end

  def self.ordered_statuses
    statuses.map &:to_s
  end

  def includes? identifier
    @hash.values.include? identifier
  end

  def self.find identifier
    identifier = identifier.status if identifier.kind_of? Taxon
    identifier = identifier.first.status if identifier.kind_of? Enumerable
    identifier = identifier.first.status if identifier.kind_of? ActiveRecord::Relation

    statuses.find { |status| status.includes? identifier } or raise "Couldn't find status for '#{identifier}'"
  end
  class << self; alias_method :[], :find end

  def self.options_for_select
    statuses.map &:option_for_select
  end

  def option_for_select
    [@hash[:label], @hash[:label]]
  end

  # TODO joe - see if we can not display "unavailable uncategorized"
  def self.statuses
    @_statuses ||= [
      ['valid',                     'valid'],
      ['synonym',                   'synonyms'],
      ['homonym',                   'homonyms'],
      ['unidentifiable',            'unidentifiable'],
      ['unavailable',               'unavailable'],
      ['excluded from Formicidae',  'excluded from Formicidae'],
      ['original combination',      'original combinations'],
      ['collective group name',     'collective group names'],
      ['obsolete combination',      'obsolete combinations'],
      ['unavailable misspelling',   'unavailable misspelling'],
      ['nonconforming synonym',     'nonconforming synonym'],
      ['unavailable uncategorized', 'unavailable uncategorized']
    ].map do |label, plural_label|
      Status.new label: label, plural_label: plural_label
    end
  end
end
