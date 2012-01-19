# coding: UTF-8
require 'spec_helper'

describe Taxt do

  describe "Encodings" do
    it "should encode an unparseable string" do
      Taxt.encode_unparseable('foo').should == '{? foo}'
    end
    it "should encode a reference" do
      reference = Factory :book_reference
      Taxt.encode_reference(reference).should == "{ref #{reference.id}}"
    end
    it "should put italics back around taxon names" do
      Taxt.encode_taxon_name('Atta', :genus).should == "<i>Atta</i>"
    end
    it "should handle a species name" do
      Taxt.encode_taxon_name('Eoformica', :genus, species_epithet: 'eofornica').should == "<i>Eoformica eofornica</i>"
    end
    it "should put a question mark after questionable names" do
      Taxt.encode_taxon_name('Atta', :genus, :questionable => true).should == "<i>Atta?</i>"
    end
    it "should put a dagger in front" do
      Taxt.encode_taxon_name('Atta', :genus, :fossil => true).should == "<i>&dagger;Atta</i>"
    end
    it "should not freak at a family_or_subfamily" do
      Taxt.encode_taxon_name('Dolichoderinae', :family_or_subfamily).should == "Dolichoderinae"
    end
  end

  describe "Interpolation" do

    it "should leave alone a string without fields" do
      string = Taxt.to_string 'foo'
      string.should == 'foo'
      string.should be_html_safe
    end
    it "should handle nil" do
      Taxt.to_string(nil).should == ''
    end
    it "should format a ref" do
      reference = Factory :article_reference
      Reference.should_receive(:find).with(reference.id.to_s).and_return reference
      key_stub = stub
      reference.should_receive(:key).and_return key_stub
      key_stub.should_receive(:to_link).and_return('foo')
      Taxt.to_string("{ref #{reference.id}}").should == 'foo'
    end
    it "should not freak if the ref is malformed" do
      Taxt.to_string("{ref sdf}").should == '{ref sdf}'
    end
    it "should not freak if the ref points to a reference that doesn't exist" do
      Taxt.to_string("{ref 12345}").should == '{ref 12345}'
    end
    it "should handle a MissingReference" do
      reference = Factory :missing_reference, :citation => 'Latreille, 1809'
      Taxt.to_string("{ref #{reference.id}}").should == 'Latreille, 1809'
    end

  end

end
