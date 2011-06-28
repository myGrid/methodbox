atom_feed :language => "en-GB", :root_url => "/csvarchives",
    :id => "urn:methodbox:csvarchive:feed",
    'xmlns:openSearch' => 'http://a9.com/-/spec/opensearch/1.1/' do |feed|
  feed.title "MethodBox Data Extracts"
  feed.updated !@archives.first.nil? ? @archives.first.created_at : Time.now
  feed.tag! "openSearch:totalResults", @archives.length

  @archives.each do |item|
    feed.entry item, :id => "urn:methodbox:csvarchive:#{item.id}" do |entry|
      entry.title item.title
      entry.summary truncate(white_list(item.description), :length=>200)
      entry.author do |author|
        person = Person.find(item.user_id)
        author.name h(person.name)
        author.email person.email
        author.uri person_path(person, :only_path => false)
      end
      if Authorization.is_authorized?("download", nil, item, current_user)
        entry.content "type" => item.content_type,
                      "src" => csvarchive_path(item, :only_path => false) + "/download"
      end
    end
  end
end
