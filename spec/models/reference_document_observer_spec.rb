require 'spec_helper'

describe ReferenceDocumentObserver do
  describe "Invalidating the cache" do
    it "should be asked to invalidate the cache when a change occurs" do
      reference_document = create :reference_document
      expect_any_instance_of(ReferenceDocumentObserver).to receive :before_update
      reference_document.url = 'antcat.org'
      reference_document.save!
    end
  end

  it "invalidates the cache for the reference that uses the reference document" do
    reference = create :article_reference
    reference_document = create :reference_document, reference: reference
    ReferenceFormatterCache.instance.populate reference
    ReferenceDocumentObserver.instance.before_update reference_document
    expect(reference.formatted_cache).to be_nil
  end

  it "shouldn't croak if there's no reference" do
    reference_document = create :reference_document
    ReferenceDocumentObserver.instance.before_update reference_document
  end
end
