def get_all_authors(pub)
  authors = []

  pub.asset.creators.each do |author|
    authors << author.person.name
  end
  pub.non_seek_authors.each do |author|
    authors << author.last_name + " " + author.first_name
  end

  authors
end

atom_feed :language => "en-GB", :root_url => "/publications",
    :id => "urn:methodbox:publication:feed",
    'xmlns:openSearch' => 'http://a9.com/-/spec/opensearch/1.1/' do |feed|

  feed.title "MethodBox Publications"
  feed.updated !@publications.first.nil? ? @publications.first.created_at : Time.now
  feed.tag! "openSearch:totalResults", @publications.length

  @publications.each do |item|
    published = !item.published_date.nil? ? item.published_date : Time.now
    feed.entry item, :id => "urn:methodbox:publication:#{item.id}",
    :published => published do |entry|
      entry.title item.title
      entry.summary truncate(white_list(item.abstract), :length=>200)
      get_all_authors(item).each do |creator|
        entry.author do |author|
            author.name h(creator)
        end
      end
      unless item.pubmed_id.nil?
        entry.content "type" => "text/html",
                      "src" => "http://www.ncbi.nlm.nih.gov/pubmed/#{item.pubmed_id}"
      end
      unless item.doi.nil?
        entry.content "type" => "text/html",
                      "src" => "http://dx.doi.org/#{item.doi}"
      end
    end
  end
end
