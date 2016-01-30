class Api::MessagesController < Api::BaseController
	include CleanPagination
	
	def recipients
		if current_user.character
			render json: Character.in_game(current_user.character.game).where(["user_id <> ?", current_user.id]).order_by_name.map{|c| {id: c.id, name: c.name}}, status: :ok
		else
			render json: [], status: :ok
		end
	end

	def show
		conversation = Mailboxer::Conversation.find(params[:id])
		unless conversation.is_participant?(current_user)
			return head :forbidden
		end
		conversation.mark_as_read(current_user)
		render json: {id: conversation.id, subject: conversation.subject, messages: conversation.messages.map{|m| {sender: {id: m.sender.id, name: m.sender.character_name}, attachment: m.attachment, body: m.body, date: m.updated_at.to_formatted_s(:short)}}}, status: :ok
	end

	def index
		conversations = nil
		if params[:mailbox].blank?
			conversations = current_user.mailbox.inbox
		else
			case params[:mailbox]
			when 'sentbox'
				conversations = current_user.mailbox.sentboxconversations
			when 'trash'
				conversations = current_user.mailbox.trash
			else
				conversations = current_user.mailbox.inbox
			end
		end
		max_per_page = params[:max_per_page] || 10
		paginate conversations.count, max_per_page.to_i do |limit, offset|
			render json: conversations.limit(limit).offset(offset).map{|c| {id: c.id, subject: c.subject, sender: {id: c.last_sender.id, name: c.last_sender.character_name}, date: c.last_message.updated_at.to_formatted_s(:short)}}, status: :ok
		end
	end

	def destroy
		conversation = Mailboxer::Conversation.find(params[:id])
		unless conversation.is_participant?(current_user)
			return head :forbidden
		end
		conversation.move_to_trash(current_user)
		head :ok
	end

	def create
		body = params[:body]
		if body.blank?
			return render json: {error: 'Invalid body'}, status: :unprocessable_entity
		end

		unless params[:conversation_id].blank?
			conversation = Mailboxer::Conversation.find(params[:conversation_id])
			unless conversation.is_participant?(current_user)
				return head :forbidden
			end
			return render json: current_user.reply_to_conversation(conversation, body)
		else
			recipient = nil
			unless params[:character_id].blank?
				character = Character.where(id: params[:character_id]).first
				unless character
					return head :not_found
				end
				recipient = character.user
			else
				recipient = User.where(id: params[:user_id]).first
				unless recipient
					return head :not_found
				end
			end

			subject = params[:subject]
			unless subject.blank?
				return render json: current_user.send_message(recipient, body, subject)
			else
				return render json: {error: 'Invalid subject'}, status: :unprocessable_entity
			end
		end
	end
end