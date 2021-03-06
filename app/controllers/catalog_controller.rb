class CatalogController < ApplicationController
  before_action :handle_family_not_found, only: [:index]
  before_action :setup_catalog, only: [:index, :show]

  def index
    render 'show'
  end

  def show
  end

  def options
    # params[:valid_only] is only for making the URL more intuitive
    session[:show_valid_only] = !session[:show_valid_only]
    redirect_to :back
  end

  private
    # Avoid blowing up if there's no family. Useful in test and dev.
    def handle_family_not_found
      render 'family_not_found' and return unless Family.first
    end

    def setup_catalog
      set_session
      set_taxon
      setup_panels
    end

    # TODO reverse name, so that this is not needed
    def set_session
      session[:show_valid_only] = true if session[:show_valid_only].nil?
    end

    def set_taxon
      @taxon = params[:id] ? Taxon.find(params[:id]) : Family.first
    end

    def setup_panels
      @self_and_parents = @taxon.self_and_parents

      @panels = @self_and_parents.reject do |taxon|
        # never show the subspecies panel (has no children)
        taxon.is_a?(Subspecies) ||

        # don't show species panel unless the species has subspecies
        (taxon.is_a?(Species) && taxon.children.empty?) ||

        # no subgenus panel (not part of the 'normal' rank hierarchy)
        taxon.is_a?(Subgenus)
      end.map do |taxon|
        children = taxon.children.displayable.ordered_by_name
        children = children.valid if session[:show_valid_only]
        { selected: taxon, children: children }
      end

      setup_non_standard_panels
    end

    def include_all_genera_in_subfamily
      if @taxon.is_a? Subfamily
        params[:display] = "all_genera_in_subfamily"
      end
    end

    def setup_non_standard_panels
      include_all_genera_in_subfamily if params[:display].blank?
      subgenera_special_case
      return unless params[:display]

      case params[:display]
      when /^incertae_sedis_in/
        title = "Genera <i>incertae sedis</i> in #{@taxon.name_html_cache}"
        children = @taxon.genera_incertae_sedis_in
      when /^all_genera_in/
        title = "All #{@taxon.name_html_cache} genera"
        children = @taxon.all_displayable_genera
      when "all_taxa_in_genus"
        title = "All #{@taxon.name_html_cache} taxa"
        children = @taxon.displayable_child_taxa
      when "subgenera_in_genus"
        title = "#{@taxon.name_html_cache} subgenera"
        children = @taxon.displayable_subgenera
      when "subgenera_in_parent_genus"
        # Works because [currently] all subgenera have parents.
        title = "#{@taxon.parent.name_html_cache} subgenera"
        children = @taxon.parent.displayable_subgenera
      end

      children = children.valid if session[:show_valid_only]
      @panels << { selected: { title_for_panel: title },
                  children: children }
    end

    # Enables the subgenera panel when subgenera are selected.
    def subgenera_special_case
      if @taxon.is_a? Subgenus
        params[:display] = "subgenera_in_parent_genus"
      end
    end
end
