
module Lijab

module HooksHandler
   module_function

   def init
      @on_connect = []
      @on_disconnect = []
      @on_incoming_message = []
      @on_presence = []
      @on_pre_send_message = []
      @on_post_send_message = []

      Dir[File.join(Config.dirs[:hooks], '**', '*.rb')].each { |f| load f }

      Main.client.add_message_callback(&method(:handle_message))
      Main.contacts.roster.add_presence_callback(&method(:handle_presence))
   end

   def handle_message(msg)
      return unless msg.body && !msg.body.empty?

      @on_incoming_message.each do |b|
         b.call(Main.contacts[msg.from.strip], msg.body)
      end
   end

   def handle_presence(roster_item, old_p, new_p)
      @on_presence.each do |b|
         b.call(Main.contacts[roster_item.jid.strip], old_p, new_p)
      end
   end

   def handle_pre_send_message(contact, msg)
      return msg if @on_pre_send_message.empty? || !msg.body || msg.body.empty?

      @on_pre_send_message.inject(msg) do |ret_msg, block|
         args = [contact, ret_msg.body]
         args.push(msg) if block.arity == 3

         m = block.call(*args)
         break if !m 

         if m.is_a?(Jabber::Message)
            m
         else
            ret_msg.body = m.to_s
            ret_msg
         end
      end
   end

   def handle_post_send_message(contact, msg)
      return if !msg.body || msg.body.empty?

      @on_post_send_message.each do |block|
         args = [contact, msg.body]
         args.push(msg) if block.arity == 3
         block.call(*args)
      end
   end

   def handle_connect
      @on_connect.each { |b| b.call }
   end

   def handle_disconnect
      @on_disconnect.each { |b| b.call }
   end

   attr_reader :on_connect, :on_disconnect, :on_incoming_message, :on_presence,
      :on_pre_send_message, :on_post_send_message
   module_function :on_connect, :on_disconnect, :on_incoming_message,:on_presence,
      :on_pre_send_message, :on_post_send_message
end

module Hooks
   module_function

   def on_incoming_message(&block)
      HooksHandler::on_incoming_message.push(block)
   end

   def on_presence(&block)
      HooksHandler::on_presence.push(block)
   end

   def on_pre_send_message(&block)
      HooksHandler::on_pre_send_message.push(block)
   end

   def on_post_send_message(&block)
      HooksHandler::on_post_send_message.push(block)
   end

   def on_connect(&block)
      HooksHandler::on_connect.push(block)
   end

   def on_disconnect(&block)
      HooksHandler::on_disconnect.push(block)
   end
end

end
