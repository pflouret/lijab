
module Lijab

module Config
   module_function

   def init(args)
      setup_basedir(args[:basedir])

      read_accounts(args[:account])

      @jid = Jabber::JID.new("#{@account['jabberid']}")
      @jid.resource ||= "lijab#{(0...5).map{rand(10).to_s}.join}"
      @account["server"] ||= @jid.domain
   end

   def read_accounts(account)
      @accounts = []
      File.open(@accounts_file) do |f|
         YAML.load_documents(f) { |a| @accounts << a }
      end

      errors = []
      errors << "need at least one account!" if @accounts.empty?
      @accounts.each do |a|
         a["port"] ||= 5222
         errors << "account #{a} needs a name" unless a.key?("name")
         errors << "account #{a} needs a jabberid" unless a.key?("jabberid")
      end

      @account = account ? @accounts.select {|a| a["name"] == account}.first : @accounts[0]

      errors << "no account with name #{account} in #{@accounts_file}" if !@account && account

      errors.each { |e| STDERR.puts("#{File.basename($0)}: error: #{e}") }
      exit(1) unless errors.empty?
   end

   def setup_basedir(basedir)
      xdg = ENV["XDG_CONFIG_HOME"]
      @basedir = basedir || xdg && File.join(xdg, "lijab") || File.expand_path("~/.lijab")

      @commands_dir = File.join(@basedir, "commands")
      @extensions_dir = File.join(@basedir, "extensions")
      @logs_dir = File.join(@basedir, "logs")

      @accounts_file = File.join(@basedir, "accounts.yml")
      @config_file = File.join(@basedir, "config.yml")

      [@commands_dir, @extensions_dir, @logs_dir].each { |d| FileUtils.mkdir_p(d) }

      unless File.file?(@accounts_file)
         File.open(@accounts_file, 'w') { |f| f.puts(DEFAULT_ACCOUNTS_FILE) }
      end
   end
   def account_logdir
      FileUtils.mkdir_p(File.join(Config.logs_dir, Config.jid.strip.to_s))
   end

   DEFAULT_ACCOUNTS_FILE = %Q{
      # Accounts go here. Separate each one with ---

      #---
      #name: an_account # the account name
      #jabberid: fisk@example.com/lijab # the resource is optional
      #password: frosk # optional, will prompt if not present
      #server: localhost # optional, will use the jid domain if not present
      #port: 5222 # optional

      #---
      #name: another_account
      #jabberid: another_user@example.com/lijab
   }.gsub!(/^\s*/, '')

   attr_reader     :jid, :account, :basedir, :commands_dir, :extensions_dir,
      :logs_dir, :accountsfile, :configfile
   module_function :jid, :account, :basedir, :commands_dir, :extensions_dir,
      :logs_dir, :accountsfile, :configfile
end

end

