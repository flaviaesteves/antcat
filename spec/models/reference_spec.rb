require 'spec_helper'

describe Reference do
  let(:author_names) { [create(:author_name)] }

  describe "Relationships" do
    let(:reference) {
      Reference.create! author_names: author_names,
        title: 'asdf', citation_year: '2010d'
    }

    it "has many author_names" do
      expect(reference.author_names.first).to eq author_names.first
    end

    it "has many authors" do
      expect(reference.authors.first).to eq author_names.first.author
    end

    describe "Nested references" do
      let!(:nesting_reference) { create :reference }
      let(:nestee) { create :nested_reference, nesting_reference: nesting_reference }

      it "can have a nesting_reference" do
        expect(nestee.nesting_reference).to eq nesting_reference
      end

      it "can have many nestees" do
        expect(nesting_reference.nestees).to match_array [nestee]
      end
    end
  end

  describe "#parse_author_names_and_suffix" do
    let(:reference) { create :reference }

    it "returns nothing if empty" do
      expect(reference.parse_author_names_and_suffix(''))
        .to eq author_names: [], author_names_suffix: nil
    end

    it "adds an error and raise and exception if invalid" do
      expect { reference.parse_author_names_and_suffix('...asdf sdf dsfdsf') }
        .to raise_error ActiveRecord::RecordInvalid

      error_message = "couldn't be parsed. Please post a message on " \
        "http://groups.google.com/group/antcat/, and we'll fix it!"
      expect(reference.errors.messages).to eq author_names_string: [error_message]
      expect(reference.author_names_string).to eq '...asdf sdf dsfdsf'
    end

    it "returns the author names and the suffix" do
      results = reference.parse_author_names_and_suffix 'Fisher, B.; Bolton, B. (eds.)'
      fisher = AuthorName.find_by_name 'Fisher, B.'
      bolton = AuthorName.find_by_name 'Bolton, B.'

      expect(results).to eq author_names: [fisher, bolton], author_names_suffix: ' (eds.)'
    end
  end

  describe "#author_names_string" do
    describe "formatting" do
      it "consists of one author_name if that's all there is" do
        reference = create :reference,
          author_names: [create(:author_name, name: 'Fisher, B.L.')]
        expect(reference.author_names_string).to eq 'Fisher, B.L.'
      end

      it "separates multiple author_names with semicolons" do
        author_names = [
          create(:author_name, name: 'Fisher, B.L.'),
          create(:author_name, name: 'Ward, P.S.')
        ]
        reference = create(:reference, author_names: author_names)
        expect(reference.author_names_string).to eq 'Fisher, B.L.; Ward, P.S.'
      end

      it "includes the author_names' suffix" do
        author_names = [
          create(:author_name, name: 'Fisher, B.L.'),
          create(:author_name, name: 'Ward, P.S.')
        ]
        reference = Reference.create! title: 'Ants',
          citation_year: '2010',
          author_names: author_names,
          author_names_suffix: ' (eds.)'
        expect(reference.reload.author_names_string).to eq 'Fisher, B.L.; Ward, P.S. (eds.)'
      end

      it "should be possible to read from and assign to, aliased to author_names_string_cache" do
        reference = create :reference
        reference.author_names_string = 'foo'
        expect(reference.author_names_string).to eq 'foo'
      end
    end

    describe "updating, when things change" do
      let(:reference) do
        create :reference,
          author_names: [create(:author_name, name: 'Fisher, B.L.')]
      end
      let(:author_name) { create :author_name, name: 'Ward' }

      it "updates its author_names_string when an author_name is added" do
        reference.author_names << author_name
        expect(reference.author_names_string).to eq 'Fisher, B.L.; Ward'
      end

      it "updates its author_names_string when an author_name is removed" do
        reference.author_names << author_name
        expect(reference.author_names_string).to eq 'Fisher, B.L.; Ward'
        reference.author_names.delete author_name
        expect(reference.author_names_string).to eq 'Fisher, B.L.'
      end

      it "updates its author_names_string when an author_name's name is changed" do
        reference.author_names = [author_name]
        expect(reference.author_names_string).to eq 'Ward'
        author_name.update_attribute :name, 'Fisher'
        expect(reference.reload.author_names_string).to eq 'Fisher'
      end

      it "updates its author_names_string when the author_names_suffix changes" do
        reference.author_names_suffix = ' (eds.)'
        reference.save
        expect(reference.reload.author_names_string).to eq 'Fisher, B.L. (eds.)'
      end
    end

    describe "maintaining its order" do
      it "maintains the order in which they were added to the reference" do
        reference = create :reference, author_names: [create(:author_name, name: 'Ward')]
        wilden = create :author_name, name: 'Wilden'
        fisher = create :author_name, name: 'Fisher'
        reference.author_names << wilden
        reference.author_names << fisher

        expect(reference.author_names_string).to eq 'Ward; Wilden; Fisher'
      end
    end
  end

  describe "#principal_author_last_name" do
    let(:ward) { create :author_name, name: 'Ward, P.' }
    let(:fisher) { create :author_name, name: 'Fisher, B.' }

    it "should not freak out if there are no authors" do
      reference = Reference.create! title: 'title', citation_year: '1993'
      expect(reference.principal_author_last_name).to be_nil
    end

    it "caches the last name of the principal author" do
      reference = create :reference, author_names: [ward, fisher]
      expect(reference.principal_author_last_name).to eq 'Ward'
    end

    it "updates its author_names_string when an author_name's name is changed" do
      reference = create :reference, author_names: [ward]
      ward.update_attributes name: 'Bolton, B.'
      expect(reference.reload.principal_author_last_name).to eq 'Bolton'
    end

    it "should be possible to read from, aliased to principal_author_last_name_cache" do
      reference = create :reference
      reference.principal_author_last_name_cache = 'foo'
      expect(reference.principal_author_last_name).to eq 'foo'
    end
  end

  describe "validations" do
    let!(:author_name) { create :author_name }
    let(:reference) do
      Reference.new author_names: [author_name],
        title: 'title', citation_year: '1910'
    end

    it "should be OK when all fields are present" do
      expect(reference).to be_valid
    end

    it "should not be OK when the title is missing" do
      reference.title = nil
      expect(reference).not_to be_valid
    end
  end

  describe "changing the citation year" do
    it "changes the year" do
      reference = create :reference, citation_year: '1910a'
      expect(reference.year).to eq 1910
      reference.citation_year = '2010b'
      reference.save!
      expect(reference.year).to eq 2010
    end

    it "sets the year to the stated year, if present" do
      reference = create :reference, citation_year: '1910a ["1958"]'
      expect(reference.year).to eq 1958
      reference.citation_year = '2010b'
      reference.save!
      expect(reference.year).to eq 2010
    end

    it "handles nil years" do
      reference = reference_factory author_name: 'Bolton', citation_year: nil
      expect(reference.short_citation_year).to eq "[no year]"
    end
  end

  describe "entering a newline in the title, public_notes, editor_notes or taxonomic_notes" do
    let(:reference) { create :reference }

    it "strips the newline" do
      reference.title = "A\nB"
      reference.public_notes = "A\nB"
      reference.editor_notes = "A\nB"
      reference.taxonomic_notes = "A\nB"
      reference.save!

      expect(reference.title).to eq "A B"
      expect(reference.public_notes).to eq "A B"
      expect(reference.editor_notes).to eq "A B"
      expect(reference.taxonomic_notes).to eq "A B"
    end

    it "handles all sorts of newlines" do
      reference.title = "A\r\nB"
      reference.save!
      expect(reference.title).to eq "A B"
    end

    it "removes newlines at the beginning and end" do
      reference.title = "\r\nA\r\nB\n\n"
      reference.save!
      expect(reference.title).to eq "A B"
    end
  end

  describe "long fields" do
    it "doesn't truncate long fields" do
      Reference.create! author_names: author_names,
        editor_notes: 'e' * 1000,
        citation: 'c' * 2000,
        public_notes: 'n' * 1500,
        taxonomic_notes: 't' * 1700,
        title: 't' * 1900,
        citation_year: '2010'
      reference = Reference.first

      expect(reference.citation.size).to eq 2000
      expect(reference.editor_notes.size).to eq 1000
      expect(reference.public_notes.size).to eq 1500
      expect(reference.taxonomic_notes.size).to eq 1700
      expect(reference.title.size).to eq 1900
    end
  end

  describe "scope.sorted_by_principal_author_last_name" do
    it "orders by author_name" do
      bolton = create :author_name, name: 'Bolton'
      ward = create :author_name, name: 'Ward'
      fisher = create :author_name, name: 'Fisher'
      bolton_reference = create :article_reference, author_names: [bolton, ward]
      ward_reference = create :article_reference, author_names: [ward, bolton]
      fisher_reference = create :article_reference, author_names: [fisher, bolton]

      results = Reference.sorted_by_principal_author_last_name
      expect(results.map(&:id)).to eq [bolton_reference.id, fisher_reference.id, ward_reference.id]
    end
  end

  describe 'scope.with_principal_author_last_name' do
    it 'returns references with a matching principal author last name' do
      not_possible_reference = create :book_reference,
        author_names: [create(:author_name, name: 'Bolton, B.')]
      possible_reference = create :article_reference,
        author_names: [
          create(:author_name, name: 'Ward, P. S.'),
          create(:author_name, name: 'Fisher, B. L.')
        ]
      another_possible_reference = create :article_reference,
        author_names: [create(:author_name, name: 'Warden, J.')]

      results = Reference.with_principal_author_last_name 'Ward'
      expect(results).to eq [possible_reference]
    end
  end

  describe 'implementing ReferenceComparable' do
    it 'maps all fields correctly' do
      author_name = create :author_name, name: 'Fisher, B. L.'
      reference = ArticleReference.create! author_names: [author_name],
        citation_year: '1981',
        title: 'Dolichoderinae',
        journal: create(:journal),
        series_volume_issue: '1(2)',
        pagination: '22-54'

      expect(reference.author).to eq 'Fisher'
      expect(reference.year).to eq 1981
      expect(reference.title).to eq 'Dolichoderinae'
      expect(reference.type).to eq 'ArticleReference'
      expect(reference.series_volume_issue).to eq '1(2)'
      expect(reference.pagination).to eq '22-54'
    end
  end

  describe "duplicate checking" do
    it "allows a duplicate record to be saved" do
      journal = create :journal
      author = create :author_name
      original = ArticleReference.create! author_names: [author],
        citation_year: '1981', title: 'Dolichoderinae',
        journal: journal, series_volume_issue: '1(2)', pagination: '22-54'
      ArticleReference.create! author_names: [author],
        citation_year: '1981', title: 'Dolichoderinae',
        journal: journal, series_volume_issue: '1(2)', pagination: '22-54'
    end

    it "checks possible duplication and add to errors, if any found" do
      journal = create :journal
      author = create :author_name
      original = ArticleReference.create! author_names: [author],
        citation_year: '1981',
        title: 'Dolichoderinae',
        journal: journal,
        series_volume_issue: '1(2)',
        pagination: '22-54'
      duplicate = ArticleReference.new author_names: [author],
        citation_year: '1981',
        title: 'Dolichoderinae',
        journal: journal,
        series_volume_issue: '1(2)',
        pagination: '22-54'
      expect(duplicate.errors).to be_empty
      expect(duplicate.check_for_duplicate).to be_truthy
      expect(duplicate.errors).not_to be_empty
    end
  end

  describe "#short_citation_year" do
    it "is the same as citation year if nothing extra" do
      reference = create :article_reference, citation_year: '1970'
      expect(reference.short_citation_year).to eq '1970'
    end

    it "allows an ordinal letter" do
      reference = create :article_reference, citation_year: '1970a'
      expect(reference.short_citation_year).to eq '1970a'
    end

    it "is trimmed if there is something extra" do
      reference = create :article_reference, citation_year: '1970a ("1971")'
      expect(reference.short_citation_year).to eq '1970a'
    end
  end

  # References to a reference
  describe "#reference_references" do
    let(:reference) { create :article_reference }

    it "recognizes various uses of this reference in taxt" do
      citation = create :citation, reference: reference, notes_taxt: "{ref #{reference.id}}"
      protonym = create :protonym, authorship: citation
      taxon = create :genus,
        protonym: protonym,
        type_taxt: "{ref #{reference.id}}",
        headline_notes_taxt: "{ref #{reference.id}}",
        genus_species_header_notes_taxt: "{ref #{reference.id}}"
      history_item = taxon.history_items.create! taxt: "{ref #{reference.id}}"
      reference_section = create :reference_section,
        title_taxt: "{ref #{reference.id}}",
        subtitle_taxt: "{ref #{reference.id}}",
        references_taxt: "{ref #{reference.id}}"
      nested_reference = create :nested_reference, nesting_reference: reference

      results = reference.send :reference_references
      expect(results).to match_array [
        {table: 'taxa',               id: taxon.id,             field: :type_taxt},
        {table: 'taxa',               id: taxon.id,             field: :headline_notes_taxt},
        {table: 'taxa',               id: taxon.id,             field: :genus_species_header_notes_taxt},
        {table: 'citations',          id: citation.id,          field: :notes_taxt},
        {table: 'citations',          id: citation.id,          field: :reference_id},
        {table: 'reference_sections', id: reference_section.id, field: :title_taxt},
        {table: 'reference_sections', id: reference_section.id, field: :subtitle_taxt},
        {table: 'reference_sections', id: reference_section.id, field: :references_taxt},
        {table: 'references',         id: nested_reference.id,  field: :nesting_reference_id},
        {table: 'taxon_history_items',id: history_item.id,      field: :taxt},
      ]
    end

    describe "#has_any_references?" do
      it "returns false if there are no references to this reference" do
        expect(reference.send(:has_any_references?)).to be_falsey
      end
    end
  end

  describe "versioning" do
    it "records events and can restore prior versions" do
      with_versioning do
        reference = UnknownReference.create! title: 'title',
          citation_year: '2010', citation: 'citation'

        versions = reference.versions
        version = versions.last
        expect(version.event).to eq 'create'

        reference.title = 'new title'
        reference.save!

        versions = reference.versions true
        version = versions.last
        expect(version.event).to eq 'update'

        reference = version.reify
        expect(reference.title).to eq 'title'
        reference.save!
        expect(reference.title).to eq 'title'
      end
    end
  end
end
