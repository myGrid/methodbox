class UserSearchesController < ApplicationController
  
    before_filter :find_search, :only => [ :show ]
    
    def show
      if current_user.id == UserSearch.find(params[:id]).user.id
        respond_to do |format|
          format.html # show.html.erb
          format.xml
        end
      else
        respond_to do |format|
          flash[:error] = "You do not have permission to view the results of this search"
          format.html { redirect_to(:back) }
        end
      end
    end
    
    private

     #find any previous searches if you are looking at your own
     #profile
     def find_all_previous_searches
       search=[]
       if logged_in? && current_user.id == Person.find(params[:id]).user.id
         search = UserSearch.all(:order => "created_at DESC", :conditions => { :user_id => current_user.id})
       end
       @recent_searches = search
     end

     #find any previous searches if you are looking at your own
     #profile
     def find_search
       if logged_in? && current_user.id == UserSearch.find(params[:id]).user.id
         @search = UserSearch.find(params[:id])
       end
     end

end