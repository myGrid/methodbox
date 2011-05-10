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
    # previous_checks = Hash.new
    archive = Csvarchive.find(236)
      puts "Matching patterns for extract " + archive.id.to_s
      vars = archive.variables.collect{|var| var.id}
      #use each of the combinations to check against other extracts
      #firstly check with single occurences ie variable y always gets chosen when varible x is picked
      vars.each do |var|
        match_hash[var] = Hash.new
        extracts_with_this_var = []
        Csvarchive.all.each do |inner_extract|
          extracts_with_this_var << inner_extract unless !inner_extract.variables.collect{|v| v.id}.include?(var)
        end

        check_array = vars - [var]
        check_array.each do |check_var|
          match_hash[var][check_var] = 0
          extracts_with_this_var.each do |extract_with_this_var|
            if extract_with_this_var.variables.collect{|v| v.id}.include?(check_var)
              match_hash[var][check_var] += 1 
            end
          end
        end
      end
    number_of_matches_hash = Hash.new
    match_hash.each_key do |key|
      match_hash[key].each_key do |inner_key|
        puts key.to_s + " has " + match_hash[key][inner_key].to_s + " matches of " + inner_key.to_s
        if !number_of_matches_hash.has_key?(match_hash[key][inner_key].to_s)
		number_of_matches_hash[match_hash[key][inner_key].to_s] = 1
	else
	number_of_matches_hash[match_hash[key][inner_key].to_s] += 1
	end
      end
   end
number_of_matches_hash.each_key do |key|
	puts "Number of matches " + key.to_s + " = " + number_of_matches_hash[key].to_s
end
end
end
