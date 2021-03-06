class ArticleReference < Reference
  belongs_to :journal

  validates_presence_of :year, :journal, :series_volume_issue, :pagination
  attr_accessible :year, :journal, :doi

  def start_page
    page_parts[:start]
  end

  def end_page
    page_parts[:end]
  end

  def series
    series_volume_issue_parts[:series]
  end

  def volume
    series_volume_issue_parts[:volume]
  end

  def issue
    series_volume_issue_parts[:issue]
  end

  private
    def series_volume_issue_parts
      @series_volume_issue_parts ||= Parsers::ArticleCitationParser.get_series_volume_issue_parts series_volume_issue
    end

    def page_parts
      @page_parts ||= Parsers::ArticleCitationParser.get_page_parts pagination
    end
end
