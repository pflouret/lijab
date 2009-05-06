require 'date'
require 'file/tail'
require 'monitor'
require 'optparse'
require 'term/ansicolor'
require 'xmpp4r'
require 'xmpp4r/roster'
require 'yaml'

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

class Array
   def strip
      self.map { |s| s.strip }
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
      read_saved_session()

      @connected = false

      print ANSI.title("lijab -- #{Config.jid.strip}") ; STDOUT.flush

      begin
         setup_client()
      rescue SystemCallError, SocketError
         Out::error("couldn't connect", false)
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

         @client.add_message_callback do |msg|
            if Main.contacts.key?(msg.from)
               Main.contacts[msg.from].handle_message(msg)
            else
               Main.contacts.handle_non_contact_message(msg)
            end
         end

         @client.use_ssl = Config.account[:use_ssl]

         Out::put("connecting...".yellow, false)

         loop do
            begin
               @client.connect(Config.account[:server], Config.account[:port])

               if !Config.account[:password]
                  print "#{ANSI.clearline}#{Config.account[:name]} account password: "
                  system("stty -echo") # FIXME
                  STDIN.read_nonblock(9999999) rescue nil
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

         @client.on_exception do |e,stream,from|
            @connected = false

            case from
            when :disconnected
               Out::error("disconnected", false)
               HooksHandler::handle_disconnect
               reconnect()
            else
               # death before lost messages!
               raise e || "exception raised from #{from}"
            end
         end

         @contacts = Contacts::Contacts.new(Jabber::Roster::Helper.new(@client))
         @client.send(@presence)
         @connected = true

         setup_after_connect()
         HooksHandler::handle_connect

         Out::put("connected!".green)
      ensure
         @monitor.exit
      end
   end

   def reconnect
      do_sleep = 1
      loop do
         do_sleep.downto(1) do |i|
            Out::make_infoline
            Out::infoline("trying reconnect in #{i*5} seconds...")
            sleep(5)
         end
         do_sleep = [do_sleep*2, 10].min

         begin
            setup_client()
            Out::clear_infoline
            break
         rescue SystemCallError, SocketError
         end
      end
   end

   def set_status(status, msg=nil)
      type = status == :invisible ? :unavailable : nil
      priority = Config.opts[:status_priorities][status]
      status = nil if [:available, :invisible].include?(status)

      @presence.set_type(type).set_show(status).set_status(msg).set_priority(priority)

      @client.send(@presence)
   end

   def clear_status_message
      set_status(@status)
   end

   def set_priority(priority)
      @client.send(@presence.set_priority(priority))
   end

   def parse_args
      options = {:debug => false}
      begin
         op = OptionParser.new do |opts|
            opts.banner = "usage: lijab [-h | -V | [-a ACCOUNTNAME] [-d BASEDIR] [-D]]\n\n"
            opts.on("-D", "--[no-]debug",
                    "output xmpp debug information to stderr") { |v| options[:debug] = v }
            opts.on("-d", "--basedir BASEDIR",
                    "configs base directory") { |v| options[:basedir] = v }
            opts.on("-a", "--account ACCOUNTNAME",
                    "the name of the account to connect to") { |v| options[:account] = v }
            opts.on("-V", "--version", "print version information") do |v|
               puts "lijab #{Lijab::VERSION}"
               exit(0)
            end
         end
         begin
            op.parse!
         rescue OptionParser::ParseError => e
            puts "#{e}\n\n#{op.banner.chomp}"
            exit(1)
         end
      rescue OptionParser::MissingArgument
         puts "lijab: error: #{$!}\n\n#{op}"
         exit 1
      end
      options
   end

   def save_session
      return unless @presence

      o = {:status => {:type => @presence.type,
                       :show => @presence.show,
                       :status => @presence.status,
                       :priority => @presence.priority}}
      File.open(File.join(Config.account[:dir], "session_data.yml"), 'w') do |f|
         f.puts(YAML.dump(o))
      end
   end

   def read_saved_session
      path = File.join(Config.account[:dir], "session_data.yml")

      if File.file?(path)
         o = YAML.load_file(path)
      else
         o = {:status => {:type => :available, :priority => 51}}
      end

      @presence = Jabber::Presence.new.set_type(o[:status][:type]) \
                                      .set_show(o[:status][:show]) \
                                      .set_status(o[:status][:status]) \
                                      .set_priority(o[:status][:priority])
   end

   def quit
      begin
         @client.close if @connected
      rescue
      end
      InputHandler::save_typed_history
      Config::dump_config_file(false, true)
      save_session()
      puts "\nexiting..."
      exit 0
   end

   attr_reader :contacts, :client, :connected, :presence
   module_function :contacts, :client, :connected, :presence
end
end

