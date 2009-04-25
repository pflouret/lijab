require 'readline'
require 'readline/extra'

module Lijab

module InputHandler
   module_function

   @last_to = ""

   def init
      Readline::completer_word_break_characters = ""
      Readline::completion_proc = method(:completer).to_proc
      Readline::pre_input_proc = lambda do
         print "#{ANSI.cleartoeol}" ; STDOUT.flush
         unless @last_to.empty?
            Readline::insert_text("#{@last_to}: ")
            Readline::redisplay
         end
      end
      read_typed_history()

      init_char_input_stuff()

      @input_thread = Thread.new { read_input() }
   end

   def init_char_input_stuff
      # i'm surprised this doesn't make typing fucking unbearable

      @on_char_input_blocks = []

      @on_char_input_blocks << lambda do |c|
         to, msg = Readline::line_buffer.split(":", 2).strip
         if to && msg && Main.contacts.key?(to)
            Main.contacts[to].typed_stuff
         end
         c
      end

      Readline::char_input_proc = lambda do |c|
         ret = c
         @on_char_input_blocks.each do |block|
            ret = block.call(c)
            break if ret != c
         end
         ret
      end
   end

   def on_char_input(&block)
      @on_char_input_blocks << block
   end

   #def composing_watcher
   #   timer = nil
   #   loop do
   #      sleep(1)

   #      buf = Readline::line_buffer
   #      next unless buf != @last_line

   #      @last_line = buf
   #      to, msg = buf.split(":", 2).strip

   #      next unless to && msg && Main.contacts.key?(to)
   #   end
   #end

   def read_input
      loop do
         Out::make_infoline

         t = Readline::readline(Out::PROMPT, true)

         if !t
            puts ; next
         elsif t =~ /^\s*$/
            Readline::HISTORY.pop
         else
            Readline::HISTORY.pop if Readline::HISTORY.to_a[-2] == t
            process_input(t)
         end
      end
   end

   def process_input(text)
      return if text.empty?

      if !Main.connected
         # FIXME: brute force ftw!
         Out::error("not connected :-(", false)
         return
      end

      if text[0] == ?/
         Commands::run(*text[1..-1].split(" ", 2))
         @last_to = ""
      else
         to, msg = text.split(":", 2).strip
         return unless to && msg && !msg.empty? && Main.contacts.key?(to)

         @last_to = to
         Main.contacts[to].send_message(msg)
      end
   end

   def completer(line)
      return if !Main.connected
      if line[0] == ?/
         Commands::completer(line)
      else
         Main.contacts.completer(line)
      end
   end

   def save_typed_history
      File.open(Config.files[:typed], 'w') do |f|
         f.puts(Readline::HISTORY.to_a[-300..-1] || Readline::HISTORY.to_a)
      end
   end

   def read_typed_history
      path = Config.files[:typed]
      File.read(path).each { |l| Readline::HISTORY.push(l.chomp) } if File.file?(path)
   end
end

end

