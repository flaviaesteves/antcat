require 'spec_helper'

describe TaxonDecorator::Statistics do
  let(:decorator_helper) { TaxonDecorator::Statistics.new }

  describe '#statistics' do
    it "handles nil and {}" do
      expect(decorator_helper.statistics(nil)).to eq ''
      expect(decorator_helper.statistics({})).to eq ''
    end

    it "uses commas in numbers" do
      statistics = {
        extant: {
          genera: { 'valid' => 2_000 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">2,000 valid genera</p>'
    end

    it "uses commas in numbers when not showing invalid" do
      statistics = {
        extant: {
          genera: { 'valid' => 2_000 }
        }
      }
      expect(decorator_helper.statistics(statistics, include_invalid: false))
        .to eq '<p class="taxon_statistics">2,000 genera</p>'
    end

    it "handles both extant and fossil statistics" do
      statistics = {
        extant: {
          subfamilies: { 'valid' => 1 },
          genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
          species: { 'valid' => 1 }
        },
        fossil: {
          subfamilies: { 'valid' => 2 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">Extant: 1 valid subfamily, 2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>' +
          '<p class="taxon_statistics">Fossil: 2 valid subfamilies</p>'
    end

    it "can exclude fossil statistics" do
      statistics = {
        extant: {
          subfamilies: { 'valid' => 1 },
          genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
          species: { 'valid' => 1 }
        },
        fossil: {
          subfamilies: { 'valid' => 2 }
        }
      }
      expect(decorator_helper.statistics(statistics, include_fossil: false)).to eq(
        '<p class="taxon_statistics">1 valid subfamily, 2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>'
      )
    end

    it "handles just fossil statistics" do
      statistics = {
        fossil: {
          subfamilies: { 'valid' => 2 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">Fossil: 2 valid subfamilies</p>'
    end

    it "handles both extant and fossil statistics" do
      statistics = {
        extant: {
          subfamilies: { 'valid' => 1 },
          genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
          species: { 'valid' => 1 }
        },
        fossil: {
          subfamilies: { 'valid' => 2 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">Extant: 1 valid subfamily, 2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>' +
          '<p class="taxon_statistics">Fossil: 2 valid subfamilies</p>'
    end

    it "can exclude fossil statistics" do
      statistics = {
        extant: {
          subfamilies: { 'valid' => 1 },
          genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
          species: { 'valid' => 1 }
        },
        fossil: {
          subfamilies: { 'valid' => 2 }
        }
      }
      expect(decorator_helper.statistics(statistics, include_fossil: false)).to eq(
        '<p class="taxon_statistics">1 valid subfamily, 2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>'
      )
    end

    it "handles just fossil statistics" do
      statistics = {
        fossil: {
          subfamilies: { 'valid' => 2 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">Fossil: 2 valid subfamilies</p>'
    end

    it "formats the family's statistics correctly" do
      statistics = {
        extant: {
          subfamilies: { 'valid' => 1 },
          genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
          species: { 'valid' => 1 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">1 valid subfamily, 2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>'
    end

    it "handles tribes" do
      statistics = {
        extant: {
          tribes: { 'valid' => 1 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">1 valid tribe</p>'
    end

    it "formats a subfamily's statistics correctly" do
      statistics = {
        extant: {
          genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
          species: { 'valid' => 1 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>'
    end

    it "uses the singular for genus" do
      statistics = {
        extant: {
          genera: { 'valid' => 1 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">1 valid genus</p>'
    end

    it "formats a genus's statistics correctly" do
      statistics = {
        extant: {
          species: { 'valid' => 1 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">1 valid species</p>'
    end

    it "formats a species's statistics correctly" do
      statistics = {
        extant: {
          subspecies: { 'valid' => 1 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">1 valid subspecies</p>'
    end

    it "handles when there are no valid rank members" do
      species = create :species
      create :subspecies, species: species, status: 'synonym'

      statistics = {
        extant: {
          subspecies: { 'synonym' => 1 }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">(1 synonym)</p>'
    end

    it "doesn't pluralize certain statuses" do
      statistics = {
        extant: {
          species: {
            'valid' => 2,
            'synonym' => 2,
            'homonym' => 2,
            'unavailable' => 2,
            'excluded from Formicidae' => 2
          }
        }
      }
      expect(decorator_helper.statistics(statistics))
        .to eq '<p class="taxon_statistics">2 valid species (2 synonyms, 2 homonyms, 2 unavailable, 2 excluded from Formicidae)</p>'
    end

    it "leaves out invalid status if desired" do
      statistics = {
        extant: {
          genera: { 'valid' => 1, 'homonym' => 2
          },
          species: { 'valid' => 2 },
          subspecies: { 'valid' => 3}
        }
      }
      expect(decorator_helper.statistics(statistics, include_invalid: false))
        .to eq '<p class="taxon_statistics">1 genus, 2 species, 3 subspecies</p>'
    end

    it "doesn't leave a trailing comma" do
      statistics = {
        extant: {
          species: { 'valid' => 2 }
        }
      }
      expect(decorator_helper.statistics(statistics, include_fossil: false, include_invalid: false))
        .to eq '<p class="taxon_statistics">2 species</p>'
    end

    it "doesn't leave a trailing comma" do
      statistics = {
        extant: {
          species: { 'valid' => 2 }
        }
      }
      expect(decorator_helper.statistics(statistics, include_fossil: false, include_invalid: false))
        .to eq '<p class="taxon_statistics">2 species</p>'
    end
  end
end
