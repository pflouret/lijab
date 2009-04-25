
class Jabber::Presence
   PRETTY = Hash.new(["", []]).update(
      { :available => ["available", [:green, :bold]],
        :away => ["away", [:magenta]],
        :chat => ["chatty", [:green]],
        :dnd => ["busy", [:red, :bold]],
        :xa => ["not available", [:red]],
        :offline => ["offline", [:blue]]
      })

   def pretty_show
      case type()
      when nil
         show() || :available
      when :unavailable
         :offline
      end
   end

   def pretty(colorize=false)
      sh = pretty_show()

      s, colors = PRETTY[sh]
      s = s.colored(*colors) if colorize
      message = status() && !status().empty? ? " [#{status()}]" : ""
      "#{s}#{message}"
   end
end

module Lijab
module Contacts

   class Contact
      attr_accessor :simple_name, :history
      attr_writer :color

      COLORS = [:red, :blue, :yellow, :green, :magenta, :cyan].shuffle!

      @@cur_color = 0

      def initialize(simple_name, roster_item)
         @simple_name = simple_name
         @roster_item = roster_item
         @resource_jid = @roster_item.jid
         @history = HistoryHandler::get(jid())
      end

      def presence(jid=nil)
         if jid
            p = @roster_item.presences.select { |p| p.jid == jid }.first
         else
            p = @roster_item.presences.inject(nil) do |max, presence|
               !max.nil? && max.priority.to_i > presence.priority.to_i ? max : presence
            end
         end
         p || Jabber::Presence.new.set_type(:unavailable)
      end

      def handle_message(msg)
         @thread = msg.thread

         @resource_jid = msg.from

         if msg.body && !msg.body.empty?
            Out::message(@simple_name, msg.body, color())
            @history.log(msg.body, :from)
         end

         if msg.chat_state
            s = ""
            case msg.chat_state
            when :composing
               s = "is typing"
            when :active
               Out::clear_infoline
            when :gone
               s = "went away"
            when :paused
               s = "paused typing"
            end
            Out::infoline("* #{@simple_name} #{s}".red) unless s.empty?
         end
      end

      def send_message(msg)
         if msg.kind_of?(Jabber::Message)
            msg.thread = @thread unless msg.thread
            message = msg
         elsif msg.kind_of?(String) && !msg.empty?
            # TODO: send to specific jid when applicable
            # TODO: send chat_state only in the first message
            Out::outgoing(@simple_name, msg, color())
            message = Jabber::Message.new(@resource_jid, msg).set_type(:chat) \
                                                             .set_chat_state(:active) \
                                                             .set_thread(@thread)

            @chat_state_timer.kill if @chat_state_timer && @chat_state_timer.alive?
         end

         message = HooksHandler::handle_pre_send_message(self, message)
         return unless message

         Main.client.send(message)

         HooksHandler::handle_post_send_message(self, message)

         @history.log(message.body, :to)
         @chat_state = :active
      end

      def send_chat_state(state)
         return if state == @chat_state
         msg = Jabber::Message.new(jid(), nil).set_type(:chat).set_chat_state(state)
         Main.client.send(msg)
         @chat_state = state
      end

      def typed_stuff
         send_chat_state(:composing)

         @chat_state_timer.kill if @chat_state_timer && @chat_state_timer.alive?
         @chat_state_timer = Thread.new do
            sleep(3); return if !Main.connected
            send_chat_state(:paused)
            sleep(10); return if !Main.connected
            send_chat_state(:active)
         end
      end

      def presence_changed(old_p, new_p)
         @resource_jid = @roster_item.jid if old_p && old_p.from == @resource_jid
      end

      def jid
         @roster_item.jid
      end

      def online?
         @roster_item.online?
      end

      def color
         @color = COLORS[(@@cur_color = (@@cur_color + 1) % COLORS.length)] unless @color
         @color
      end

      def to_s;
         @simple_name
      end
   end

   class Contacts < Hash
      attr_reader :roster

      def initialize(roster)
         super()
         @roster = roster

         # why does everything always has to be so hackish?
         self_ri = Jabber::Roster::Helper::RosterItem.new(Main.client)
         self_ri.jid = Config.jid.strip
         @roster.items[self_ri.jid] = self_ri

         @roster.add_presence_callback(&method(:handle_presence))
         @roster.wait_for_roster

         @short = {}

         @roster.items.each do |jid, item|
            self[jid] = Contact.new(jid.node, item)
            if @short.key?(jid.node)
               self[@short[jid.node].jid].simple_name = jid.strip.to_s
               @short[@short[jid.node].jid.strip.to_s] = @short.delete(jid.node)
               @short[jid.strip.to_s] = self[jid]
            else
               @short[jid.node] = self[jid]
            end
         end
      end

      def [](k)
         return @short[k] if @short.key?(k)

         k = Jabber::JID.new(k) unless k.is_a?(Jabber::JID)

         super(k) || super(k.strip)
      end

      def key?(k)
         return true if @short.key?(k)

         k = Jabber::JID.new(k) unless k.is_a?(Jabber::JID)

         super(k) || super(k.strip)
      end

      def completer(line, end_with_colon=true)
         matches = @short.keys.select { |k| k.match(/^#{Regexp.escape(line)}/) }
         end_with_colon && matches.length == 1 ? "#{matches.first}:" : matches
      end

      def handle_presence(roster_item, old_p, new_p)
         contact = self[roster_item.jid]
         type = new_p.type
         if type == nil || type == :unavailable && !contact.online?
            Out::presence(new_p.from.to_s, new_p)
         end
         contact.presence_changed(old_p, new_p)
         # TODO: handle subscriptions
      end
   end
end
end
