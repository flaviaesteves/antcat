# coding: UTF-8
require 'spec_helper'

describe Family do

  describe "Importing" do
    it "should create the Family, Protonym, and Citation, and should link to the right Genus and Reference" do
      reference = FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'
      data =  {
        :protonym => {
          :family_or_subfamily_name => "Formicariae",
          :authorship => [{:author_names => ["Latreille"], :year => "1809", :pages => "124"}],
        },
        :type_genus => {
          :genus_name => 'Formica',
          :texts => [{:text => [{:phrase => ', by monotypy'}]}]
        },
        :taxonomic_history => ["Formicidae as family"]
      }

      family = Family.import(data).reload
      family.name.to_s.should == 'Formicidae'
      family.should_not be_invalid
      family.should_not be_fossil
      family.taxonomic_history_items.map(&:taxt).should == ['Formicidae as family']

      family.type_name.to_s.should == 'Formica'
      family.type_name.rank.should == 'genus'
      family.type_taxt.should == ', by monotypy'

      protonym = family.protonym
      protonym.name.to_s.should == 'Formicariae'

      authorship = protonym.authorship
      authorship.pages.should == '124'

      authorship.reference.should == reference
    end
    it "should save the note (when there's not a type taxon note)" do
      reference = FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'
      data =  {
        :protonym => {
          :family_or_subfamily_name => "Formicariae",
          :authorship => [{:author_names => ["Latreille"], :year => "1809", :pages => "124"}],
        },
        :type_genus => {:genus_name => 'Formica'},
        :note => [{:phrase=>"[Note.]"}],
        :taxonomic_history => ["Formicidae as family"]
      }

      family = Family.import(data).reload
      family.name.to_s.should == 'Formicidae'
      family.should_not be_invalid
      family.should_not be_fossil
      family.taxonomic_history_items.map(&:taxt).should == ['Formicidae as family']

      family.headline_notes_taxt.should == '[Note.]'

      protonym = family.protonym
      protonym.name.to_s.should == 'Formicariae'

      authorship = protonym.authorship
      authorship.pages.should == '124'

      authorship.reference.should == reference
    end
  end

  describe "Statistics" do
    it "should return the statistics for each status of each rank" do
      family = FactoryGirl.create :family
      subfamily = FactoryGirl.create :subfamily
      tribe = FactoryGirl.create :tribe, subfamily: subfamily
      genus = FactoryGirl.create :genus, :subfamily => subfamily, :tribe => tribe
      FactoryGirl.create :genus, :subfamily => subfamily, :status => 'homonym', :tribe => tribe
      2.times {FactoryGirl.create :subfamily, :fossil => true}
      family.statistics.should == {
        :extant => {subfamilies: {'valid' => 1}, tribes: {'valid' => 1}, genera: {'valid' => 1, 'homonym' => 1}},
        :fossil => {subfamilies: {'valid' => 2}}
      }
    end
  end

  describe "Label" do
    it "should be the family name" do
      FactoryGirl.create(:family, name: FactoryGirl.create(:name, name: 'Formicidae')).name.to_html.should == 'Formicidae'
    end
  end

  describe "Genera" do
    it "should include genera without subfamilies" do
      family = create_family
      subfamily = create_subfamily
      genus_without_subfamily = create_genus subfamily: nil
      genus_with_subfamily = create_genus subfamily: subfamily
      family.genera.should == [genus_without_subfamily]
    end
  end

  describe "Subfamilies" do
    it "should include all the subfamilies" do
      family = create_family
      subfamily = create_subfamily
      family.subfamilies.should == [subfamily]
    end
  end

end
