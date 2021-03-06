class TaxonHistoryItemsController < ApplicationController
  include UndoTracker

  before_filter :authenticate_editor

  def show
    @item = TaxonHistoryItem.find params[:id]
    render 'history_items/show'
  end

  def update
    item = TaxonHistoryItem.find params[:id]
    item.update_taxt_from_editable params[:taxt]
    render_json item
  end

  def create
    taxon = Taxon.find params[:taxa_id]
    setup_change taxon, :create
    item = TaxonHistoryItem.create_taxt_from_editable taxon, params[:taxt]
    render_json item
  end

  def destroy
    item = TaxonHistoryItem.find params[:id]
    item.destroy
    json = { success: true }
    render json: json
  end

  private
    def render_json item
      json = {
        content: render_to_string(partial: 'history_items/panel', locals: { item: item }),
        id: item.id,
        success: item.errors.empty?
      }

      render json: json
    end
end
