
module Lijab
module Commands

   Command.define :help do
      usage "/help [<command> | commands]"
      description "Get some help."

      def run(args)
         if args.empty?
            puts %Q{
               When in doubt, hit <tab>.

               Some general hints:

               Run "lijab -a <name>" to connect to the account named <name>.

               Tab on an empty line will try to complete online contacts.
               If there are no online contact matches for what you typed, offline contacts will also be
               considered.

               You can tab-complete specific resources of a contact by typing the contact name
               followed by an @ character, e.g. somecontact@<tab> will complete all the available 
               resources for the contact and a message can be sent to that specific resource.

               Config/logs folder is at #{Config.basedir}

               Put your custom commands in #{Config.dirs[:commands]}
               Check out the files in <install-path>/lib/lijab/commands/ for some examples.

               Put your custom hooks in #{Config.dirs[:hooks]}

               Send mails to quuxbaz@gmail.com to complain about the lack of documentation :-)

            }.gsub!(/^ */, '')
         else
            if args == "commands"
               puts
               Commands::registered.each do |name, cmd|
                  puts %{#{cmd.usage || "/#{name}"}}.magenta
                  puts "#{cmd.description}\n\n"
               end
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
      end

      def completer(line)
         help_cmd, rest = line.split(" ", 2)
         rest ||= ""

         m = "commands" =~ /^#{Regexp.escape(rest)}/ ? ["commands"] : []

         rest = "/#{rest}"

         m += Commands::completer(rest).map { |c| c[1..-1] } if rest.split(" ", 2).length == 1
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

      class << self
         include ContactCompleterMixin
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

      class << self
         include ContactCompleterMixin
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
         if !args || args.empty?
            puts Config.opts[:show_status_changes] ? "yes" : "no"
         else
            Config.opts[:show_status_changes] = args.strip == "yes"
         end
      end
   end

end
end

