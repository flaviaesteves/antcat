class ReferencesController < ApplicationController
  before_filter :authenticate_user!, :except => :index
  def index
    if params[:commit] == 'clear'
      params[:author] = params[:start_year] = params[:end_year] = params[:journal] = ''
    end
    @references = Reference.search(params).paginate(:page => params[:page])
  end

  def update
    @reference = get_reference
    set_journal if @reference.respond_to? :journal
    set_publisher if @reference.respond_to? :publisher
    set_pagination
    success = set_authors
    @reference.attributes = params[:reference]
    if success
      @reference.save
    end
    render_json
  end
  
  def create
    journal_valid = true
    begin
      Reference.transaction do
        @reference = case params[:selected_tab]
                when 'Article': ArticleReference.new
                when 'Book': BookReference.new
                else OtherReference.new
                end
        journal_valid = set_journal if @reference.respond_to? :journal
        set_publisher if @reference.respond_to? :publisher
        set_pagination
        set_authors
        @reference.attributes = params[:reference]
        @reference.save!
        unless @reference.errors.empty?
          @reference.instance_variable_set( :@new_record ,true)
          @reference[:id] = nil
          raise ActiveRecord::Rollback
        end
      end
    rescue ActiveRecord::RecordInvalid
      @reference[:id] = nil
      @reference.instance_variable_set( :@new_record ,true)
    end
    @reference.errors.add_to_base "Journal title can't be blank" unless journal_valid
    render_json true
  end
  
  def destroy
    @reference = Reference.find(params[:id])
    @reference.destroy
    head :ok
  end

  private
  def set_pagination
    params[:reference][:pagination] =
      case @reference
      when ArticleReference: params[:article_pagination]
      when BookReference: params[:book_pagination]
      else nil
      end
  end

  def set_authors
    if params[:reference][:authors].blank?
      params[:reference][:authors] = []
      @reference.errors.add :authors, "can't be blank"
      @reference.authors_string = ''
    else
      params[:reference][:authors] = Author.import_authors_string params[:reference][:authors]
    end
  end

  def set_journal
    if params[:journal_title].blank?
      return false
    else
      params[:reference][:journal] = Journal.import :title => params[:journal_title]
      return true
    end
  end

  def set_publisher
    params[:reference][:publisher] = Publisher.import_string params[:publisher_string]
  end

  def render_json new = false
    render :json => {
      :isNew => new,
      :content => render_to_string(:partial => 'reference',
                                   :locals => {:reference => @reference, :css_class => 'reference'}),
      :id => @reference.id,
      :success => @reference.errors.empty?
    }
  end

  def get_reference
    reference = Reference.find(params[:id])
    return reference if reference.type == params[:selected_tab]
    reference.update_attribute(:type, params[:selected_tab] + 'Reference')
    Reference.find(params[:id])
  end
end
