#Find out which extracts have similar variables and if there are any patterns.  For variable x, check other extracts
#and see if patterns of choice appear.  ie. do people always seem to choose variable y when picking variable x. Also
#do it for pairs of variables ie, do people always seem to pick variables y and z when choosing variable x
#
#This version looks at a single extract

require 'rubygems'
require 'rake'

namespace :obesity do
  desc "check extracts for similarities and patterns"
  task :single_extract_similarity_match  => :environment do
    #Hash key is the variable from the checked extract, the value is another hash.
    #In this value hash the key is the variable that has been matched and the value
    #the number of extracts in which the match has been seen
    match_hash = Hash.new
    #keep a list of all the extracts which contain a particular var, should make it faster overall by caching this
    var_to_extract_match = Hash.new
    #keep all extracts in a map with only their var ids
    all_extracts_hash = Hash.new
    # previous_checks = Hash.new
    #extract is the source
    extract = Csvarchive.find(291)
    puts "Matching patterns for extract " + extract.id.to_s
    vars = extract.variables.collect{|var| var.id}
    #use each of the combinations to check against other extracts
    #firstly check with single occurences ie variable y always gets chosen when varible x is picked
    #vars is basically an array of integers which are the ids of the variables the extract contains
    vars.each do |var|
      extracts_with_this_var = []
      #is this the first time we have tried to match this var?
      if !var_to_extract_match.has_key?(var)
        Csvarchive.all.each do |inner_extract|
          extracts_with_this_var << inner_extract unless !inner_extract.variables.collect{|v| v.id}.include?(var)
        end
        #if this is the first time we have checked this var then keep a track of the extracts that contain it
        var_to_extract_match[var] = extracts_with_this_var
        end
        extracts_with_this_var = var_to_extract_match[var]
        #we don't check matches against the original var so remove it from the possible vars that we will check
        check_array = vars - [var]
        check_array.each do |check_var|
          #copy the array to avoid any reference problems
          extracts_to_check = Array.new(extracts_with_this_var)
          extracts_to_check.delete_if{|x| x.id == extract.id}
          #loop through each of the target extracts
          extracts_to_check.each do |extract_with_this_var|
	    if !all_extracts_hash.key?(extract_with_this_var.id)
	      all_extracts_hash[extract_with_this_var.id] = extract_with_this_var.variables.collect{|v| v.id}
	    end
            if all_extracts_hash[extract_with_this_var.id].include?(check_var)
              if !match_hash.key?(var)
                match_hash[var] = Hash.new
              end
              if !match_hash[var].has_key?(check_var)
                match_hash[var][check_var] = 0
              end
              #puts "source var " + var.to_s + " matched to target var " + check_var.to_s + " in extract " + extract_with_this_var.id.to_s
              match_hash[var][check_var] += 1 
            end
          end
        end
      end
    match_hash.each_key do |key|
      match_hash[key].each_key do |inner_key|
        #check if this variable pair have already been matched
        mvs = MatchedVariable.all(:conditions=>{:variable_id=>key,:target_variable_id=>inner_key})
	if mvs.empty?
          matched_var = MatchedVariable.new
	  matched_var.variable_id = key
	  matched_var.target_variable_id = inner_key
	  matched_var.occurences = match_hash[key][inner_key]
          matched_var.save
        else
          mvs[0].update_attributes(:occurences=>mvs[0].occurences += match_hash[key][inner_key])
        end
      end
    end
  end
end
