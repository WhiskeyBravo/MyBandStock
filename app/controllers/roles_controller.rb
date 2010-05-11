class RolesController < ApplicationController

  before_filter :authenticated?
  before_filter :user_has_site_admin
  skip_filter :update_last_location, :except => [:index]
  protect_from_forgery :only => [:create, :update]
  
  
  def toggle_user_role
    unless ( (@user = User.find_by_email(params[:role][:user_email].strip)) && (@role = Role.find(params[:role][:id])) )
      redirect_to session[:last_clean_url]
      return false
    end
    
    
    @user.toggle_role(@role.id)
    
    
    respond_to do |format|
        format.html {
                      flash[:notice] = 'User role toggled.'
                      redirect_to session[:last_clean_url]
                    }
        format.js
        format.xml  { head :ok }
    end
  end
  
=begin  
  def auto_complete_for_role_user_email
    unless ( (params[:role] && (email_search = params[:role][:user_email]) ) && (email_search.length >= 3) )
      render :nothing => true
      return false
    end
    
    @users = User.find(:all, :conditions => ['email LIKE ?', "%#{email_search}%"], :limit => 15)

    respond_to do |format|
      format.html {
                    render :nothing => true
                  }
      format.js   {
                    #dont like calling render in the code but it is what it is
                    render :partial => 'roles/user_email_autocomplete', :locals => {:user_collection => @users}
                  }
      format.xml
    end
    
  end
=end  
  
  def index
    @roles = Role.find(:all, :order => ['created_at asc'])

    respond_to do |format|
        format.html
        format.js
        format.xml  { head :ok }
    end
    
  end


  def new
    @role = Role.new
    @user = User.find(session[:user_id])
    
    respond_to do |format|
        format.html
        format.js
        format.xml  { head :ok }
    end
  end


    def create
    @role = Role.new(params[:role])
    success = @role.save

    respond_to do |format|
      format.html { 
                    if success
                      flash[:notice] = 'Role created.'
                      redirect_to session[:last_clean_url]
                    else
                      @user = User.find(session[:user_id])
                      render :controller => 'roles', :action => 'new'
                    end
                  }
      format.js 
      format.xml  { head :ok }
    end
  end
  
  
  def edit
    unless ( @role = Role.find(params[:id]) )
      redirect_to session[:last_clean_url]
      return false
    end
    
    respond_to do |format|
      format.html
      format.js
      format.xml
    end
  end
  
  
  def update
    unless ( @role = Role.find(params[:id]) )
      redirect_to session[:last_clean_url]
      return false
    end
    
    @role.update_attributes(params[:role])
    @role.save
    
    respond_to do |format|
      format.html {
                    redirect_to session[:last_clean_url]
                  }
      format.js
      format.xml
    end
    
  end
  
  
  def show
    unless ( @role = Role.find(params[:id]) )
      redirect_to session[:last_clean_url]
      return false
    end
    
    respond_to do |format|
      format.html
      format.js
      format.xml
    end
    
  end
  
  
  def destroy
    #site admin check included in before_filter
    unless (@role = Role.find(params[:id]))
      redirect_to session[:last_clean_url]
      return false
    end

    @old_role_id = @role.id
    @role.destroy

    respond_to do |format|
      format.html {
                    redirect_to session[:last_clean_url]
                  } 
      format.js   #let the rjs render
      format.xml
    end
    
  end





#end controller
end
