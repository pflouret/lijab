require 'lijab/input'
require 'lijab/term/ansi'
require 'monitor'
require 'readline'
require 'readline/extra'

include Term

module Lijab

module Out

   @monitor = Monitor.new
   @time = Time.now

   module_function

   def put(s="\n", redisplay_input=false)
      #clear_infoline()
      puts "#{ANSI.clearline}#{s}"
      InputHandler::redisplay_input if redisplay_input
   end

   def notice_if_day_changed(redisplay_input=true)
      t = Time.now
      if @time.day != t.day
         ft = @time.strftime('%Y-%M-%d')
         @time = t
         puts "#{ANSI.clearline}** day changed -- #{ft} -> #{Date.today}".green
      end
   end

   def format_time(time=nil, format=:datetime_format)
      return "" unless time
      time = Time.now if time == :now

      "#{time.strftime(Config.opts[format])} "
   end

   def format_message_in(from, text, colors, time)
      "#{ANSI.clearline}#{time}#{from} <- ".colored(*colors) + text
   end
   
   def format_message_out(to, text, colors, time)

      prefix = "#{time}#{to} -> "
      indent = " " * prefix.length

      lines = text.to_a
      s = []

      s << "#{ANSI.clearline}#{prefix.colored(*colors)}#{lines.shift.chomp}"
      lines.each do |l|
         s << "#{ANSI.clearline}#{indent}#{l.chomp}"
      end

      s.join("\n")
   end

   def message_in(from, text, colors=[])
      @monitor.synchronize do
         clear_infoline()
         InputHandler::delete_typed

         notice_if_day_changed()

         print "\a" if Config.opts[:terminal_bell_on_message]
         puts format_message_in(from, text, colors, format_time(:now))

         InputHandler::redisplay_input
      end
   end

   def message_out(to, text, colors=[])
      @monitor.synchronize do
         InputHandler::delete_last_typed

         notice_if_day_changed(false)

         puts format_message_out(to, text, colors, format_time(:now))
      end
   end

   def presence(from, presence, colors=[])
      @monitor.synchronize do
         clear_infoline()
         InputHandler::delete_typed

         notice_if_day_changed()

         print "#{ANSI.clearline}"
         print "** #{format_time(:now)}#{from} (#{presence.priority || 0}) is now ".colored(*colors)
         puts presence.pretty(true)

         InputHandler::redisplay_input
      end
   end

   def subscription(from, type, colors=[])
      @monitor.synchronize do
         clear_infoline()
         InputHandler::delete_typed

         notice_if_day_changed()

         time = format_time(:now)
         case type
         when :subscribe
            s = "#{time}** subscription request from #{from} received\n" \
                "#{' '*time.length}** See '/help requests' to see how to handle requests."
         when :subscribed
            s = "**#{time}#{from} has subscribed to you"
         when :unsubscribed
            s = "** #{time}#{from} has unsubscribed from you"
         end

         puts "#{ANSI.clearline}#{s}"

         InputHandler::redisplay_input
      end
   end

   def history(*log_entries)
      log_entries.each do |e|
         contact = Main.contacts[Jabber::JID.new(e[:target])]
         target_s = contact ? contact.simple_name : e[:target]
         colors = contact ? [contact.color] : []
         time = format_time(e[:time].localtime, :history_datetime_format)

         if e[:direction] == :from
            colors << :bold
            m = method(:format_message_in)
         else
            m = method(:format_message_out)
         end

         puts m.call(target_s, e[:msg], colors, time)
      end
   end

   def error(s, redisplay_input=true)
      puts "#{ANSI.cleartoeol}error: #{s}".red.bold
      InputHandler::redisplay_input if redisplay_input
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
