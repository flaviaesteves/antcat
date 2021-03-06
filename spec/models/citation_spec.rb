require 'spec_helper'

describe Citation do
  it "has a Reference" do
    reference = create :reference
    citation = Citation.create! reference: reference

    expect(citation.reload.reference).to eq reference
  end

  it "requires a Reference" do
    citation = Citation.create
    expect(citation.reference).to be_nil
    expect(citation).not_to be_valid
  end

  describe "versioning" do
    it "records versions" do
      with_versioning do
        citation = create :citation
        expect(citation.versions.last.event).to eq 'create'
      end
    end
  end

  describe "#authorship_string" do
    it "shows the author and year" do
      reference = reference_factory author_name: 'Bolton', citation_year: '2001'
      citation = FactoryGirl.build_stubbed :citation, reference: reference

      expect(citation.authorship_string).to eq 'Bolton, 2001'
    end

    it "handles multiple authors" do
      reference = FactoryGirl.build_stubbed :article_reference,
        author_names: [
          create(:author_name, name: 'Bolton, B.'),
          create(:author_name, name: 'Fisher, R.'),
        ],
        citation_year: '2001', year: '2001'
      citation = FactoryGirl.build_stubbed :citation, reference: reference

      expect(citation.authorship_string).to eq 'Bolton & Fisher, 2001'
    end

    it "doesn't include the year ordinal" do
      reference = reference_factory author_name: 'Bolton', citation_year: '1885g'
      citation = FactoryGirl.build_stubbed :citation, reference: reference

      expect(citation.authorship_string).to eq 'Bolton, 1885'
    end
  end

  describe "#authorship_html_string" do
    it "shows the author and year" do
      citation = FactoryGirl.build_stubbed :citation
      expect_any_instance_of(ReferenceDecorator)
        .to receive(:format_authorship_html)
        .and_return 'XYZ'

      expect(citation.authorship_html_string).to eq 'XYZ'
    end
  end

  describe "#author_last_names_string" do
    it "shows the authors' last names" do
      reference = reference_factory author_name: 'Bolton', citation_year: '2001'
      citation = FactoryGirl.build_stubbed :citation, reference: reference

      expect(citation.author_last_names_string).to eq 'Bolton'
    end
  end

  describe "#year" do
    it "shows the year" do
      reference = reference_factory author_name: 'Bolton', citation_year: '2001'
      citation = FactoryGirl.build_stubbed :citation, reference: reference

      expect(citation.year).to eq '2001'
    end

    it "handles nil years" do
      reference = reference_factory author_name: 'Bolton', citation_year: nil
      citation = FactoryGirl.build_stubbed :citation, reference: reference

      expect(citation.year).to eq "[no year]"
    end
  end
end
