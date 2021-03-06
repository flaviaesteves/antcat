require 'spec_helper'

describe TooltipsController do
  # Note: Shoulda only checks if the filter is defined;
  # the matcher does not support :only, :except or `skip_before_filter`
  it { should use_before_filter(:authenticate_editor) }

  describe '#index' do
    context "signed in" do
      let!(:no_namespace)         { create :tooltip, key: "no_namespace" }
      let!(:references_authors)   { create :tooltip, key: "authors", scope: "references" }
      let!(:references_title)     { create :tooltip, key: "title", scope: "references" }
      let!(:references_new_title) { create :tooltip, key: "new.title", scope: "references" }
      let!(:taxa_type_species)    { create :tooltip, key: "type_species", scope: "taxa" }

      before do
        editor = create :user, can_edit: true
        sign_in editor
      end

      describe "grouping" do
        before do
          get :index
          @grouped = assigns :grouped_tooltips
        end

        it "creates keys for each namespace" do
          expect(@grouped.key? nil).to be true
          expect(@grouped.key? "references").to be true
          expect(@grouped.key? "taxa").to be true
        end

        it "groups keys without namespaces in the 'nil' bucket" do
          expect(@grouped[nil]).to eq [no_namespace]
        end

        it "groups keys with namespaces" do
          expect(@grouped["references"]).to eq [
            references_authors, references_new_title, references_title]
          expect(@grouped["taxa"]).to eq [taxa_type_species]
        end

        it "includes all items" do
          expect(@grouped.values.flatten.size).to eq Tooltip.count
        end
      end
    end

    context "not signed in" do
      before { get :index }

      it { should redirect_to(new_user_session_path) } # TODO extract this to a helper
    end
  end

  describe '#show' do
    let(:tooltip) { create :tooltip }

    context "signed in" do
      before do
        editor = create :user, can_edit: true
        sign_in editor
        get :show, id: tooltip.id
      end

      it { should render_template(:show) }
    end

    context "not signed in" do
      it 'redirects to sign in' do
        get :show, id: tooltip.id
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  describe '#new' do
    # TODO
  end

  describe '#edit' do
    let(:tooltip) { create :tooltip }

    context "signed in" do
      it 'redirects to the "show" action for the tooltip' do
        editor = create :user, can_edit: true
        sign_in editor

        get :edit, id: tooltip.id
        expect(response).to redirect_to tooltip
      end
    end

    context "not signed in" do
      it 'redirects to sign in' do
        get :edit, id: tooltip.id
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  describe '#create' do
    context "signed in" do
      before do
        editor = create :user, can_edit: true
        sign_in editor
      end

      context 'with valid attributes' do
        before do
          post :create, tooltip: { key: "references.authors" }
        end

        it 'creates the tooltips' do
          expect(Tooltip.count).to eq 1
        end

        it { should redirect_to(Tooltip.first) }
      end

      context 'with invalid attributes' do
        before do
          post :create, tooltip: { key: nil }
        end

        it 'does not create the tooltips' do
          expect(Tooltip.count).to eq 0
        end

        it { should render_template(:new) }
      end
    end

    context 'not signed in' do
      before do
        post :create, tooltip: { key: "references.authors" }
      end

      it 'does not create the tooltips' do
        expect(Tooltip.count).to eq 0
      end

      it { should redirect_to new_user_session_path }
    end
  end

  describe '#update' do
    # TODO
  end

  describe '#destroy' do
    # TODO
  end
end
