# frozen_string_literal: true

require 'test_helper'

describe 'LinksControllerTest' do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:user) { create(:account) }

  before do
    @link_homepage = create(:link, project: project, link_category_id: Link::CATEGORIES[:Homepage])
    @link_download = create(:link, project: project, link_category_id: Link::CATEGORIES[:Download])
  end

  it 'after edit user is taken to index if they came from another page' do
    link = nil

    edit_as(admin) do
      link = create(:link, project_id: project.id)
    end

    edit_as(admin) do
      request.session[:return_to] = 'https://test.host:80/p/linux'

      put :update, project_id: project.vanity_url, id: link.id,
                   link: attributes_for(:link)

      must_redirect_to project_links_path(project)
    end
  end

  it 'after save user is taken to index' do
    link = nil

    edit_as(admin) do
      link = create(:link, project_id: project.id)
    end

    edit_as(user) do
      put :update, project_id: project.vanity_url, id: link.id,
                   link: attributes_for(:link)
      must_redirect_to project_links_path(project)
    end
  end

  it 'must display alert on index action for non manager' do
    restrict_edits_to_managers project

    login_as create(:account)

    get :index, project_id: project.vanity_url

    assert_select '.alert', text: "×\n\nYou can view, but not change this data. Only managers may change this data."
  end

  it 'must redirect to login page on new action for non manager' do
    restrict_edits_to_managers project

    get :new, project_id: project.vanity_url
    project.reload.wont_be :edit_authorized?
    must_redirect_to new_session_path
  end

  it 'must render projects/deleted when project is deleted' do
    project = create(:project)
    project.update!(deleted: true, editor_account: admin)

    get :new, project_id: project.to_param

    must_render_template 'deleted'
  end

  it 'must redirect to login page on edit action for non manager' do
    link = create(:link, project_id: project.id)

    restrict_edits_to_managers project

    get :edit, project_id: project.vanity_url, id: link.id

    must_redirect_to new_session_path
  end

  describe 'single category links' do
    let(:link) do
      as(admin) do
        project.links.find_by(link_category_id: Link::CATEGORIES[:Homepage])
      end
    end

    describe 'new' do
      it 'must not be shown if the link already exists' do
        as(admin) do
          get :new, project_id: project.vanity_url
          assigns(:categories)[:Homepage].must_be_nil
        end
      end

      it 'must be shown if link does not exist' do
        as(admin) do
          link.editor_account = admin
          link.destroy
          get :new, project_id: project.vanity_url
          assigns(:categories)[:Homepage].must_equal Link::CATEGORIES[:Homepage]
        end
      end

      it 'download link must not be shown if it already exists' do
        as(admin) do
          link.editor_account = admin
          link.update!(title: 'Project Download page',
                       link_category_id: Link::CATEGORIES[:Download])

          get :new, project_id: project.vanity_url
          assigns(:categories)[:Download].must_be_nil
        end
      end
    end

    describe 'create' do
      it 'must not be shown if the link already exists' do
        as(admin) do
          project.links.first.link_category_id.must_equal Link::CATEGORIES[:Homepage]

          post :create, project_id: project.vanity_url,
                        link: attributes_for(:link)

          assigns(:categories)[:Homepage].must_be_nil
        end
      end

      it 'must be shown if link does not exist' do
        as(admin) do
          link.editor_account = admin
          link.destroy

          post :create, project_id: project.vanity_url,
                        link: attributes_for(:link)

          assigns(:categories)[:Homepage].must_equal Link::CATEGORIES[:Homepage]
        end
      end

      it 'must be shown if link is being created' do
        as(admin) do
          link.editor_account = admin
          link.destroy

          post :create, project_id: project.vanity_url,
                        link: attributes_for(:link, link_category_id: Link::CATEGORIES[:Homepage])

          assigns(:categories)[:Homepage].must_equal Link::CATEGORIES[:Homepage]
        end
      end
    end

    describe 'update' do
      let(:other_link) do
        create(:link, project_id: project.id,
                      link_category_id: Link::CATEGORIES[:Other])
      end

      it 'must be shown if the link is being updated' do
        as(admin) do
          put :update, id: link.id, project_id: project.vanity_url, link: { title: nil }

          assigns(:categories)[:Homepage].must_equal Link::CATEGORIES[:Homepage]
        end
      end

      it 'must be shown if does not exist and other link is being updated' do
        as(admin) do
          link.editor_account = admin
          link.destroy

          put :update, id: other_link.id, project_id: project.vanity_url,
                       link: { title: :new_title }

          assigns(:categories)[:Homepage].must_equal Link::CATEGORIES[:Homepage]
        end
      end
    end

    it 'must be shown if the link is being edited' do
      as(admin) do
        get :edit, id: link.id, project_id: project.vanity_url
        assigns(:categories)[:Homepage].must_equal Link::CATEGORIES[:Homepage]
      end
    end
  end

  it 'index' do
    get :index, project_id: project.vanity_url
    must_respond_with :success
  end

  it 'new' do
    login_as(admin)
    get :new, project_id: project.vanity_url
    must_respond_with :success
  end

  it 'edit' do
    link = create(:link, project: project)
    login_as(admin)
    get :edit, project_id: project.vanity_url, id: link.id
    must_respond_with :success
  end

  it 'create_with_existing_link' do
    link1 = create(:link, project_id: project.id, link_category_id: Link::CATEGORIES[:Homepage])
    link1.destroy

    create(:link, project_id: project.id, link_category_id: Link::CATEGORIES[:Homepage])
    login_as(admin)

    assert_difference('project.reload.links.count', 1) do
      post :create, project_id: project.vanity_url,
                    link: attributes_for(:link, link_category_id: Link::CATEGORIES[:Homepage])

      must_redirect_to project_links_path(project)
      flash[:success].must_equal I18n.t('links.create.success')
    end
  end

  it 'create_without_existing_link' do
    login_as(admin)
    assert_difference('project.reload.links.count', 1) do
      post :create, project_id: project.vanity_url,
                    link: attributes_for(:link, link_category_id: Link::CATEGORIES[:Homepage])
      must_redirect_to project_links_path(project)
      flash[:success].must_equal I18n.t('links.create.success')
    end
  end

  it 'create' do
    login_as(admin)
    assert_difference('project.reload.links.count', 1) do
      post :create, project_id: project.vanity_url,
                    link: attributes_for(:link, link_category_id: Link::CATEGORIES[:Homepage])

      must_redirect_to project_links_path(project)
    end
  end

  it 'load_category_and_title_for_new_homepage_link' do
    category_id = Link::CATEGORIES[:Homepage]
    login_as(admin)

    get :new, project_id: project.vanity_url, category_id: category_id
    assigns(:category_name).must_equal 'Homepage'
    assigns(:link).title.must_equal 'Homepage'
  end

  it 'load_category_and_title_for_new_download_link' do
    login_as(admin)

    get :new, project_id: project.vanity_url, category_id: Link::CATEGORIES[:Download]
    assigns(:category_name).must_equal 'Download'
    assigns(:link).title.must_equal 'Downloads'
  end

  it 'load_category_and_title_for_new_other_link' do
    category_id = Link::CATEGORIES[:Other]
    login_as(admin)

    get :new, project_id: project.vanity_url, category_id: category_id
    assigns(:category_name).must_equal 'Other'
    assigns(:link).title.must_be_nil
  end

  it 'should_allow_same_url_in_two_categories' do
    project = create(:project)

    link_to_be_deleted = create(:link, link_category_id: Link::CATEGORIES[:Homepage], project: project)
    create(:link, project: project, link_category_id: Link::CATEGORIES[:Download])

    login_as(admin)
    delete :destroy, id: link_to_be_deleted.id, project_id: project.vanity_url

    project.links.size.must_equal 1
  end

  it 'should gracefully handle errors when trying to delete a link' do
    link = create(:link, project: create(:project))
    Link.any_instance.stubs(:destroy).returns false
    delete :destroy, id: link.id, project_id: link.project.vanity_url
    must_respond_with 302
  end

  it 'should_not_create_if_link_was_soft_deleted_already_in_a_link_category' do
    project = create(:project)

    create(:link, project: project, link_category_id: Link::CATEGORIES[:Homepage])

    login_as(admin)

    assert_no_difference 'project.links.count' do
      post :create, project_id: project.vanity_url,
                    link: { title: 'A Link', link_category_id: Link::CATEGORIES[:Homepage] }
    end
  end

  it 'load_category_and_title_for_edit_link' do
    category_id = Link::CATEGORIES['Forums']

    create(:link, title: 'Title', project: project, link_category_id: category_id)

    link = Link.find_by(link_category_id: Link::CATEGORIES[:Forums])
    login_as(admin)

    get :edit, project_id: project.vanity_url, id: link.id
    assigns(:category_name).must_equal 'Forums'
    assigns(:link).title.must_equal 'Title'
  end
end
