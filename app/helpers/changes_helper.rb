module ChangesHelper
  def format_taxon_name name
    name.name_html.html_safe
  end

  def format_status status
    Status[status].to_s
  end

  def format_attributes taxon
    string = []
    string << 'Fossil' if taxon.fossil?
    string << 'Hong' if taxon.hong?
    string << '<i>nomen nudum</i>' if taxon.nomen_nudum?
    string << 'unresolved homonym' if taxon.unresolved_homonym?
    string << 'ichnotaxon' if taxon.ichnotaxon?
    string.join(', ').html_safe
  end

  def format_protonym_attributes taxon
    protonym = taxon.protonym
    string = []
    string << 'Fossil' if protonym.fossil?
    string << '<i>sic</i>' if protonym.sic?
    string.join(', ').html_safe
  end

  def format_type_attributes taxon
    if taxon.type_fossil? then 'Fossil' else '' end.html_safe
  end

  def format_taxt taxt
    Taxt.to_string taxt
  end

  def approve_all_changes_button
    return unless user_is_superadmin?

    link_to 'Approve all', approve_all_changes_path,
      method: :put, class: "btn-destructive",
      data: { confirm: "Are you sure you want to approve all changes?" }
  end
end
