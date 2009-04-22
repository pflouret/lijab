require 'time'

class File
   include File::Tail
end

module Lijab

module HistoryHandler
   class History
      MEMORY_LOG_LENGTH = 50

      def initialize(path, target=nil, log_to_session=false)
         @path, @target, @log_to_session = path, target, log_to_session
         @m = []
      end

      def init_logfile
         @w = File.open(@path, 'a')
         @r = File.open(@path, 'r')
         @r.return_if_eof = true
      end

      def log(msg, direction, target=nil)
         init_logfile() unless @w

         time = Time.now.utc
         target ||= @target
         arrow = direction == :from ? "<-" : "->"
         quoted = [msg].pack("M").gsub(/=?\n/) { |m| m[0] == ?= ? "" : "=0A" }

         @w.puts("#{time.iso8601} #{target} #{arrow} #{quoted}")
         @w.flush

         @m.push({:time=>time.localtime, :target=>target, :direction=>direction, :msg=>msg})
         @m.shift if @m.length > MEMORY_LOG_LENGTH

         @m = []

         HistoryHandler::log(msg, direction, target) if @log_to_session

         self
      end

      def last(n)
         return [] if n <= 0

         init_logfile() unless @r

         if n <= @m.length
            @m[-n..-1]
         else
            ret = []
            @r.seek(0, File::SEEK_END)
            @r.backward(n)
            @r.tail(n-@m.length) do |l|
               time, target, direction, msg = l.split(" ", 4)
               ret << {:time => Time.parse(time).localtime,
                       :target => target,
                       :direction => direction == "<-" ? :from : :to,
                       :msg => msg.unpack("M").first.strip}
            end
            ret += @m
            if @m.length < MEMORY_LOG_LENGTH
               @m = (ret[0...n-@m.length] + @m)
               @m = @m[-MEMORY_LOG_LENGTH..-1] if @m.length > MEMORY_LOG_LENGTH
            end
            ret
         end
      end
   end

   module_function

   @histories = {}

   def get(jid)
      name = jid.strip.to_s
      @histories[name] ||= History.new(File.join(Config.account_logdir, "#{name}.log"), name, true)
   end

   def log(msg, direction, target)
      init_session_log() unless @session
      @session.log(msg, direction, target)
   end

   def last(n)
      init_session_log() unless @session
      @session.last(n)
   end

   def init_session_log
      path = File.join(Config.account_logdir, "session.log")
      @session = History.new(path)
   end
end

end

