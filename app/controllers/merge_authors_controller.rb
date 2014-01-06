# coding: UTF-8
class MergeAuthorsController < ApplicationController
  before_filter :authenticate_user!, only: :merge
  skip_before_filter :authenticate_user!, :if => :preview?

  def index
    create_panels
    add_blank_panel_if_necessary
  end

  def create_panels
    params[:terms] ||= []

    # if closing a panel, remove its term
    params[:terms].delete params[:term] unless params[:commit]

    @panels = []
    @authors = []
    for term in params[:terms]
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
    @panels << OpenStruct.new(term: '') unless @panels.find{|panel| !panel.author}
  end

  #######
  def merge
    term = params[:terms].first
    create_panels
    Author.merge @authors
    params[:terms] = [term]
    index
    render :index
  end

  #######
  def all
    respond_to do |format|
      format.json {render :json => AuthorName.search(params[:term]).to_json}
      format.html
    end
  end
end