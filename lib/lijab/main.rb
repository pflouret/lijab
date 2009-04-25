require 'file/tail'
require 'monitor'
require 'optparse'
require 'term/ansicolor'
require 'xmpp4r'
require 'xmpp4r/roster'

require 'lijab/commands'
require 'lijab/config'
require 'lijab/contacts'
require 'lijab/history'
require 'lijab/hooks'
require 'lijab/input'
require 'lijab/out'
require 'lijab/version'
require 'lijab/xmpp4r/message'

include Term


class String
   include ANSIColor

   def colored(*colors)
      s = self
      colors.each { |c| s = s.send(c) }
      s
   end
end

Thread.abort_on_exception = true

module Lijab

module Main
   module_function

   @monitor = Monitor.new

   def run!
      args = parse_args()
      Jabber::debug = args[:debug]

      Config::init(args)
      @connected = false

      begin
         setup_client()
      rescue SystemCallError
         Out::error("couldn't connect")
         reconnect()
      end

      Commands::init
      InputHandler::init
   end

   def setup_after_connect
      HooksHandler::init
   end

   def setup_client
      return unless @monitor.try_enter
      begin
         @client = Jabber::Client.new(Config.jid)

         @client.on_exception do |e,stream,from|
            @connected = false

            case from
            when :disconnected
               Out::error("disconnected")
               HooksHandler::handle_disconnect
               reconnect()
            else
               # death before lost messages!
               raise e || "exception raised from #{from}"
            end
         end

         @client.add_message_callback do |msg|
            Main.contacts[msg.from].handle_message(msg) if Main.contacts.key?(msg.from)
         end

         Out::inline("connecting...", false)

         @client.connect(Config.account[:server], Config.account[:port])

         loop do
            begin
               if !Config.account[:password]
                  print "#{Config.account[:name]} account password: "
                  system("stty -echo") # FIXME
                  Config.account[:password] = gets.chomp
                  system("stty echo")
                  puts
               end

               @client.auth(Config.account[:password])
               break
            rescue Jabber::ClientAuthenticationFailure
               Out::error("couldn't authenticate: wrong password?", false)
               Config.account[:password] = nil
            end
         end

         @contacts = Contacts::Contacts.new(Jabber::Roster::Helper.new(@client))
         @client.send(Jabber::Presence.new.set_type(:available).set_priority(51))
         @connected = true

         setup_after_connect()
         HooksHandler::handle_connect

         Out::inline("connected!".green, true)
      ensure
         @monitor.exit
      end
   end

   def reconnect
      do_sleep = 1
      loop do
         do_sleep.downto(1) do |i|
            Out::infoline("trying reconnect in #{i*5} seconds...")
            sleep(5)
         end
         do_sleep = [do_sleep*2, 10].min

         begin
            setup_client()
            Out::clear_infoline
            break
         rescue SystemCallError
         end
      end
   end

   def set_status(status, msg=nil)
      type = status == :invisible ? :unavailable : nil
      status = nil if [:available, :invisible].include?(status)
      @status = status

      p = Jabber::Presence.new.set_type(type) \
                              .set_show(status) \
                              .set_status(msg) \
                              .set_priority(51)
      @client.send(p)
   end

   def clear_status_message
      set_status(@status)
   end

   def parse_args
      options = {:debug => false}
      begin
         op = OptionParser.new do |opts|
            opts.banner = "usage: lijab [-a ACCOUNTNAME] [-d BASEDIR] [-D]\n\n"
            opts.on("-D", "--[no-]debug",
                    "show xmpp debug information") { |v| options[:debug] = v }
            opts.on("-d", "--basedir BASEDIR",
                    "configs base directory") { |v| options[:basedir] = v }
            opts.on("-a", "--account ACCOUNTNAME",
                    "the name of the account to connect to") { |v| options[:account] = v }
            opts.on("-V", "--version", "print version information") do |v|
               puts "lijab #{Lijab::VERSION}"
               exit(0)
            end
         end
         op.parse!
      rescue OptionParser::MissingArgument
         puts "lijab: error: #{$!}\n\n#{op}"
         exit 1
      end
      options
   end

   def quit
      begin
         @client.close if @connected
      rescue
      end
      InputHandler::save_typed_history
      puts "\nexiting..."
      exit 0
   end

   attr_reader :contacts, :client, :connected
   module_function :contacts, :client, :connected
end
end

