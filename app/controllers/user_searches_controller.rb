class UserSearchesController < ApplicationController
  
    before_filter :find_search, :only => [ :show ]
    after_filter :update_last_user_activity
    
    def show
      if current_user.id == UserSearch.find(params[:id]).user.id
        variables_hash = {"total_entries"=>@search.variables.size, "results" => @search.variables.sort{|x,y| x.name <=> y.name}.collect{|variable| {"id" => variable.id, "name"=> variable.name, "description"=>variable.value, "survey"=>variable.dataset.survey.title, "year"=>variable.dataset.survey.year, "category"=>variable.category, "popularity" => VariableList.all(:conditions=>"variable_id=" + variable.id.to_s).size}}}
        @variables_json = variables_hash.to_json
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
       if user_signed_in? && current_user.id == Person.find(params[:id]).user.id
         search = UserSearch.all(:order => "created_at DESC", :conditions => { :user_id => current_user.id})
       end
       @recent_searches = search
     end

     #find any previous searches if you are looking at your own
     #profile
     def find_search
       if user_signed_in? && current_user.id == UserSearch.find(params[:id]).user.id
         @search = UserSearch.find(params[:id])
       end
     end

end
