# Create access policies for all the surveys created before sharing was
# added to surveys

require 'rubygems'
require 'rake'

namespace :obesity do
  desc "create new policies for surveys without any"
  task :create_policies_for_surveys  => :environment do
    # choose the user you want all the surveys without policies to belong to
    user_id = 6
    current_user = User.find(user_id)
    Survey.all.each do |survey|
      unless survey.asset != nil
          policy = Policy.new(:name => 'auto',
                    :contributor_type => 'Person',
                    :contributor_id => current_user.person.id,
                    :sharing_scope => 4,
                    :access_type => 2,
                    :use_custom_sharing => false,
                    :use_whitelist => false,
                    :use_blacklist => false)
          asset = Asset.new
          asset.contributor = current_user
          asset.resource = survey
          asset.policy = policy
          asset.save  
      end
    end
  end
end