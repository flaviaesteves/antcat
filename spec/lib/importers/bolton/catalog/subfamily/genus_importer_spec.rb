# coding: UTF-8
require 'spec_helper'

describe Importers::Bolton::Catalog::Subfamily::Importer do
  before do
    @importer = Importers::Bolton::Catalog::Subfamily::Importer.new
  end

  describe "Importing a genus" do
    def make_contents content
      @importer.stub :parse_family

      %{<html><body><div>
      <p>THE DOLICHODEROMORPHS: SUBFAMILIES ANEURETINAE AND DOLICHODERINAE</p>
      <p>SUBFAMILY MARTIALINAE</p>
      <p>Subfamily MARTIALINAE</p>
      <p>Martialinae Emery, 1913a: 6. Type-genus: <i>Aneuretus</i>.  </p>
      <p>Genus of Martialinae<span lang=EN-GB>: <i>Sphinctomyrmex</i>.</span></p>
      <p>Genus of Martialinae</p>
      #{content}
      </div></body></html>}
    end

    it "should work" do
      latreille = FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'
      lund = FactoryGirl.create :unknown_reference, :bolton_key_cache => 'Lund 1831a'
      swainson = FactoryGirl.create :unknown_reference, :bolton_key_cache => 'Swainson Shuckard 1840'
      baroni = FactoryGirl.create :unknown_reference, :bolton_key_cache => 'Baroni Urbani 1977c'

      @importer.import_html make_contents %{
        <p>Genus <i>CONDYLODON</i></p>
        <p><i>Condylodon</i> Lund, 1831a: 131. Type-species: <i>Condylodon audouini</i>, by monotypy. </p>
        <p>Taxonomic history</p>
        <p><i>Condylodon</i> in family Mutillidae: Swainson &amp; Shuckard, 1840: 173. </p>
        <p>Genus references</p><p>Baroni Urbani, 1977c: 482 (review of genus).</p>
      }
      genus = Genus.find_by_name 'Condylodon'
      genus.should_not be_invalid
      genus.should_not be_fossil
      genus.subfamily.name.should == 'Martialinae'
      genus.taxonomic_history_items.map(&:taxt).should =~
        ["<i>Condylodon</i> in family Mutillidae: {ref #{swainson.id}}: 173."]
      genus.type_name.name.should == "Condylodon audouini"
      genus.type_taxt.should == ", by monotypy."
      genus.type_name.rank.should == 'species'
      genus.reference_sections.map(&:title).should == ['Genus references']
      genus.reference_sections.map(&:references).should == ["{ref #{baroni.id}}: 482 (review of genus)."]

      protonym = genus.protonym
      protonym.name.should == 'Condylodon'
      protonym.rank.should == 'genus'
      protonym.authorship.reference.should == lund
      protonym.authorship.pages.should == '131'
    end

    describe "Importing a genus that replaced a homonym" do
      it "should work" do
        @importer.import_html make_contents %{
          <p>Genus <i>SPHINCTOMYRMEX</i></p>
          <p><i>Sphinctomyrmex</i> Mayr, 1866b: 895. Type-species: <i>Sphinctomyrmex stali</i>, by monotypy.</p> 
          <p>Taxonomic history</p>
          <p>Sphinctomyrmex history</p>

          <p>Homonym replaced by <i>SPHINCTOMYRMEX</i></p>
          <p><i>Acrostigma</i> Forel, 1902h: 477 [as subgenus of <i>Acantholepis</i>].  Type-species: <i>Acantholepis (Acrostigma) froggatti</i>, by subsequent designation of Wheeler, W.M. 1911f: 158.</p>
          <p>Taxonomic history</p>
          <p>[Junior homonym of *<i>Acrostigma</i> Emery, 1891a: 149 (Formicidae).]</p>
        }

        sphinctomyrmex = Genus.find_by_name 'Sphinctomyrmex'
        sphinctomyrmex.should_not be_nil
        acrostigma = Genus.find_by_name 'Acrostigma'
        acrostigma.should_not be_nil
        acrostigma.should be_homonym_replaced_by sphinctomyrmex
      end

    end
  end
  describe "Parsing taxonomic history" do
    it "should return an array of text items converted to Taxt" do
      dalla_torre = FactoryGirl.create :article_reference, :bolton_key_cache => 'Dalla Torre 1893'
      swainson = FactoryGirl.create :article_reference, :bolton_key_cache => 'Swainson Shuckard 1840'
      @importer.initialize_parse_html %{<div>
        <p>Taxonomic history</p>
        <p><i>Condylodon</i> in family Mutillidae: Swainson &amp; Shuckard, 1840: 173.</p>
        <p><i>Condylodon</i> as junior synonym of <i>Pseudomyrma</i>: Dalla Torre, 1893: 55.</p>
      </div>}
      @importer.parse_taxonomic_history.should == [
        "<i>Condylodon</i> in family Mutillidae: {ref #{swainson.id}}: 173.",
        "<i>Condylodon</i> as junior synonym of <i>Pseudomyrma</i>: {ref #{dalla_torre.id}}: 55."
      ]
    end
  end

  describe "Parsing references" do
    it "should return an array of text items converted to Taxt" do
      genus = FactoryGirl.create :genus, name_object: FactoryGirl.create(:name, name: 'Lepisiota')
      @importer.initialize_parse_html %{<div>
        <p>Genus <i>Lepisiota</i> references</p>
        <p>Note</p>
        <p>Another note</p>
      </div>}
      @importer.parse_genus_references(genus)
      genus.reference_sections.map(&:title).should ==
        ["Genus <i>Lepisiota</i> references", ""]
      genus.reference_sections.map(&:references).should ==
        ["Note", "Another note"]
    end
  end

end

#describe "Importing a genus with junior synonyms" do
  #it "should not include the genus's references at the end of a junior synonym's taxonomic history" do
    #@importer.import_html make_contents %{
#<p>Genus <i>SPHINCTOMYRMEX</i></p>
#<p><i>Sphinctomyrmex</i> Mayr, 1866b: 895. Type-species: <i>Sphinctomyrmex stali</i>, by monotypy. </p>
#<p>Taxonomic history</p>
#<p>Sphinctomyrmex history</p>

#<p>Junior synonyms of <i>SPHINCTOMYRMEX</i></p>

#<p><i>Aethiopopone</i> Santschi, 1930a: 49. Type-species: <i>Sphinctomyrmex rufiventris</i>, by monotypy. </p>
#<p>Taxonomic history</p>
#<p><i>Aethiopopone history</i></p>

#<p><b>Genus <i>Sphinctomyrmex</i> references <p></p></b></p>
#<p>[Note. Entries prior to Bolton, 1995b: 44, refer to genus as <i>Acantholepis</i>.]</p>
#<p>Sphinctomyrmex references</p>
    #}

    #sphinctomyrmex = Genus.find_by_name 'Sphinctomyrmex'
    #sphinctomyrmex.should_not be_nil
    #sphinctomyrmex.taxonomic_history.should ==
#%{<p><b><i>Sphinctomyrmex</i></b> Mayr, 1866b: 895. Type-species: <i>Sphinctomyrmex stali</i>, by monotypy. </p>} +
#%{<p><b>Taxonomic history<p></p></b></p>} +
#%{<p>Sphinctomyrmex history</p>} +
#%{<p><b>Junior synonyms of <i>SPHINCTOMYRMEX<p></p></i></b></p>} +
#%{<p><b><i>Aethiopopone</i></b> Santschi, 1930a: 49. Type-species: <i>Sphinctomyrmex rufiventris</i>, by monotypy. </p>} +
#%{<p><b>Taxonomic history<p></p></b></p>} +
#%{<p><i>Aethiopopone history</i></p>} +

    #aethiopopone = Genus.find_by_name 'Aethiopopone'
    #aethiopopone.should_not be_nil
    #aethiopopone.should be_synonym_of sphinctomyrmex
    #aethiopopone.taxonomic_history.should == 
#%{<p><b><i>Aethiopopone</i></b> Santschi, 1930a: 49. Type-species: <i>Sphinctomyrmex rufiventris</i>, by monotypy. </p>} +
#%{<p><b>Taxonomic history<p></p></b></p>} +
#%{<p><i>Aethiopopone history</i></p>}
  #end

#end
