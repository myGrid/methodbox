module SurveysHelper
  
  require 'linkeddata'

#  require 'rubygems'
#  require 'faster_csv'
#
#  def parse_csv survey
#    table = FSCV.parse(survey, :headers => true, :return_headers => true)
#    #work in progress
#    table.by_col!
#  end

#generate an RDF triple representation of the publicly available surveys
def convert_to_linked_data survey_hash
  graph = RDF::Graph.new 
  survey_hash.each_key do |key| 
    survey_hash[key].each do |survey| 
      graph << RDF::Statement.new({ :subject   => RDF::URI.new(survey_url(survey)), :predicate => RDF::type,:object    => RDF::DC.Dataset, })
      graph << RDF::Statement.new({ :subject   => RDF::URI.new(survey_url(survey)), :predicate => RDF::DC.description, :object => "\"" + survey.description + "\"", })
  		if survey.survey_type.is_ukda
  	    graph << RDF::Statement.new({ :subject   => RDF::URI.new(survey_url(survey)), :predicate => RDF::DC.creator, :object    => RDF::URI.new("http://www.esds.ac.uk"), })
  		else 
        graph << RDF::Statement.new({ :subject   => RDF::URI.new(survey_url(survey)), :predicate => RDF::DC.creator, :object   => RDF::URI.new(user_url(survey.contributor_id)), })
  		end
  		# get all the links, only one way at the moment TODO helper method to get links both ways %>
  		Link.find(:all, :conditions => { :object_type => "Survey", :object_id => survey.id, :predicate => "link", :subject_type => "Script"}).each do |link| 
  		  graph << RDF::Statement.new({ :subject   => RDF::URI.new(survey_url(survey)), :predicate => RDF::SKOS.related, :object   => RDF::URI.new(script_url(link.subject_id)), })
      end 
  		Link.find(:all, :conditions => { :object_type => "Survey", :object_id => survey.id, :predicate => "link", :subject_type => "Csvarchive"}).each do |link|
  		  graph << RDF::Statement.new({ :subject   => RDF::URI.new(survey_url(survey)), :predicate => RDF::SKOS.related, :object   => RDF::URI.new(csvarchive_url(link.subject_id)), })
  	  end
    end
  end 
  return graph
end

end
