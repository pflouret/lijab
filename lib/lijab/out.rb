require 'lijab/term/ansi'
require 'readline'
require 'readlinep'
require 'monitor'

include Term

module Lijab

module Out
   PROMPT = "> "

   module_function
   @monitor = Monitor.new

   def inline(s, redisplay_line=true, newline=true)
      Out::clear_infoline if redisplay_line

      print %{#{ANSI.clearline}#{s}#{"\n" if newline}}

      if redisplay_line
         make_infoline()
         print "#{PROMPT}#{Readline::line_buffer}"
      end
      STDOUT.flush
   end

   def message(from, text, color=:clear, print_inline=true)
      @monitor.synchronize do
         inline("#{from} -> ".send(color).bold + "#{text}\a", print_inline)
      end
   end

   def presence(from, presence, color=:clear)
      @monitor.synchronize do
         inline("** #{from} is now ".send(color) + presence.pretty(true))
      end
   end

   def outgoing(to, text, color=:clear, print_inline=true)
      @monitor.synchronize do
         print "#{ANSIMove.up(1)}" if print_inline
         inline("#{to} <- ".send(color) + "#{text}", print_inline)
      end
   end

   def history(*log_entries)
      log_entries.each do |e|
         contact = Main.contacts[Jabber::JID.new(e[:target])]
         target_s = contact ? contact.simple_name : e[:target]
         m = method(e[:direction] == :from ? :message : :outgoing)
         m.call(target_s, e[:msg], contact ? contact.color : :clear, false)
      end
   end

   def error(s, print_inline=true)
      s = "#{ANSI.cleartoeol}error: #{s}".red.bold
      print_inline ? inline(s) : puts(s)
   end

   def infoline(s)
      @monitor.synchronize do
         print "#{ANSI.savepos}#{ANSIMove.down(1)}#{ANSI.clearline}"
         print s
         print "#{ANSI.restorepos}"
         STDOUT.flush
      end
   end

   def clear_infoline
      @monitor.synchronize do
         print "#{ANSI.savepos}\n#{ANSI.clearline}#{ANSI.restorepos}"
         STDOUT.flush
      end
   end

   def make_infoline
      @monitor.synchronize do
         print "\n\r#{ANSI.cleartoeol}#{ANSIMove.up(1)}"
         STDOUT.flush
      end
   end
end

end
