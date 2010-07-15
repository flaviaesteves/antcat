class ReferencesController < ApplicationController
  def show
    @reference = Reference.find(params[:id])
  end
  
  def edit
    @reference = Reference.find(params[:id])
  end

  def update
    @reference = Reference.find(params[:id])
    if @reference.update_attributes(params[:reference])
      flash[:notice] = "Successfully updated reference."
      redirect_to references_url
    else
      render :action => 'edit'
    end
  end
  
  def new
    @reference = Reference.new
  end
  
  def create
    @reference = Reference.new(params[:reference])
    if @reference.save
      flash[:notice] = "Successfully created reference."
      redirect_to references_url
    else
      render :action => 'new'
    end
  end
  
  def destroy
    @reference = Reference.find(params[:id])
    @reference.destroy
    flash[:notice] = "Successfully destroyed reference."
    redirect_to references_url
  end
  
  def index
    @references = Reference.paginate :page => params[:page], :order => :year
    render :template => 'references/index'
  end
end
