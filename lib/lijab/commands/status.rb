
module Lijab
module Commands

   Command.define :priority do
      usage "/priority [<priority>]"
      description "Change the jabber priority. Number must be between -127 and 127.\n" \
                  "Show current priority if no argument is given."

      def run(args)
         if args.strip.empty?
            Out::put("Current priority is #{Main.presence.priority}")
            return
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
            Out::put("#{Config.jid} (#{p.priority || 0}) #{p.pretty(true)}")
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

end
end
