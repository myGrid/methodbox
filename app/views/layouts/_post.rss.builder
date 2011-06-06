xm.item do
  if post.user!= nil
    user_name = post.user.display_name
  else
     user_name = "User no longer has account"
  end
  key = post.topic.posts.size == 1 ? :topic_posted_by : :topic_replied_by
  xm.title "{title} posted by {user_name} @ {date}"[key, h(post.respond_to?(:topic_title) ? post.topic_title : post.topic.title), h(user_name), post.created_at.rfc822]
  xm.description post.body_html
  xm.pubDate post.created_at.rfc822
  xm.guid [request.host_with_port+request.relative_url_root, post.forum_id.to_s, post.topic_id.to_s, post.id.to_s].join(":"), "isPermaLink" => "false"
  xm.author "#{user_name}"
  xm.link forum_topic_url(post.forum_id, post.topic_id)
end
