class BaselinesController < ApplicationController
  unloadable

  model_object Baseline

  before_filter :find_model_object, :except => [:new, :create]
  before_filter :find_project_from_association, :except => [:new, :create]
  before_filter :find_project_with_project_id, :only => [:new, :create]
  before_filter :authorize

  def show
  end

  def new
    @baseline = Baseline.new
  end

  def create
    @baseline = Baseline.new(params[:baseline])
    @baseline.project = @project
    @baseline.state = l(:label_current_baseline)
    @baseline.start_date = @project.start_date || @project.created_on.to_date

    if @baseline.save

      @baseline.create_versions(@project.versions)
      @baseline.create_issues(@project.issues)
      flash[:notice] = l(:notice_successful_create)
      redirect_to settings_project_path(@project, :tab => 'baselines')
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    if request.put? && params[:baseline]
      attributes = params[:baseline].dup
      @baseline.safe_attributes = attributes
      if @baseline.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to settings_project_path(@project, :tab => 'baselines')
      else
        render :action => 'edit'
      end
    end
  end

  def destroy
    @baseline.destroy
    redirect_to settings_project_path(@project, :tab => 'baselines')
  end

  private 

  def find_project_with_project_id
    @project = Project.find(params[:project_id])
  end
end