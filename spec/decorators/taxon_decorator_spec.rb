require 'spec_helper'

describe TaxonDecorator do
  describe "Header formatting" do
    let(:decorator_helper) { TaxonDecorator::Header }

    describe "#header_name" do
      it "formats a subspecies with > 3 epithets" do
        formica = create_genus 'Formica'
        rufa = create_species 'rufa', genus: formica
        major_name = Name.create! name: 'Formica rufa pratensis major',
          epithet_html: '<i>major</i>',
          epithets: 'rufa pratensis major'
        major = create_subspecies name: major_name, species: rufa, genus: rufa.genus

        expect(decorator_helper.new(major).send(:header_name)).to eq(
          %{<a href="/catalog/#{formica.id}"><i>Formica</i></a> } +
          %{<a href="/catalog/#{rufa.id}"><i>rufa</i></a> } +
          %{<a href="/catalog/#{major.id}"><i>pratensis major</i></a>}
        )
      end
    end
  end

  describe "Headline formatting" do
    let(:decorator_helper) { TaxonDecorator::Headline }

    describe "#protonym_name" do
      it "formats a family name in the protonym" do
        protonym = create :protonym, name: create(:family_or_subfamily_name, name: 'Dolichoderinae')
        expect(decorator_helper.new(nil).send(:protonym_name, protonym))
          .to eq '<b><span class="protonym_name">Dolichoderinae</span></b>'
      end

      it "formats a genus name in the protonym" do
        protonym = create :protonym, name: create(:genus_name, name: 'Atari')
        expect(decorator_helper.new(nil).send(:protonym_name, protonym))
          .to eq '<b><span class="protonym_name"><i>Atari</i></span></b>'
      end

      it "formats a fossil" do
        protonym = create :protonym, name: create(:genus_name, name: 'Atari'), fossil: true
        expect(decorator_helper.new(nil).send(:protonym_name, protonym))
          .to eq '<b><span class="protonym_name"><i>&dagger;</i><i>Atari</i></span></b>'
      end
    end

    describe "types" do
      let(:species_name) { create :species_name, name: 'Atta major', epithet: 'major' }

      describe "#headline_type" do
        it "shows the type taxon" do
          genus = create_genus 'Atta', type_name: species_name
          expect(decorator_helper.new(genus).send(:headline_type))
            .to eq %{<span class="type">Type-species: <span class="species taxon"><i>Atta major</i></span>.</span>}
        end

        it "shows the type taxon with extra Taxt" do
          genus = create_genus 'Atta', type_name: species_name, type_taxt: ', by monotypy'
          expect(decorator_helper.new(genus).send(:headline_type))
            .to eq %{<span class="type">Type-species: <span class="species taxon"><i>Atta major</i></span>, by monotypy.</span>}
        end
      end

      describe "#headline_type_name" do
        it "shows the type taxon as a link, if the taxon for the name exists" do
          type = create_species 'Atta major'
          genus = create_genus 'Atta', type_name: create(:species_name, name: 'Atta major')
          expect(decorator_helper.new(genus).send(:headline_type_name))
            .to eq %Q{<a href="/catalog/#{type.id}"><i>Atta major</i></a>}
        end
      end
    end

    describe "#link_to_other_site" do
      it "links to species" do
        subfamily = create_subfamily 'Dolichoderinae'
        genus = create_genus 'Atta', subfamily: subfamily
        species = create_species 'Atta major', genus: genus, subfamily: subfamily
        expect(decorator_helper.new(species).send(:link_to_other_site)).to eq %{<a class="link_to_external_site" target="_blank" href="http://www.antweb.org/description.do?rank=species&genus=atta&species=major&project=worldants">AntWeb</a>}
      end

      it "links to subspecies" do
        subfamily = create_subfamily 'Dolichoderinae'
        genus = create_genus 'Atta', subfamily: subfamily
        species = create_species 'Atta major', genus: genus, subfamily: subfamily
        species = create_subspecies 'Atta major nigrans', species: species, genus: genus, subfamily: subfamily
        expect(decorator_helper.new(species).send(:link_to_other_site))
          .to eq %{<a class="link_to_external_site" target="_blank" href="http://www.antweb.org/description.do?rank=subspecies&genus=atta&species=major&subspecies=nigrans&project=worldants">AntWeb</a>}
      end

      it "links to invalid taxa" do
        subfamily = create_subfamily 'Dolichoderinae', status: 'synonym'
        expect(decorator_helper.new(subfamily).send(:link_to_other_site)).not_to be_nil
      end
    end
  end

  describe "Child lists" do
    let(:decorator_helper) { TaxonDecorator::ChildList }
    let(:subfamily) { create_subfamily 'Dolichoderinae' }

    describe "#child_list" do
      it "formats a tribes list" do
        attini = create_tribe 'Attini', subfamily: subfamily
        expect(decorator_helper.new(subfamily).send(:child_list, subfamily.tribes, true))
          .to eq %{<div class="child_list"><span class="caption">Tribe (extant) of <span class="name subfamily taxon">Dolichoderinae</span></span>: <a href="/catalog/#{attini.id}">Attini</a>.</div>}
      end

      it "formats a child list, specifying extinctness" do
        atta = create_genus 'Atta', subfamily: subfamily
        expect(decorator_helper.new(subfamily).send(:child_list, Genus.all, true))
          .to eq %{<div class="child_list"><span class="caption">Genus (extant) of <span class="name subfamily taxon">Dolichoderinae</span></span>: <a href="/catalog/#{atta.id}"><i>Atta</i></a>.</div>}
      end

      it "formats a genera list, not specifying extinctness" do
        atta = create_genus 'Atta', subfamily: subfamily
        expect(decorator_helper.new(subfamily).send(:child_list, Genus.all, false))
          .to eq %{<div class="child_list"><span class="caption">Genus of <span class="name subfamily taxon">Dolichoderinae</span></span>: <a href="/catalog/#{atta.id}"><i>Atta</i></a>.</div>}
      end

      it "formats an incertae sedis genera list" do
        genus = create_genus 'Atta', subfamily: subfamily, incertae_sedis_in: 'subfamily'
        expect(decorator_helper.new(subfamily).send(:child_list, [genus], false, incertae_sedis_in: 'subfamily'))
          .to eq %{<div class="child_list"><span class="caption">Genus <i>incertae sedis</i> in <span class="name subfamily taxon">Dolichoderinae</span></span>: <a href="/catalog/#{genus.id}"><i>Atta</i></a>.</div>}
      end
    end

    describe "#collective_group_name_child_list" do
      it "formats a list of collective group names" do
        genus = create_genus 'Atta', subfamily: subfamily, status: 'collective group name'
        expect(decorator_helper.new(subfamily).send(:collective_group_name_child_list))
          .to eq %{<div class="child_list"><span class="caption">Collective group name in <span class="name subfamily taxon">Dolichoderinae</span></span>: <a href="/catalog/#{genus.id}"><i>Atta</i></a>.</div>}
      end
    end
  end

  describe "#status" do
    let(:decorator_helper) { TaxonDecorator::Header }

    it "returns 'valid' if the status is valid" do
      taxon = create_genus
      expect(decorator_helper.new(taxon).send(:status)).to eq 'valid'
    end

    it "shows the status if there is one" do
      taxon = create_genus status: 'homonym'
      expect(decorator_helper.new(taxon).send(:status)).to eq 'homonym'
    end

    it "shows one synonym" do
      senior_synonym = create_genus 'Atta'
      taxon = create_synonym senior_synonym
      result = decorator_helper.new(taxon).send :status
      expect(result).to eq %{junior synonym of current valid taxon <a href="/catalog/#{senior_synonym.id}"><i>Atta</i></a>}
      expect(result).to be_html_safe
    end

    describe "Using current valid taxon" do
      it "handles a null current valid taxon" do
        senior_synonym = create_genus 'Atta'
        senior_synonym.update_attribute :created_at, Time.now - 100
        other_senior_synonym = create_genus 'Eciton'
        taxon = create_synonym senior_synonym
        Synonym.create! senior_synonym: other_senior_synonym, junior_synonym: taxon
        result = decorator_helper.new(taxon).send :status
        expect(result).to eq %{junior synonym of current valid taxon <a href="/catalog/#{other_senior_synonym.id}"><i>Eciton</i></a>}
      end

      it "handles a null current valid taxon with no synonyms" do
        taxon = create_genus status: 'synonym'
        result = decorator_helper.new(taxon).send :status
        expect(result).to eq %{junior synonym}
      end

      it "handles a current valid taxon that's one of two 'senior synonyms'" do
        senior_synonym = create_genus 'Atta'
        senior_synonym.update_attribute :created_at, Time.now - 100
        other_senior_synonym = create_genus 'Eciton'
        taxon = create_synonym senior_synonym, current_valid_taxon: other_senior_synonym
        Synonym.create! senior_synonym: other_senior_synonym, junior_synonym: taxon
        result = decorator_helper.new(taxon).send :status
        expect(result).to eq %{junior synonym of current valid taxon <a href="/catalog/#{other_senior_synonym.id}"><i>Eciton</i></a>}
      end
    end

    it "doesn't freak out if the senior synonym hasn't been set yet" do
      taxon = create_genus status: 'synonym'
      expect(decorator_helper.new(taxon).send(:status)).to eq 'junior synonym'
    end

    it "shows where it is incertae sedis" do
      taxon = create_genus incertae_sedis_in: 'family'
      result = decorator_helper.new(taxon).send :status
      expect(result).to eq '<i>incertae sedis</i> in family, valid'
      expect(result).to be_html_safe
    end
  end

  describe 'Taxon statistics' do
    it "gets the statistics, then formats them", pending: true do
      pending "test after refactoring TaxonDecorator"
      subfamily = double
      expect(subfamily).to TaxonFormatter(:statistics).and_return extant: :foo
      formatter = Formatters::TaxonFormatter.new subfamily
      expect(Formatters::StatisticsFormatter).to receive(:statistics).with({extant: :foo}, {})
      formatter.statistics
    end

    it "just returns nil if there are no statistics", pending: true do
      pending "test after refactoring TaxonDecorator"
      subfamily = double
      expect(subfamily).to receive(:statistics).and_return nil
      formatter = Formatters::TaxonFormatter.new subfamily
      expect(Formatters::StatisticsFormatter).not_to receive :statistics
      expect(formatter.statistics).to eq ''
    end

    it "doesn't leave a comma at the end if only showing valid taxa", pending: true do
      pending "test after refactoring TaxonDecorator"
      genus = create_genus
      expect(genus).to receive(:statistics).and_return extant: {species: {'valid' => 2}}
      formatter = Formatters::TaxonFormatter.new genus
      expect(formatter.statistics(include_invalid: false))
        .to eq '<div class="statistics"><p class="taxon_statistics">2 species</p></div>'
    end

    it "doesn't leave a comma at the end if only showing valid taxa", pending: true do
      pending "test after refactoring TaxonDecorator"
      genus = create_genus
      expect(genus).to receive(:statistics).and_return extant: {species: {'valid' => 2}}
      formatter = Formatters::TaxonFormatter.new genus
      expect(formatter.statistics(include_invalid: false))
        .to eq '<div class="statistics"><p class="taxon_statistics">2 species</p></div>'
    end
  end

  describe "#link_to_taxon" do
    it "creates the link" do
      genus = create_genus 'Atta'
      expect(genus.decorate.link_to_taxon).to eq %{<a href="/catalog/#{genus.id}"><i>Atta</i></a>}
    end
  end

  describe "#change_history" do
    around do |example|
      with_versioning &example
    end

    it "shows nothing for old taxa" do
      taxon = create_genus
      expect(taxon.decorate.change_history).to be_nil
    end

    it "shows the adder for waiting taxa" do
      adder = create :user, can_edit: true
      taxon = create_taxon_version_and_change :waiting, adder

      change_history = taxon.decorate.change_history
      expect(change_history).to match /Added by/
      expect(change_history).to match /Mark Wilden/
      expect(change_history).to match /less than a minute ago/
    end

    it "shows the adder and the approver for approved taxa" do
      adder = create :user, can_edit: true
      approver = create :user, can_edit: true
      taxon = create_taxon_version_and_change :waiting, adder
      taxon.taxon_state.review_state = :waiting
      change = Change.find taxon.last_change.id
      change.update_attributes! approver: approver, approved_at: Time.now
      taxon.approve!

      change_history = taxon.decorate.change_history
      expect(change_history).to match /Added by/
      expect(change_history).to match /#{adder.name}/
      expect(change_history).to match /less than a minute ago/
      expect(change_history).to match /approved by/
      expect(change_history).to match /#{approver.name}/
      expect(change_history).to match /less than a minute ago/
    end
  end

  describe "#format_senior_synonym" do
    let(:decorator_helper) { TaxonDecorator::Header }

    context "when the senior synonym is itself invalid" do
      it "returns an empty string" do
        invalid_senior = create_genus 'Atta', status: 'synonym'
        junior = create_genus 'Eciton', status: 'synonym'
        Synonym.create! junior_synonym: junior,
          senior_synonym: invalid_senior
        expect(junior.decorate.send(:format_senior_synonym)).to eq ''
      end
    end
  end

  describe "#name_description" do
    it "handles subfamilies" do
      subfamily = create_subfamily build_stubbed: true
      expect(subfamily.decorate.name_description).to eq 'subfamily'
    end

    it "handles genera" do
      subfamily = create_subfamily build_stubbed: true
      genus = create_genus subfamily: subfamily, tribe: nil
      expect(genus.decorate.name_description).to eq "genus of #{subfamily.name}"
    end

    it "handles genera without a subfamily" do
      genus = create_genus subfamily: nil, tribe: nil, build_stubbed: true
      expect(genus.decorate.name_description).to eq "genus of (no subfamily)"
    end

    it "handles genera with a tribe" do
      subfamily = create_subfamily
      tribe = create_tribe subfamily: subfamily
      genus = create_genus tribe: tribe, build_stubbed: true
      expect(genus.decorate.name_description).to eq "genus of #{tribe.name}"
    end

    it "handles new genera" do
      subfamily = create_subfamily build_stubbed: true
      genus = build :genus, subfamily: subfamily, tribe: nil
      expect(genus.decorate.name_description).to eq "new genus of #{subfamily.name}"
    end

    it "handles new species" do
      genus = create_genus 'Atta'
      species = build :species, genus: genus
      expect(species.decorate.name_description).to eq "new species of <i>#{genus.name}</i>"
    end

    it "handles subspecies" do
      genus = create_genus 'Atta'
      species = build :species, genus: genus
      subspecies = build :subspecies, species: species, genus: genus
      expect(subspecies.decorate.name_description).to eq "new subspecies of <i>#{species.name}</i>"
    end

    it "handles subspecies without a species" do
      genus = create_genus 'Atta'
      subspecies = build :subspecies, genus: genus, species: nil
      expect(subspecies.decorate.name_description).to eq "new subspecies of (no species)"
    end

    it "should be html_safe" do
      subfamily = create_subfamily build_stubbed: true
      genus = create_genus subfamily: subfamily, build_stubbed: true
      expect(genus.decorate.name_description).to be_html_safe
    end
  end
end
