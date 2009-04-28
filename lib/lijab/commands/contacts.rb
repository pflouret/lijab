
module Lijab
module Commands

   module ContactsCommandMixin
      SORTBY = ["status", "alpha"]

      def completer(line)
         sortby = line.split[1] || ""
         if SORTBY.grep(sortby).empty?
            SORTBY.grep(/^#{Regexp.escape(sortby)}/)
         end
      end

      def group_contacts(contacts)
         grouped = {}
         contacts.each do |jid,contact|
            groups = contact.roster_item.groups
            if groups.empty?
               (grouped["<no group>"] ||= []) << contact
            else
               groups.each { |g| (grouped[g] ||= []) << contact }
            end
         end

         grouped = grouped.sort_by { |g,c| g }
      end

      def print_contacts(sort_by_status=false, online_only=false)
         if sort_by_status
            contacts = Main.contacts.sort { |a, b| -(a[1].presence <=> b[1].presence) }
         else
            contacts = Main.contacts.sort_by { |j,c| c.simple_name }
         end

         if Config.opts[:show_groups_in_contact_list]
            grouped = group_contacts(contacts)
         else
            grouped = {nil => contacts.map { |j,c| c }}
         end

         s = []
         grouped.each do |group, contactz|
            if online_only
               next unless contactz.any? { |c| c.online? }
            end

            s << " #{group} ".on_blue if group
            contactz.each do |contact|
               unless online_only && !contact.online?
                  main = contact.presence
                  s << "* #{contact.simple_name} #{main.pretty(true)} " \
                     "(#{main.priority || 0}) [#{main.from || contact.jid}]"

                  if online_only && contact.roster_item.presences.length > 1
                     contact.roster_item.presences.each do |p|
                        if p.from != main.from
                           s << "    #{p.from} #{p.pretty(true)} (#{p.priority || 0})"
                        end
                     end
                  end
               end
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
