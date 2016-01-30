# This migration comes from forem (originally 20110214221555)
class Forums < ActiveRecord::Migration
	def change
		create_table :forem_forums do |t|
	      t.string :title
	      t.text :description
	    end

	    create_table :forem_topics do |t|
	      t.integer :forum_id
	      t.integer :user_id
	      t.string :subject

	      t.timestamps :null => true
	    end

	    create_table :forem_posts do |t|
	      t.integer :topic_id
	      t.text :text
	      t.integer :user_id

	      t.timestamps :null => true
	    end

	    add_column :forem_posts, :reply_to_id, :integer
	    add_column :forem_topics, :locked, :boolean, :null => false, :default => false
	    add_column :forem_topics, :pinned, :boolean, :default => false, :nullable => false

	    create_table :forem_views do |t|
	      t.integer :user_id
	      t.integer :topic_id
	      t.datetime :created_at
	    end

	    add_column :forem_views, :updated_at, :datetime
    	add_column :forem_views, :count, :integer, :default => 0

    	add_column :forem_topics, :hidden, :boolean, :default => false

    	add_index :forem_topics, :forum_id
	    add_index :forem_topics, :user_id    
	    add_index :forem_posts, :topic_id
	    add_index :forem_posts, :user_id    
	    add_index :forem_posts, :reply_to_id    
	    add_index :forem_views, :user_id
	    add_index :forem_views, :topic_id    
	    add_index :forem_views, :updated_at 

	    create_table :forem_categories do |t|
	      t.string :name, :null => false
	      t.timestamps :null => true
	    end

	    add_column :forem_forums, :category_id, :integer

	    if Forem::Forum.count > 0
	      Forem::Forum.update_all :category_id => Forem::Category.first.id
	    end

	    create_table :forem_subscriptions do |t|
	      t.integer :subscriber_id
	      t.integer :topic_id
	    end

	    add_column :forem_posts, :pending_review, :boolean, :default => true

	    Forem::Post.reset_column_information
	    Forem::Post.update_all :pending_review => false

	    add_column :forem_topics, :pending_review, :boolean, :default => true

	    Forem::Topic.reset_column_information
	    Forem::Topic.update_all :pending_review => false

	    add_column :forem_topics, :last_post_at, :datetime
	    Forem::Topic.reset_column_information
	    Forem::Topic.includes(:posts).find_each do |t|
	      post = t.posts.last
	      t.update_attribute(:last_post_at, post.updated_at)
	    end

	    create_table :forem_groups do |t|
	      t.string :name
	    end

	    add_index :forem_groups, :name

	    create_table :forem_memberships do |t|
	      t.integer :group_id
	      t.integer :member_id
	    end

	    add_index :forem_memberships, :group_id

	    create_table :forem_moderator_groups do |t|
	      t.integer :forum_id
	      t.integer :group_id
	    end

	    add_index :forem_moderator_groups, :forum_id

	    remove_column :forem_posts, :pending_review
	    add_column :forem_posts, :state, :string, :default => 'pending_review'
	    add_index :forem_posts, :state

	    remove_column :forem_topics, :pending_review
	    add_column :forem_topics, :state, :string, :default => 'pending_review'
	    add_index :forem_topics, :state

	    Forem::Topic.update_all :state => "approved"
    	Forem::Post.update_all :state => "approved"

    	add_column :forem_posts, :notified, :boolean, :default => false

    	rename_column :forem_views, :topic_id, :viewable_id
	    add_column :forem_views, :viewable_type, :string
	    Forem::View.update_all("viewable_type='Forem::Topic'")

	    add_column :forem_views, :current_viewed_at, :datetime
	    add_column :forem_views, :past_viewed_at, :datetime
	    add_column :forem_topics, :views_count, :integer, :default=>0
	    add_column :forem_forums, :views_count, :integer, :default=>0

	    Forem::Topic.find_each do |topic|
	      topic.update_column(:views_count, topic.views.sum(:count))
	    end

	    Forem::Forum.find_each do |forum|
	      forum.update_column(:views_count, forum.topics.sum(:views_count))
	    end

	    unless column_exists?(user_class, :forem_admin)
	      add_column user_class, :forem_admin, :boolean, :default => false
	    end

	    unless column_exists?(user_class, :forem_state)
	      add_column user_class, :forem_state, :string, :default => 'pending_review'
	    end

	    unless column_exists?(user_class, :forem_auto_subscribe)
	      add_column user_class, :forem_auto_subscribe, :boolean, :default => false
	    end

	    add_column :forem_forums, :slug, :string
	    add_index :forem_forums, :slug, :unique => true
	    Forem::Forum.reset_column_information
	    Forem::Forum.find_each {|t| t.save! }

	    add_column :forem_categories, :slug, :string
	    add_index :forem_categories, :slug, :unique => true
	    Forem::Category.reset_column_information
	    Forem::Category.find_each {|t| t.save! }

	    add_column :forem_topics, :slug, :string
	    add_index :forem_topics, :slug, :unique => true
	    Forem::Topic.reset_column_information
	    Forem::Topic.find_each {|t| t.save! }

	    rename_column :forem_forums, :title, :name

	    add_column :forem_categories, :position, :integer, :default => 0

	    add_column :forem_forums, :position, :integer, :default => 0
	end

	def user_class
	    Forem.user_class.table_name.downcase.to_sym
	  end
end