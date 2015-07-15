module ProjectFilters
  extend ActiveSupport::Concern

  included do
    before_action :session_required, only: [:check_forge, :create, :new, :update]
    before_action :find_account
    before_action :find_projects, only: [:index]
    before_action :find_project, only: [:show, :edit, :update, :estimated_cost, :users, :settings, :map,
                                        :similar_by_tags, :similar]
    before_action :redirect_new_landing_page, only: :index
    before_action :find_forge_matches, only: :check_forge
    before_action :project_context, only: [:show, :users, :estimated_cost, :edit, :settings, :map, :similar, :update]
    before_action :show_permissions_alert, only: [:settings, :edit]
    before_action :set_session_projects, only: :index
    before_action :set_rating_and_score, only: :show
  end

  private

  def find_account
    @account = Account.from_param(params[:account_id]).take
  end

  def find_projects
    @projects = find_projects_by_params.page(params[:page]).per_page([25, (params[:per_page] || 10).to_i].min).to_a
  rescue
    raise ParamRecordNotFound
  end

  def find_projects_by_params
    @sort = params[:sort]
    projects = @account ? @account.projects.not_deleted : Project.not_deleted
    projects.by_collection(params[:ids], @sort, params[:query])
  end

  def find_project
    @project = Project.from_param(params[:id]).take
    fail ParamRecordNotFound unless @project
    @project.editor_account = current_user
  end

  def find_forge_matches
    @match = Forge::Match.first(params[:codelocation])
    return unless @match
    @projects = Project.where(id: Repository.matching(@match).joins(:projects).select('projects.id')).not_deleted
  end

  def set_rating_and_score
    @analysis = @project.best_analysis
    @rating = logged_in? ? @project.ratings.where(account_id: current_user.id).first : nil
    @score = @rating ? @rating.score : 0
  end

  def redirect_new_landing_page
    return unless @account.nil?
    redirect_to projects_explores_path if request.query_parameters.except('action').empty? && request_format == 'html'
  end
end
