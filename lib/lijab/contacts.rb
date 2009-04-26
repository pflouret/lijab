
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
      attr_reader :roster_item

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

         if msg.body && !msg.body.empty?
            @resource_jid = msg.from
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

      def send_message(msg, jid=nil)
         if msg.kind_of?(Jabber::Message)
            msg.thread = @thread unless msg.thread
            message = msg
         elsif msg.kind_of?(String) && !msg.empty?
            # TODO: send chat_state only in the first message
            if jid
               @resource_jid = jid
            else
               jid = @resource_jid
            end
            Out::outgoing(@simple_name, msg, color())
            message = Jabber::Message.new(jid, msg).set_type(:chat) \
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
      attr_reader :roster, :subscription_requests

      def initialize(roster)
         super()
         @roster = roster

         # why does everything always has to be so hackish?
         self_ri = Jabber::Roster::Helper::RosterItem.new(Main.client)
         self_ri.jid = Config.jid.strip
         @roster.items[self_ri.jid] = self_ri

         @roster.add_presence_callback(&method(:handle_presence))
         @roster.add_subscription_callback(&method(:handle_subscription))
         @roster.add_subscription_request_callback(&method(:handle_subscription))
         @roster.wait_for_roster

         @subscription_requests = {}
         @short = {}

         @roster.items.each do |jid, item|
            add(jid, Contact.new(jid.node, item))
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

      def add(jid, contact=nil)
         if contact
            self[jid] = contact
            if @short.key?(jid.node)
               self[@short[jid.node].jid].simple_name = jid.strip.to_s
               @short[@short[jid.node].jid.strip.to_s] = @short.delete(jid.node)
               @short[jid.strip.to_s] = self[jid]
            else
               @short[jid.node] = self[jid]
            end
         else
            jid = Jabber::JID.new(jid) unless jid.is_a?(Jabber::JID)
            jid.strip!

            p = Jabber::Presence.new.set_type(:subscribe)
            p.to = jid

            Main.client.send(p)
         end
      end

      def remove(jid)
         return false unless key?(jid)

         contact = self[jid]
         contact.roster_item.remove()
         @short.delete(contact.simple_name)
         self.delete(contact.jid)

         true
      end

      def process_request(jid, action)
         jid = Jabber::JID.new(jid) unless jid.is_a?(Jabber::JID)
         jid.strip!
         if @subscription_requests.include?(jid)
            @subscription_requests.delete(jid)

            case action
            when :accept
               Main.contacts.roster.accept_subscription(jid)
            when :decline
               Main.contacts.roster.decline_subscription(jid) if exists
            end

            true
         else
            false
         end
      end

      def has_subscription_requests?
         !@subscription_requests.empty?
      end

      def subscription_requests
         @subscription_requests.keys.map { |jid| jid.to_s }
      end

      def completer(line, end_with_colon=true)
         if line.include?(?@)
            matches = @roster.items.values.collect { |ri| ri.presences }.flatten.select do |p|
               p.from.to_s =~ /^#{Regexp.escape(line)}/
            end.map { |p| p.from.to_s }
         else
            if Config.opts[:autocomplete_online_first]
               matches = @short.keys.find_all do |name|
                  @short[name].online? && name =~ /^#{Regexp.escape(line)}/
               end
            end
            if matches.empty? || !Config.opts[:autocomplete_online_first]
               matches = @short.keys.find_all { |name| name =~ /^#{Regexp.escape(line)}/ }
            end
         end
         end_with_colon && matches.length == 1 ? "#{matches.first}:" : matches
      end

      def handle_presence(roster_item, old_p, new_p)
         contact = self[new_p.from]
         if Config.opts[:show_status_changes]
            type = new_p.type
            if type == nil || type == :unavailable && (!contact || !contact.online?)
               Out::presence(new_p.from.to_s, new_p)
            end
         end
         contact.presence_changed(old_p, new_p) if contact
      end

      def handle_subscription(roster_item, presence)
         show = true
         if presence.type == :subscribe
            show = !@subscription_requests.key?(presence.from.strip)
            @subscription_requests[presence.from.strip] = presence
         elsif presence.type == :subscribed
            jid = presence.from.strip

            ri = Jabber::Roster::Helper::RosterItem.new(Main.client)
            ri.jid = jid
            @roster.items[jid] = ri

            add(jid, Contact.new(jid.node, ri))

            p = Jabber::Presence.new.set_type(:probe)
            p.to = jid
            Main.client.send(p)
         end

         Out::subscription(presence.from.to_s, presence.type) if show
      end
   end
end
end
