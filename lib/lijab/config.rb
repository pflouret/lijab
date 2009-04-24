
module Lijab

module Config
   module_function

   def init(args)
      @opts = {}
      @dirs = {}
      @files = {}
      @accounts = []
      @account = nil

      setup_basedir(args[:basedir])
      read_accounts(args[:account])
      read_options()

      @jid = Jabber::JID.new("#{@account[:jabberid]}")
      @jid.resource ||= "lijab#{(0...5).map{rand(10).to_s}.join}"
      @account[:server] ||= @jid.domain

      create_account_log_dirs()
   end

   def setup_basedir(basedir)
      xdg = ENV["XDG_CONFIG_HOME"]
      @basedir = basedir || xdg && File.join(xdg, "lijab") || File.expand_path("~/.lijab")

      unless File.directory?(@basedir)
         puts "Creating #{@basedir} with the default configs"
      end

      %w{commands extensions logs}.each do |d|
         @dirs[d.to_sym] = path = File.join(@basedir, d)
         FileUtils.mkdir_p(path)
      end

      %w{accounts config}.each do |f|
         @files[f.to_sym] = path = File.join(@basedir, "#{f}.yml")
         unless File.file?(path)
            File.open(path, 'w') { |fd| fd.puts(DEFAULT_FILES[f]) }
         end
      end
   end

   def read_accounts(account)
      File.open(@files[:accounts]) do |f|
         YAML.load_documents(f) { |a| @accounts << a }
      end

      errors = []
      errors << "need at least one account!" if @accounts.empty?

      @accounts.each do |a|
         a[:port] ||= 5222

         errors << "account #{a} needs a name" unless a.key?(:name)
         errors << "account #{a[:name] || a} needs a jabberid" unless a.key?(:jabberid)
      end

      @account = account ? @accounts.find { |a| a[:name] == account} : @accounts[0]

      errors << "no account with name #{account} in #{@accounts_file}" if account && !@account

      errors.each do |e|
         STDERR.puts("#{File.basename($0)}: error: #{e}")
      end

      exit(1) unless errors.empty?
   end

   def read_options
      # FIXME: error check / validate
      @opts = YAML.load(DEFAULT_FILES["config"])
      @opts.merge!(YAML.load_file(@files[:config]))
   end

   def create_account_log_dirs
      @accounts.select { |a| a[:log] }.each do |a|
         a[:log_dir] = File.join(@dirs[:logs], @jid.strip.to_s)
         FileUtils.mkdir_p(a[:log_dir])
      end
   end

   def account_logdir
      @account[:log_dir]
   end

   DEFAULT_FILES = {
      "accounts" => %Q{
         # Accounts go here. Separate each one with ---
         # First one is the default.

         #---
         #:name : an_account                  # the account name
         #:jabberid : fisk@example.com/lijab  # the resource is optional
         #:password : frosk                   # optional, will prompt if not present
         #:server : localhost                 # optional, will use the jid domain if not present
         #:port : 5222                        # optional
         #:log : yes                          # yes|no ; default no

         #---
         #:name : another_account
         #:jabberid : another_user@example.com/lijab
      }.gsub!(/^\s*/, ''),

      "config" => %Q{
         # default config file

         # time formatting (leave empty to not show timestamps)
         :datetime_format : %H:%M:%S                   # normal messages
         :history_datetime_format : %Y-%b-%d %H:%M:%S  # history messages

         # Command aliases.
         # <command_alias> : <existing_command>
         # Commands can be overloaded.
         # For instance /who could be redefined like so to sort by status by default
         # /who : /who status
         :aliases :
            /h : /history
            /exit : /quit
      }.gsub!(/^\s{9}/, '')
   }

   attr_reader     :jid, :account, :basedir, :dirs, :files, :opts
   module_function :jid, :account, :basedir, :dirs, :files, :opts
end

end

