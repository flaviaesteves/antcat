# coding: UTF-8
class Taxon < ActiveRecord::Base


  def self.report_counts_for_genera
    Genus.order(:name_cache).all.each do |genus|
      puts "#{genus.name_cache},#{genus.species.valid.count},#{genus.subspecies.valid.count}"
    end
    nil
  end

  def update_current_valid_taxon
    return if current_valid_taxon.present?
    return unless synonym? and senior_synonyms.count > 0
    current_valid_taxon = self.class.find_most_recent_valid_senior_synonym_for self
    update_attributes! current_valid_taxon: current_valid_taxon
  end

  def self.find_most_recent_valid_senior_synonym_for taxon
    (taxon.senior_synonyms.count - 1).downto 0 do |index|
      senior_synonym = taxon.senior_synonyms[index]
      if !senior_synonym.invalid?
        return senior_synonym
      else
        return find_most_recent_valid_senior_synonym_for senior_synonym
      end
    end
    nil
  end

  ###############################################

  # to create the map: open Flávia's file, select all, then copy and paste into a
  # new text file with the indicated name in the /data directory of the project

  def self.biogeographic_regions_for_localities
    map = {}
    File.open('data/biogeographic_regions_for_localities.txt', 'r').each_line do |line|
      components = line.split "\t"
      raise line if components.size != 2
      locality = components[0].upcase.chomp.gsub(/ \d+$/, '')
      biogeographic_region = components[1].chomp
      map[locality] = {biogeographic_region: biogeographic_region, used_count: 0}
    end
    map
  end

  def update_biogeographic_region_from_locality map = nil
    return if fossil?
    return unless protonym.locality
    locality = protonym.locality.upcase
    map ||= self.class.biogeographic_regions_for_localities
    region = map[locality]
    return unless region
    biogeographic_region = region[:biogeographic_region]
    biogeographic_region = nil if biogeographic_region == 'none'
    region[:used_count] += 1
    self.biogeographic_region = biogeographic_region
    save!
  end

  def self.update_biogeographic_regions_from_localities
    taxa = Taxon.includes :protonym
    replacement_count = unfound_count = 0
    Progress.init true, taxa.count
    map = biogeographic_regions_for_localities
    taxa.each do |taxon|
      success = taxon.update_biogeographic_region_from_locality map
      if success then
        replacement_count += 1
      else
        unfound_count += 1
      end
      Progress.tally_and_show_progress 1000 do
        "#{replacement_count} replacements, #{unfound_count} not found"
      end
    end
    Progress.show_results
    Progress.puts "#{replacement_count} replacements, #{unfound_count} not found"
    output_results_from_updating_biogeographic_locations map
  end

  def self.output_results_from_updating_biogeographic_locations map
    map.select do |k, v|
      v[:used_count].zero?
    end.sort.each do |k, v|
      puts "#{k} "
    end
  end

  def self.initialize_china_biographic_regions
    Taxon.includes(:protonym).where('(biogeographic_region IS NULL OR biogeographic_region = "") && protonyms.locality = "China"').each do |taxon|
      taxon.update_attributes biogeographic_region: 'Palearctic'
    end
  end

end