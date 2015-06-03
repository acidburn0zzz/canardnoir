class StackEntriesController < ApplicationController
  helper RatingsHelper
  helper StacksHelper

  before_action :session_required
  before_action :find_stack
  before_action :find_project, :unless => :i_use_this?
  before_action :find_project_xhr, only: [:create], :if => :i_use_this?
  before_action :find_stack_entry, only: [:destroy]

  def create
    stack_entry = StackEntry.create(stack_id: @stack.id, project_id: @project.id)
    if stack_entry.persisted?
      respond_to do |format|
        format.html { render json: { stack_entry: stack_entry_html(stack_entry), result: 'okay', updated_count: 1 }, status: :ok }
        format.json { render nothing: true }
      end
    else
      render json: { result: 'error' }, status: :unprocessable_entity
    end
  end

  def destroy
    respond_to do |format|
      format.html { render json: { result: 'okay' }, status: (@stack_entry.destroy ? :ok : :unprocessable_entity) }
      format.json { render nothing: true }
    end
  end

  private

  def find_stack
    @stack = Stack.find_by_id(params[:stack_id])
    fail ParamRecordNotFound if @stack.nil? || (@stack.account_id != current_user.id)
  end

  def find_project
    se_params = params[:stack_entry]
    @project = find_project_by_url_name(se_params[:project_id]) || find_project_by_name(se_params[:project_name])
    fail ParamRecordNotFound if @project.nil?
  end

  def find_project_xhr
    @project = Project.from_param(params[:project_id]).first
    fail ParamRecordNotFound if @project.nil?
  end

  def find_project_by_url_name(url_name)
    Project.find_by_url_name(url_name) if url_name
  end

  def find_project_by_name(name)
    Project.find_by_name(name) if name
  end

  def find_stack_entry
    @stack_entry = StackEntry.find_by_id(params[:id])
    fail ParamRecordNotFound if @stack_entry.nil?
  end

  def stack_entry_html(stack_entry)
    locals = { stack_entry: stack_entry, hidden: true, editable: true }
    render_to_string partial: 'stacks/stack_entry.html.haml', locals: locals
  end

  def i_use_this?
    request.xhr?
  end
end
