class UserMailer < MandrillMailer::TemplateMailer
	def setup_complete(user_id)
		user = User.find(user_id)
		standard_email(user, "Welcome to Myth Chronicles", 'Welcome to Myth Chronicles',
			["Your new character <strong>#{user.character.character_type} #{user.character.name}</strong> is ready to <a href=\"#{EMAIL_HOME_URL}/#sign_in\" style=\"color:#ffc600; text-decoration:underline;\"><strong>Play</strong></a>"],
			["Your new character #{user.character.character_type} {{user.character.name}} is ready to play:\n#{EMAIL_HOME_URL}/#sign_in"])
	end

	def status_update(user_id, status_updates)
		user = User.find(user_id)
		standard_email(user, "[Myth Chronicles] #{user.game.game_time}", user.game.game_time.to_s, status_updates)
	end

	def character_killed(user_id, character_id, reason)
		user = User.find(user_id)
		character = Character.find(character_id)
		standard_email(user, "[Myth Chronicles] Death of #{character.name}", "Death of #{character.name}", ["<h2>Dear #{user.name}</h2>
    		<br>
    		Unfortunately, #{character.character_type} #{character.name} died #{reason}.<br>
    		<br>
    		We hope you will come back and try again!
    		<p>Please visit <a style='color:#cccccc; text-decoration:underline;' href='#{EMAIL_HOME_URL}'>#{EMAIL_HOME_URL}</a> to create your new character.</p>"])
	end

	def send_email(message, receiver)
		if message.conversation.messages.size > 1
			reply_message_email(message,receiver)
		else
			new_message_email(message,receiver)
		end
	end

	def new_message_email(message,receiver_id)
		receiver = User.find(receiver_id)
		standard_email(receiver, "[Myth Chronciles] New message received",message.subject,["<p>
      You have received a new message:
    </p>
    <blockquote>
      <p>#{message.body.html_safe}</p>
      <cite>-- #{message.sender.character_name}</cite>
    </blockquote>
    <p>Please visit <a style='color:#cccccc; text-decoration:underline;' href='#{EMAIL_HOME_URL}/#/u/mailbox/'>#{EMAIL_HOME_URL}/#/u/mailbox/</a> to reply.</p>"])
	end

	def reply_message_email(message,receiver_id)
		receiver = User.find(receiver_id)
		standard_email(receiver, "[Myth Chronciles] Reply message received",message.subject,["<p>
	      You have received a new reply:
	    </p>
	    <blockquote>
	      <p>#{message.body.html_safe}</p>
	      <cite>-- #{message.sender.character_name}</cite>
	    </blockquote>
	    <p>Please visit <a style='color:#cccccc; text-decoration:underline;' href='#{EMAIL_HOME_URL}/#/u/mailbox/'>#{EMAIL_HOME_URL}/#/u/mailbox/</a> to respond.</p>"])
	end

	def topic_reply(post_id, user_id, topic_path, unsub_path)
		post = Forem::Post.find(post_id)
        topic = post.topic
        user = User.find(user_id)
		standard_email(user, "[Myth Chronciles] A topic you have subscribed to has received a reply.",topic.subject,["<p>
      A topic you have subscribed to has received a reply:
    </p>
    <blockquote>
      <p>#{post.text.html_safe}</p>
      <cite>-- #{post.forem_user.name}</cite>
    </blockquote>
    <p>Please visit <a style='color:#cccccc; text-decoration:underline;' href='#{EMAIL_HOME_URL}/#{topic_path}/'>#{EMAIL_HOME_URL}/#{topic_path}</a> to reply.</p>",
    "<p>To unsubscribe from this topic, use the following link:<br>
    <a style='color:#cccccc; text-decoration:underline;' href='#{EMAIL_HOME_URL}/#{unsub_path}/'>#{EMAIL_HOME_URL}/#{unsub_path}</a></p>"])
	end

	def standard_email(user, subject, header, sections_html, sections_text=sections_html)
		mandrill_mail(
			template: 'mythchronicles',
			subject: subject,
			to: [user_to(user)],
			vars: global_vars,
			important: true,
			inline_css: true,
			recipient_vars: [user_vars(user, header, sections_html, sections_text)]
		)
	end

	def global_vars
		{
			'home_path' => EMAIL_HOME_URL,
			'images_path' => "https://s3-eu-west-1.amazonaws.com/mythchronicles/emails",
			'play_path' => '#/sign_in',
			'help_path' => '/docs',
			'forum_path' => '/forums'
		}
	end

	def user_vars(user, header, sections_html, sections_text=sections_html)
		vars = {
			user.email =>
			{
				'name' => user.name,
				'header' => header,
				'sections_html' => sections_html,
				'sections_text' => sections_text
			}
		}
		vars
	end

	def user_to(user)
		{email: user.email, name: user.name }
	end
end