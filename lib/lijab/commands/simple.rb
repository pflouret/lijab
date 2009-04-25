
module Lijab

module Commands

   Command.define :help do
      usage "/help [<command>]"
      description "Get some help."

      def run(args)
         if args.empty?
            puts %Q{
               Help goes here you lazy ass.
               "/help help" is a good place to start
            }.gsub!(/^\s*/, '')
         else
            cmd = Commands::get(args)
            if cmd
               s = "usage: #{cmd.usage}\n\n" if cmd.usage
               s = "#{s}#{cmd.description}"
               # FIXME: make Out::normal or something, could use Out::inline(s, false)
               # but it feels wrong
               puts s
            else
               raise CommandError, %(No such command "#{args}")
            end
         end
      end

      def completer(line)
         help_cmd, rest = line.split(" ", 2)
         rest = "/#{rest}"

         Commands::completer(rest).map { |c| c[1..-1] } if rest.split(" ", 2).length == 1
      end
   end

   Command.define :history do
      usage "/history [<contact>] [<limit>]"
      description "Show the message history with a <contact>, or all the contacts."

      def run(args)
         contact, limit = args.split(" ", 2).strip
         limit ||= 10

         if contact
            return puts %(No contact named "#{contact}) unless Main.contacts.key?(contact)
            m = Main.contacts[contact].history.last(limit.to_i)
         else
            m = HistoryHandler::last(limit.to_i)
         end
         Out::history(*m)
      end

      def completer(line)
         contact = line.split[1] || ""
         Main.contacts.completer(contact, false) if contact.empty? || !Main.contacts.key?(contact)
      end
   end

   Command.define :multiline do
      usage "/multiline <contact> [<first_line>]"
      description "Enter multiline mode, meaning, send a multiline message to a contact.\n" \
                  "Ctrl-d in an empty line exits multiline mode and sends the message."

      def run(args)
         contact, first_line = args.split(" ", 2).strip
         first_line = "#{contact}: #{first_line}"
         InputHandler::multiline(true, first_line)
      end

      def completer(line)
         contact = line.split[1] || ""
         Main.contacts.completer(contact, false) if contact.empty? || !Main.contacts.key?(contact)
      end
   end

   Command.define :quit do
      usage "/quit"
      description "Quit lijab"

      def run(args)
         Main.quit
      end
   end

   Command.define :priority do
      usage "/priority [<priority>]"
      description "Change the jabber priority. Number must be between -127 and 127.\n" \
                  "Show current priority if no argument is given."

      def run(args)
         if args.strip.empty?
            return puts "Current priority is #{Main.presence.priority}"
         end

         begin
            p = Integer(args)
         rescue ArgumentError
            raise Commands::CommandError, %{"#{args}" is not a valid integer}
         end

         raise Commands::CommandError, "priority must be between -127 and 127" unless (-127..127).include?(p)

         Main.set_priority(p)
      end
   end

   Command.define :status do
      usage "/status [available|away|chat|xa|dnd|invisible] [<message>]"
      description "Set your status.\n" \
                  "If no status is given, keep the current and set the status message.\n" \
                  "If no message is given, keep the current status and clear the message.\n" \
                  "If no arguments are given, print the current status."

      STATUSES = ["available", "away", "chat", "xa", "dnd", "invisible"]

      def run(args)
         status, message = args.split(" ", 2).strip

         unless status
            p = Main.presence
            puts "#{Config.jid} (#{p.priority || 0}) #{p.pretty(true)}"
            return
         end

         unless STATUSES.include?(status)
            message = "#{status} #{message}".strip
            status = nil
         end

         Main.set_status(status && status.to_sym, message)
      end

      def completer(line)
         status = line.split[1] || ""
         if STATUSES.grep(status).empty?
            STATUSES.grep(/^#{Regexp.escape(status)}/)
         end
      end
   end

   module ContactsCommandMixin
      SORTBY = ["status", "alpha"]

      def completer(line)
         sortby = line.split[1] || ""
         if SORTBY.grep(sortby).empty?
            SORTBY.grep(/^#{Regexp.escape(sortby)}/)
         end
      end

      def print_contacts(sort_by_status=false, online_only=false)
         if sort_by_status
            contacts = Main.contacts.sort { |a, b| -(a[1].presence <=> b[1].presence) }
         else
            contacts = Main.contacts.sort_by { |j,c| c.simple_name }
         end

         s = []
         contacts.each do |jid,contact|
            unless online_only && !contact.online?
               s << "* #{contact.simple_name} #{contact.presence.pretty(true)}"
            end
         end

         Out::inline(s.join("\n"), false) unless s.empty?
      end

   end

   Command.define :contacts do
      usage "/contacts [status|alpha]"
      description "Show a list of all contacts. Sorted alphabetically or by status."

      SORTBY = ["status", "alpha"]

      def run(args)
         print_contacts(args.split[0] == "status")
      end

      class << self
         include ContactsCommandMixin
      end
   end

   Command.define :who do
      usage "/who [status|alpha]"
      description "Show a list of online contacts. Sorted alphabetically or by status."

      def run(args)
         print_contacts(args.split[0] == "status", true)
      end

      class << self
         include ContactsCommandMixin
      end
   end
end

end

