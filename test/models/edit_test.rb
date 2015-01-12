require 'test_helper'

class EditTest < ActiveSupport::TestCase
  fixtures :accounts

  before do
    project = create(:project, description: 'Linux')
    Edit.for_target(project).delete_all
    @edit = create(:create_edit, target: project)
    @previous_edit = create(:create_edit, value: '456', created_at: Time.now - 5.days, target: project)
  end

  it 'test_that_we_can_get_the_previous_value_of_an_edit' do
    @edit.previous_value.must_equal '456'
  end

  it 'test_that_previous_value_returns_nil_on_initial_edit' do
    @previous_edit.previous_value.must_equal nil
  end

  it 'test_that_undo_and_redo_work' do
    @edit.undo!(accounts(:admin))
    @edit.undone.must_equal true
    @edit.undoer.must_equal accounts(:admin)
    @edit.redo!(accounts(:user))
    @edit.undone.must_equal false
    @edit.undoer.must_equal accounts(:user)
  end

  it 'test_that_undo_requires_an_editor' do
    proc { @edit.undo!(nil) }.must_raise RuntimeError
  end

  it 'test_that_redo_requires_an_editor' do
    @edit.undo!(accounts(:admin))
    proc { @edit.undo!(nil) }.must_raise RuntimeError
  end

  it 'test_that_undo_can_only_be_called_once' do
    @edit.undo!(accounts(:admin))
    proc { @edit.undo!(accounts(:admin)) }.must_raise ActsAsEditable::UndoError
  end

  it 'test_that_redo_can_only_be_called_after_an_undo' do
    proc { @edit.redo!(accounts(:admin)) }.must_raise ActsAsEditable::UndoError
  end

  it 'test_that_project_gets_filled_in_automatically_for_project_edits' do
    p = create(:project)
    edit = CreateEdit.where(target: p).first
    edit.project_id.must_equal edit.target.id
    edit.organization_id.must_equal nil
  end

  it 'test_that_project_gets_filled_in_automatically_for_project_license_edits' do
    pl = create(:project_license, project: create(:project), license: create(:license))
    edit = CreateEdit.where(target: pl).first
    edit.project_id.must_equal edit.target.project.id
    edit.organization_id.must_equal nil
  end

  it 'test_that_organization_gets_filled_in_automatically_for_organization_edits' do
    org = create(:organization)
    edit = CreateEdit.where(target: org).first
    edit.organization_id.must_equal edit.target.id
    edit.project_id.must_equal nil
  end

  it 'test_that_project_and_organization_get_filled_in_automatically_when_associating_project_to_an_org' do
    p = create(:project)
    org = create(:organization)
    p.update_attributes(organization_id: org.id)
    edit = PropertyEdit.where(target: p, key: 'organization_id').first
    edit.project_id.must_equal p.id
    edit.organization_id.must_equal org.id
  end

  it 'test_that_nothing_gets_filled_in_automatically_for_license_edits' do
    l = create(:license)
    edit = CreateEdit.where(target: l).first
    edit.project_id.must_equal nil
    edit.organization_id.must_equal nil
  end
end