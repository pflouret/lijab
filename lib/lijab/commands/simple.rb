
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
         _, contact = line.split(nil, 2)
         Main.contacts.completer(contact, false)
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
         _, contact = line.split(nil, 2)
         Main.contacts.completer(contact, false)
      end
   end

   Command.define :quit do
      usage "/quit"
      description "Quit lijab"

      def run(args)
         Main.quit
      end
   end

   # TODO: make a generic option changer?
   Command.define :show_status_changes do
      usage "/show_status_changes yes|no"
      description "Enable/disable printing the contacts' status changes. Can get quite spammish."

      def run(args)
         Config.opts[:show_status_changes] = args.split[0].strip == 'yes'
      end
   end

end
end

