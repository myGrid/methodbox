atom_feed :language => "en-GB", :root_url => "/people",
    :id => "urn:methodbox:people:feed",
    'xmlns:openSearch' => 'http://a9.com/-/spec/opensearch/1.1/' do |feed|
  feed.title "MethodBox People"
  feed.updated !@people.first.nil? ? @people.first.created_at : Time.now
  feed.tag! "openSearch:totalResults", @people.length

  @people.each do |item|
    feed.entry item, :id => "urn:methodbox:people:#{item.id}" do |entry|

    end
  end
end
