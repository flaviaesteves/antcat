class Bolton::SubfamilyCatalog < Bolton::Catalog
  private

  def parse_genus attributes = {}, expect_genus_line = true
    return unless @type == :genus_header
    Progress.log 'parse_genus'

    name = @parse_result[:name]
    status = @parse_result[:status]
    fossil = @parse_result[:fossil]

    parse_next_line
    expect :genus_line if expect_genus_line

    taxonomic_history = @paragraph
    taxonomic_history << parse_taxonomic_history

    genus = Genus.find_by_name name
    if genus
      attributes = {:status => status, :taxonomic_history => taxonomic_history}.merge(attributes)
      check_status_change genus, attributes[:status]
      raise "Genus #{name} fossil change from #{genus.fossil?} to #{fossil}" if fossil != genus.fossil
      genus.update_attributes attributes
    else
      check_existence name, genus
      genus = Genus.create!({:name => name, :fossil => fossil, :status => status, :taxonomic_history => taxonomic_history}.merge(attributes))
    end

    taxonomic_history << parse_homonym_replaced_bys
    taxonomic_history << parse_genus_synonyms(genus)

    genus.reload.update_attributes :taxonomic_history => taxonomic_history
  end

  def parse_homonym_replaced_bys
    return '' unless @type == :homonym_replaced_by
    Progress.log 'parse_homonym_replaced_bys'

    parse_results = @paragraph
    parse_next_line

    while @type == :genus_line
      parse_results << @paragraph << parse_taxonomic_history
    end

    parse_results
  end

  def parse_genus_synonyms genus
    return '' unless @type == :synonyms_header
    Progress.log 'parse_genus_synonyms'

    parse_results = @paragraph
    parse_next_line

    while @type == :genus_line
      name = @parse_result[:name]
      fossil = @parse_result[:fossil]
      taxonomic_history = @paragraph
      taxonomic_history << parse_taxonomic_history
      genus = Genus.create! :name => name, :fossil => fossil, :status => 'synonym', :synonym_of => genus,
                            :subfamily => genus.subfamily, :tribe => genus.tribe, :taxonomic_history => taxonomic_history
      parse_results << taxonomic_history
    end

    parse_results
  end

  def parse_genera_lists parent_rank, parent_attributes = {}
    Progress.log 'parse_genera_lists'

    parsed_text = ''

    while @type == :genera_list
      parsed_text << @paragraph
      @parse_result[:genera].each do |genus, fossil|
        attributes = {:name => genus, :fossil => fossil, :status => 'valid'}.merge parent_attributes
        attributes.merge!(:incertae_sedis_in => parent_rank.to_s) if @parse_result[:incertae_sedis]
        Genus.create! attributes
      end

      parse_next_line
    end

    parsed_text
  end

  def parse_genera
    return unless @type == :genera_header || @type == :genus_header
    Progress.log 'parse_genera'

    parse_next_line if @type == :genera_header

    parse_genus while @type == :genus_header
  end

  def parse_genera_incertae_sedis
    return unless @type == :genera_incertae_sedis_header
    Progress.log 'parse_genera_incertae_sedis'

    parse_next_line

    parse_genus while @type == :genus_header
  end

  def check_status_change genus, status
    return if status == genus.status
    return if genus.status == 'valid' && status == 'unidentifiable'
    raise "Genus #{genus.name} status change from #{genus.status} to #{status}"
  end

  def check_existence name, genus
    raise "Genus #{name} not found" unless genus || name == 'Syntaphus'
  end

end
