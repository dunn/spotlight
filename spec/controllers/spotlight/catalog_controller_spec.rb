require 'spec_helper'

describe Spotlight::CatalogController do
  routes { Spotlight::Engine.routes }

  describe "when the user is not authenticated" do

    describe "GET admin" do
      it "should redirect to the login page" do
        get :admin, exhibit_id: Spotlight::Exhibit.default
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end
    
    describe "GET edit" do
      let (:exhibit) {Spotlight::Exhibit.default}
      it "should not be allowed" do
        get :edit, exhibit_id: exhibit, id: 'dq287tq6352'
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end

    describe "GET show" do
      let (:exhibit) {Spotlight::Exhibit.default}
      let (:document) { SolrDocument.find('dq287tq6352') }
      let(:search) { FactoryGirl.create(:search) }
      it "should show the item" do
        expect(controller).to receive(:add_breadcrumb).with(exhibit.title, exhibit_path(exhibit, q: ''))
        expect(controller).to receive(:add_breadcrumb).with("L'AMERIQUE", exhibit_catalog_path(exhibit, document))
        get :show, exhibit_id: exhibit, id: 'dq287tq6352'
        expect(response).to be_successful
      end

      it "should show the item with breadcrumbs to the browse page" do
        controller.stub(current_browse_category: search)
        
        expect(controller).to receive(:add_breadcrumb).with(exhibit.title, exhibit_path(exhibit, q: ''))
        expect(controller).to receive(:add_breadcrumb).with("Browse", exhibit_browse_index_path(exhibit))
        expect(controller).to receive(:add_breadcrumb).with(search.title, exhibit_browse_path(exhibit, search))
        expect(controller).to receive(:add_breadcrumb).with("L'AMERIQUE", exhibit_catalog_path(exhibit, document))
        get :show, exhibit_id: exhibit, id: 'dq287tq6352'
        expect(response).to be_successful
      end
    end


    describe "GET index" do
      let (:exhibit) {Spotlight::Exhibit.default}
      it "should show the index" do
        expect(controller).to receive(:add_breadcrumb).with(exhibit.title, exhibit_path(exhibit, q: ''))
        expect(controller).to receive(:add_breadcrumb).with("Search Results", exhibit_catalog_index_path(exhibit, q:'map'))
        get :index, exhibit_id: exhibit, q: 'map'
        expect(response).to be_successful
      end

      it "should add the curation widget" do
        get :index, exhibit_id: exhibit, q: 'map'
        expect(controller.blacklight_config.show.partials.first).to eq "curation_mode_toggle"
      end
    end
  end

  describe "when the user is not authorized" do
    before do
      sign_in FactoryGirl.create(:exhibit_visitor)
    end

    describe "GET index" do
      it "should apply gated discovery access controls" do
        expect(controller.solr_search_params_logic).to include :apply_permissive_visibility_filter
      end
    end

    describe "GET admin" do
      it "should deny access" do
        get :admin, exhibit_id: Spotlight::Exhibit.default
        expect(response).to redirect_to main_app.root_path
        expect(flash[:alert]).to be_present
      end
    end

    describe "GET edit" do
      let (:exhibit) {Spotlight::Exhibit.default}
      it "should not be allowed" do
        get :edit, exhibit_id: exhibit, id: 'dq287tq6352'
        expect(response).to redirect_to main_app.root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end

    describe "GET show with private item" do
      let (:exhibit) {Spotlight::Exhibit.default}
      it "should not be allowed" do
        ::SolrDocument.any_instance.stub(:private?).and_return(true)
        get :show, exhibit_id: exhibit, id: 'dq287tq6352'
        expect(response).to redirect_to main_app.root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end

    describe "PUT make_public" do

      let (:exhibit) {Spotlight::Exhibit.default}
      it "should not be allowed" do
        put :make_public, exhibit_id: exhibit, catalog_id: 'dq287tq6352'
        expect(response).to redirect_to main_app.root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end

    end

    describe "DELETE make_private" do

      let (:exhibit) {Spotlight::Exhibit.default}
      it "should not be allowed" do
        delete :make_private, exhibit_id: exhibit, catalog_id: 'dq287tq6352'
        expect(response).to redirect_to main_app.root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end
  end

  describe "when the user is a curator" do
    before do
      sign_in FactoryGirl.create(:exhibit_curator)
    end
    let (:exhibit) { Spotlight::Exhibit.default }

    it "should show all the items" do
      expect(controller).to receive(:add_breadcrumb).with(exhibit.title, exhibit_path(exhibit, q: ''))
      expect(controller).to receive(:add_breadcrumb).with("Curation", exhibit_dashboard_path(exhibit))
      expect(controller).to receive(:add_breadcrumb).with("Items", admin_exhibit_catalog_index_path(exhibit))
      get :admin, exhibit_id: exhibit
      expect(response).to be_successful
      expect(assigns[:document_list]).to be_a Array
      expect(assigns[:exhibit]).to eq exhibit
      expect(response).to render_template "spotlight/catalog/admin"
    end

    before {sign_in FactoryGirl.create(:exhibit_curator)}

    describe "GET edit" do
      it "should be successful" do
        get :edit, exhibit_id: exhibit, id: 'dq287tq6352'
        expect(response).to be_successful
        expect(assigns[:exhibit]).to eq exhibit
        expect(assigns[:document]).to be_kind_of SolrDocument
      end
    end
    describe "PATCH update" do
      it "should be successful" do
        patch :update, exhibit_id: exhibit, id: 'dq287tq6352', solr_document: {tag_list: 'one, two'}
        expect(response).to be_redirect
      end
    end


    describe "PUT make_public" do
      before do
        request.env["HTTP_REFERER"] = "where_i_came_from"
        ::SolrDocument.any_instance.stub(:reindex)
      end

      it "should be successful" do
        ::SolrDocument.any_instance.should_receive(:reindex)
        ::SolrDocument.any_instance.should_receive(:make_public!).with(exhibit)
        put :make_public, exhibit_id: exhibit, catalog_id: 'dq287tq6352'
        expect(response).to redirect_to "where_i_came_from"
      end

    end

    describe "DELETE make_private" do

      before do
        request.env["HTTP_REFERER"] = "where_i_came_from"
        ::SolrDocument.any_instance.stub(:reindex)
      end

      it "should be successful" do
        ::SolrDocument.any_instance.should_receive(:reindex)
        ::SolrDocument.any_instance.should_receive(:make_private!).with(exhibit)
        delete :make_private, exhibit_id: exhibit, catalog_id: 'dq287tq6352'
        expect(response).to redirect_to "where_i_came_from"
      end
    end
  end
end
