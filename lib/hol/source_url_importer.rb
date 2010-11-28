require 'curl'

class Hol::SourceUrlImporter

  attr_reader :success_count,
              :book_failure_count, :unknown_reference_failure_count, :pdf_not_found_failure_count,
              :missing_author_failure_count, :already_imported_count

  def initialize show_progress = false
    Progress.init show_progress, Reference.count
    @bibliography = Hol::Bibliography.new
    @success_count = @unmatched_count =
      @book_failure_count = @unknown_reference_failure_count = @pdf_not_found_failure_count =
      @missing_author_failure_count = @already_imported_count = 0
    @missing_authors = []
  end

  def import
    Progress.puts "Importing source URLs..."
    Reference.sorted_by_author_name.each do |reference|
      result = import_source_url_for reference
      show_progress reference, result
    end
    show_results
  end

  def import_source_url_for reference
    if reference.source_url?
      result = {:status => :already_imported}
    else
      result = @bibliography.match reference
      see_if_pdf_exists result
      reference.update_attribute(:source_url, result[:source_url])
    end
    update_counts reference, result
  end

  def missing_authors
    @missing_authors.uniq.sort
  end

  def processed_count
    Progress.processed_count
  end

  private
  def see_if_pdf_exists result
    return unless result[:source_url]
    unless source_url_exists? result[:source_url]
      result[:source_url] = nil
      result[:status] = :pdf_not_found
    end
  end

  def update_counts reference, result
    if result[:source_url]
      @success_count += 1
      return '* OK *'
    elsif result[:status] == :already_imported
      @already_imported_count += 1
      @success_count += 1
      return 'Already'
    else
      if result[:status] == Hol::Bibliography::NO_ENTRIES_FOR_AUTHOR
        @missing_authors << reference.author_names.first.name
        @missing_author_failure_count += 1
        return 'Author'
      elsif result[:status] == :pdf_not_found
        @pdf_not_found_failure_count += 1
        return 'PDF'
      elsif reference.kind_of? BookReference
        @book_failure_count += 1
        return 'Book'
      elsif reference.kind_of? UnknownReference
        @unknown_reference_failure_count += 1
        return 'Unknown'
      else
        @unmatched_count += 1
        return 'Unmatched'
      end
    end
  end

  def show_progress reference, result
    Progress.tally
    rate = Progress.rate
    time_left = Progress.time_left
    success_percent = Progress.percent @success_count, Progress.processed_count
    result = result.ljust(9)
    success = (success_percent + ' success').rjust(12)
    rate = rate.rjust(8)
    time_left = time_left.rjust(13)
    Progress.puts "#{result} #{success} #{rate} #{time_left} #{reference}"
  end

  def show_results
    Progress.puts
    Progress.puts "#{missing_authors.size} missing authors:\n#{missing_authors.join("\n")}"

    Progress.puts
    rate = Progress.rate
    elapsed = Progress.elapsed
    Progress.puts "#{Progress.processed_count} processed in #{elapsed} (#{rate})"

    Progress.puts Progress.count(@success_count, Progress.processed_count, 'successful')
    Progress.puts Progress.count(@already_imported_count, Progress.processed_count, 'already imported')
    Progress.puts Progress.count(@missing_author_failure_count, Progress.processed_count, 'author not found')
    Progress.puts Progress.count(@unmatched_count, Progress.processed_count, 'unmatched')
    Progress.puts Progress.count(@unknown_reference_failure_count, Progress.processed_count, 'unknown references')
    Progress.puts Progress.count(@book_failure_count, Progress.processed_count, 'book references')
    Progress.puts Progress.count(@pdf_not_found_failure_count, Progress.processed_count, 'PDF not found')
  end

  def source_url_exists? source_url
    (200..399).include? Curl::Easy.http_head(source_url).response_code
  end
end
