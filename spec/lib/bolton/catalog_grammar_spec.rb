require 'spec_helper'

describe Bolton::CatalogGrammar do

  it "should recognize incertae sedis" do
    Bolton::CatalogGrammar.parse('<i>incertae sedis</i> in ', :root => :incertae_sedis_in).should_not be_nil
  end

  it "should recognize incertae sedis when " do
    Bolton::CatalogGrammar.parse('<i>incertae sedis </i>in ', :root => :incertae_sedis_in).should_not be_nil
  end

  it "should recognize incertae sedis when " do
    Bolton::CatalogGrammar.parse("<i> incertae sedis</i> in ", :root => :incertae_sedis_in).should_not be_nil
  end

end
