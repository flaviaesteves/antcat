module ApplicationHelper
  include LinkHelper

  def make_title title
    string = ''.html_safe
    string << "#{title} - " if title
    string << "AntCat"
    string << (Rails.env.production? ? '' : " (#{Rails.env})")
    string
  end

  def make_link_menu *items
    content_tag :span do |content|
      items.flatten.reduce(''.html_safe) do |string, item|
        string << ' | '.html_safe unless string.empty?
        string << item
      end
    end
  end

  def pluralize_with_delimiters count, singular, plural = nil
    word = if count == 1
      singular
    else
      plural || singular.pluralize
    end
    "#{number_with_delimiter(count)} #{word}"
  end

  # TODO move to MergeAuthorsHelper, or nuke and replace with `pluralize_with_delimiters`
  def count_and_noun collection, noun
    quantity = collection.present? ? collection.count.to_s : 'no'
    noun << 's' unless collection.count == 1
    "#{quantity} #{noun}"
  end

  def add_period_if_necessary string
    return unless string.present?
    return string + '.' unless string[-1..-1] =~ /[.!?]/
    string
  end

  def italicize string
    content_tag :i, string
  end

  def unitalicize string
    raise "Can't unitalicize an unsafe string" unless string.html_safe?
    string = string.dup
    string.gsub!('<i>', '')
    string.gsub!('</i>', '')
    string.html_safe
  end

  # First attempt at creating a spinner that works on all elements.
  # Add .has-spinner to the button/link/element and call this method inside that element.
  # To be improved once all buttons are more consistently formatted site-wide.
  def spinner_icon
    "<span class='spinner'><i class='fa fa-refresh fa-spin'></i></span>".html_safe
  end

  # Used when more than one button can trigger the spinner.
  def shared_spinner_icon
    "<span class='shared-spinner'><i class='fa fa-refresh fa-spin'></i></span>".html_safe
  end

  def foundation_class_for flash_type
    case flash_type.to_sym
    when :success, :notice
      "primary"
    when :error, :alert, :warning
      "alert"
    else
      "secondary"
    end
  end

  # dev-specific CSS. Disable by suffixing the url with ?prod=pizza,
  # or toggle on/off from the Editor's Panel.
  def dev_css
    return unless Rails.env.development?

    unless params[:prod] || session[:disable_dev_css]
      stylesheet_link_tag "dev_env"
    end
  end

  private
    def antcat_icon *css_classes
      content_tag :span, nil,
        class: ["antcat_icon"].concat(Array.wrap css_classes)
    end
end
