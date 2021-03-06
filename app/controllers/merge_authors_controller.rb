class MergeAuthorsController < ApplicationController
  before_action :authenticate_editor, except: [:index, :create_panels, :add_blank_panel_if_necessary]

  def index
    create_panels
    add_blank_panel_if_necessary
  end

  def merge
    term = params[:terms].first
    create_panels
    Author.merge @authors
    params[:terms] = [term]
    index
    render :index
  end

  private
    def create_panels
      params[:terms] ||= []

      # if closing a panel, remove its term
      params[:terms].delete params[:term] unless params[:commit]

      @panels = []
      @authors = []
      params[:terms].each do |term|
        panel = OpenStruct.new term: term.strip, author: Author.find_by_names(term).first
        @panels << panel
        next unless panel.author
        panel.already_open = @authors.include? panel.author
        panel.author = nil if panel.already_open
        @authors << panel.author if panel.author
      end
      @names = @authors.map(&:names).flatten.map(&:name).uniq
    end

    def add_blank_panel_if_necessary
      @panels << OpenStruct.new(term: '') unless @panels.find { |panel| !panel.author }
    end
end
