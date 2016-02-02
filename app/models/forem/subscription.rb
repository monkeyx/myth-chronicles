module Forem
  class AsyncNotifier
     @queue = :emails

     def self.perform(sub_id, post_id)
      logger.info "HELLO IS IT ME YOU'RE LOOKING FOR"
      Subscription.find(sub_id).really_send_notification(post_id)
    end
  end

  class Subscription < ActiveRecord::Base

    belongs_to :topic
    belongs_to :subscriber, :class_name => Forem.user_class.to_s

    validates :subscriber_id, :presence => true

    def send_notification(post_id)
      Resque.enqueue(AsyncNotifier, self.id, post_id)
    end

    def really_send_notification(post_id)
      # If a user cannot be found, then no-op
      # This will happen if the user record has been deleted.
      if subscriber.present?
        post = Post.find(post_id)
        topic = post.topic
        topic_path = Forem::Engine.routes.url_helpers.forum_topic_path(post.topic.forum_id, post.topic)
        unsub_path = Forem::Engine.routes.url_helpers.unsubscribe_forum_topic_path(post.topic.forum, post.topic)
        UserMailer.topic_reply(post_id, subscriber_id, topic_path, unsub_path).deliver
      end
    end
  end
end