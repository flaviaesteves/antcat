# coding: UTF-8
class ReviewStatus

  def initialize attributes
    @attributes = attributes
  end

  def being_reviewed?
    @attributes[:value] == 'being reviewed'
  end

  def reviewed?
    @attributes[:value] == 'reviewed'
  end

  def value
    @attributes[:value]
  end

  def to_s
    value
  end

  def display_string
    @attributes[:display_string]
  end

  def self.find string
    review_statuses.find {|review_status| review_status.value == string} or raise "Couldn't find #{string}"
  end
  class << self; alias_method :[], :find end

  def self.review_statuses
    @_review_statuses ||= [
      ReviewStatus.new(value: 'reviewed',       display_string: 'Reviewed'),
      ReviewStatus.new(value: 'being reviewed', display_string: 'Being reviewed'),
      ReviewStatus.new(value: '',               display_string: ''),
      ReviewStatus.new(value: nil,              display_string: ''),
    ]
  end

end