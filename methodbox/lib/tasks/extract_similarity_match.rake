#Find out which extracts have similar variables and if there are any patterns

require 'rubygems'
require 'rake'

namespace :obesity do
  desc "check extracts for similarities and patterns"
  task :extract_similarity_match  => :environment do
    match_hash = Hash.new
    # previous_checks = Hash.new
    archive = Csvarchive.find(238)
    # Csvarchive.first do |extract|
    Csvarchive.all.each do |extract|
      puts "Matching patterns for extract " + extract.id.to_s
      vars = extract.variables.collect{|var| var.id}
      #use each of the combinations to check against other extracts
      #firstly with single occurences
      vars.each do |var|
        match_hash[var] = Hash.new
        extracts_with_this_var = []
        Csvarchive.all.each do |inner_extract|
          extracts_with_this_var << inner_extract unless !inner_extract.variables.collect{|v| v.id}.include?(var)
        end
        # puts extracts_with_this_var.empty? ? "No extracts also contain var " + var.to_s : "These extracts also contain " + var.to_s + ": " + extracts_with_this_var.collect{|v| v.id}.join(",")
        #we now have all the extracts which also contain this var
        check_array = vars - [var]
        # previous_checks[extract.id] = Hash.new
        check_array.each do |check_var|
          match_hash[var][check_var] = 0
          extracts_with_this_var.each do |extract_with_this_var|
            # if previous_checks.has_key?(extract_with_this_var.id)
            #               if previous_checks[extract_with_this_var.id][extract.id] != nil && previous_checks[extract_with_this_var.id][extract.id].include?(check_var)
            #                 puts extract.id.to_s + " says no need to check " + extract_with_this_var.id.to_s + " for " + check_var.to_s
            #                 next
            #               end
            #             end
            # previous_checks[extract.id][extract_with_this_var.id] = [] if previous_checks[extract.id][extract_with_this_var.id] == nil
            #            previous_checks[extract.id][extract_with_this_var.id] << check_var
            if extract_with_this_var.variables.collect{|v| v.id}.include?(check_var)
              match_hash[var][check_var] += 1 
              # puts "Extract " +  extract_with_this_var.id.to_s + " also has " + check_var.to_s
            end
          end
        end
        # puts "Matches for var: " + var.to_s + ": " + match_hash.to_s
        # match_hash.each_key do |key|
        #   match_hash[key].each_key do |inner_key|
        #     puts key.to_s + " has " + match_hash[key][inner_key].to_s + " matches of " + inner_key.to_s
        #   end
        # end
      end
      
      # for i in 0..vars.size -1
      #   vars.combination(i){|x| p x}
      #   vars - [vars[0]]
      # end
    end
    match_hash.each_key do |key|
      match_hash[key].each_key do |inner_key|
        puts key.to_s + " has " + match_hash[key][inner_key].to_s + " matches of " + inner_key.to_s
      end
    end
  end
end