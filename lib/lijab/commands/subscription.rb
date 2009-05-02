
module Lijab
module Commands
   Command.define :add do
      usage "/add <user@server>"
      description "Add a user to your roster."

      def run(args)
         Main.contacts.add(args)
         Out::put("subscription request sent to #{args}")
      end
   end

   Command.define :remove do
      usage "/remove <user@server>"
      description "Remove a user from your roster."
      
      def run(args)
         unless Main.contacts.remove(args)
            raise CommandError, "no contact found for #{args}"
         end
      end

      class << self
         include ContactCompleterMixin
      end
   end

   # TODO: <user@server | all>
   Command.define :requests do
      usage "/requests [accept|accept_and_add|decline <user@server>]"
      description "Accept/decline a user's request to see your status.\n" \
                  "Print pending requests if no argument given." \

      ACTIONS = ["accept", "accept_and_add", "decline"]

      def run(args)
         action, addr = args.split(nil, 2).strip

         if action
            unless ACTIONS.include?(action)
               raise CommandError, "action must be accept, accept_and_add or decline"
            end
            raise CommandError, "need the user's address" unless addr and !addr.empty?

            if ["accept", "accept_and_add"].include?(action)
               success = Main.contacts.process_request(addr, :allow)
               Main.contacts.add(addr) if success && action == "accept_and_add"
            else
               success = Main.contacts.process_request(addr, :decline)
            end

            raise CommandError, "no pending request from #{addr}" unless success
         else
            if Main.contacts.has_subscription_requests?
               Out::put("pending requests from:")
               Out::put(Main.contacts.subscription_requests.join("\n"))
            else
               Out::put("no pending requests")
            end
         end
      end

      def completer(line)
         _, action, addr = line.split(nil, 3)

         if !addr
            ACTIONS.grep(/^#{Regexp.escape(action)}/)
         elsif addr && ACTIONS.include?(action)
            Main.contacts.subscription_requests.grep(/^#{Regexp.escape(addr)}/).map do |c|
               "#{action} #{c}"
            end
         end
      end
   end

end
end
