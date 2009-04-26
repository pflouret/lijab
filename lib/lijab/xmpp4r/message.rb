require 'xmpp4r'

unless Jabber::Message.method_defined?(:chat_state)
   class Jabber::Message
      CHAT_STATES = %w(active composing gone inactive paused).freeze

      # Returns the current chat state, or nil if no chat state is set
      def each_elements(*els, &block)
         els.inject([ ]) do |res, e|
            res + each_element(e, &block)
         end
      end

      def chat_state
         each_elements(*CHAT_STATES) { |el| return el.name.to_sym }
         return nil
      end

      ##
      # Sets the chat state :active, :composing, :gone, :inactive, :paused
      def chat_state=(s)
         s = s.to_s
         raise InvalidChatState, 
            "Chat state must be one of #{CHAT_STATES.join(', ')}" unless CHAT_STATES.include?(s)
         CHAT_STATES.each { |state| delete_elements(state) }
         add_element(REXML::Element.new(s).add_namespace('http://jabber.org/protocol/chatstates'))
      end

      CHAT_STATES.each do |state|
         define_method("#{state}?") do
            chat_state == state.to_sym
         end
      end
   end
end

class Jabber::Message
   ##
   # Sets the message's chat state
   def set_chat_state(s)
      self.chat_state = s
      self
   end
end

