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

   def inline(s, redisplay_line=true)
      Out::clear_infoline if redisplay_line

      print %{#{ANSI.clearline}#{s}\n}

      if redisplay_line
         make_infoline()
         print "#{InputHandler::prompt}#{Readline::line_buffer}"
      end
      STDOUT.flush
   end

   def notice_if_day_changed(redisplay_line)
      t = Time.now
      if @time.day != t.day
         print ANSIMove.up(1) unless redisplay_line
         ft = @time.strftime('%Y-%M-%d')
         Out::inline("** day changed -- #{ft} -> #{Date.today}".green)
         puts unless redisplay_line
         @time = t
      end
   end

   # TODO: ugh, clean this shit up
   def conversation(prefix, text, colors=[], print_inline=true, move_up=false)
         n_lines = text.count($/) + 1
         lines = text.lines.to_a
         return unless lines[0]

         print ANSIMove.up(n_lines) if print_inline && move_up

         inline(prefix.colored(*colors) + "#{lines.shift.chomp}", print_inline)

         prefix = " " * prefix.length

         lines.each do |l|
            inline(prefix + "#{l.chomp}", print_inline)
         end
   end

   def message(from, text, color=:clear, print_inline=true, time=:now)
      @monitor.synchronize do
         notice_if_day_changed(true)
         time = ftime(time) unless time.kind_of?(String)
         print "\a" if Config.opts[:terminal_bell_on_message]
         conversation("#{time}#{from} -> ", text, [color, :bold], print_inline)
      end
   end

   def outgoing(to, text, color=:clear, print_inline=true, time=:now)
      @monitor.synchronize do
         notice_if_day_changed(false)
         time = ftime(time) unless time.kind_of?(String)
         conversation("#{time}#{to} <- ", text, [color], print_inline, true)
      end
   end

   def presence(from, presence, color=:clear, time=:now)
      @monitor.synchronize do
         notice_if_day_changed(true)
         time = ftime(time) unless time.kind_of?(String)
         s = "** #{time}#{from} (#{presence.priority || 0}) is now ".send(color)
         s += presence.pretty(true)
         inline(s)
      end
   end

   def subscription(from, type, colors=[], time=:now)
      @monitor.synchronize do
         notice_if_day_changed(true)
         time = ftime(time) unless time.kind_of?(String)
         case type
         when :subscribe
            s = "** #{time}subscription request from #{from} received\n" \
                "** See '/help requests' to see how to handle requests."
         when :subscribed
            s = "** #{time}#{from} has subscribed to you"
         when :unsubscribed
            s = "** #{time}#{from} has unsubscribed from you"
         end
         inline(s)
      end
   end

   def history(*log_entries)
      log_entries.each do |e|
         contact = Main.contacts[Jabber::JID.new(e[:target])]
         target_s = contact ? contact.simple_name : e[:target]
         m = method(e[:direction] == :from ? :message : :outgoing)
         m.call(target_s,
                e[:msg],
                contact ? contact.color : :clear,
                false,
                ftime(e[:time].localtime, :history_datetime_format))
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

   def ftime(time=nil, format=:datetime_format)
      return "" unless time
      time = Time.now if time == :now

      "#{time.strftime(Config.opts[format])} "
   end
end

end
