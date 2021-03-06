require 'spec_helper'

describe ChangesController do
  describe "check that we can find and report the entire undo set" do
    it "returns a single taxon when no others would be deleted" do
      adder = create :user, can_edit: true
      sign_in adder
      taxon = create_taxon_version_and_change :waiting, adder, nil, 'this_genus'
      taxon.save
      change_id = Change.all.first.id

      get :undo_items, id: change_id
      changes = JSON.parse response.body
      expect(changes.size).to eq 1
      expect(changes[0]['name']).to eq 'this_genus'
      expect(changes[0]['change_type']).to eq 'create'
    end

    it "returns multiple items when undoing an older change would hit newer changes" do
      adder = create :user, can_edit: true
      sign_in adder
      taxon = create_taxon_version_and_change :waiting, adder, nil, 'Genus1'
      taxon.save
      change = create :change, user_changed_taxon_id: taxon.id, change_type: "update"
      create :version, item_id: taxon.id, whodunnit: adder.id, change_id: change.id

      taxon.status = 'homonym'
      taxon.save
      change_id = Change.all.first.id

      get :undo_items, id: change_id
      changes = JSON.parse response.body

      expect(changes.size).to eq 2
      expect(changes[0]['name']).to eq 'Genus1'
      expect(changes[0]['change_type']).to eq 'create'
      expect(changes[0]['change_timestamp']).not_to be nil
      expect(changes[0]['user_name']).to eq 'Mark Wilden'

      expect(changes[1]['name']).to eq 'Genus1'
      expect(changes[1]['change_type']).to eq 'update'
    end
  end
end
