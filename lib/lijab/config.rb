
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

      create_account_dirs()
   end

   def setup_basedir(basedir)
      xdg = ENV["XDG_CONFIG_HOME"]
      @basedir = basedir ||
                 xdg && File.join(xdg, "lijab") ||
                 "~/.lijab"
      @basedir = File.expand_path(@basedir)

      unless File.directory?(@basedir)
         puts "Creating #{@basedir} with the default configs"
      end

      %w{accounts commands hooks}.each do |d|
         @dirs[d.to_sym] = path = File.join(@basedir, d)
         FileUtils.mkdir_p(path)
      end

      @files[:accounts] = path = File.join(@basedir, "accounts.yml")
      File.open(path, 'w') { |f| f.puts(DEFAULT_ACCOUNTS_FILE) } unless File.file?(path)

      @files[:config] = File.join(@basedir, "config.yml")
      dump_config_file(true)
   end

   def dump_config_file(default=false, clobber=false)
      if !File.file?(@files[:config]) || clobber
         File.open(@files[:config], 'w') do |f|
            DEFAULT_OPTIONS.each do |a|
               if a[2]
                  f.puts
                  a[2].each { |l| f.puts("# #{l}") }
               end
               v = default ? a[1] : @opts[a[0]]
               f.puts(YAML.dump({a[0] => v})[5..-1].chomp)
            end
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
         a[:port] ||= a[:use_ssl] ? 5223 : 5222

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

      @opts = Hash[*DEFAULT_OPTIONS.collect { |a| [a[0], a[1]] }.flatten]
      @opts.merge!(YAML.load_file(@files[:config]))
   end

   def create_account_dirs
      @accounts.each do |a|
         a[:dir] = File.join(@dirs[:accounts], @jid.strip.to_s)
         a[:log_dir] = File.join(a[:dir], "logs")
         a[:typed] = File.join(a[:dir], "typed_history")

         [:dir, :log_dir].each { |s| FileUtils.mkdir_p(a[s]) }
      end
   end

   DEFAULT_OPTIONS = [
      [:datetime_format, "%H:%M:%S", ["Time formatting (leave empty to disable timestamps)"]],
      [:history_datetime_format, "%Y-%b-%d %H:%M:%S"],
      [:autocomplete_online_first, true, 
       ["When completing contacts try to find matches for online contacts, and if none",
        "is found try to find matches on all of them. Otherwise always match every",
        "contact."]],
      [:ctrl_c_quits, false,
       ["ctrl+c quits the program if enabled, otherwise ctrl+c ignores whatever is",
        "typed and you get a clean prompt, and ctrl+d on a clean line exits lijab,",
        "terminal style."]],
      [:show_status_changes, true, ["Show changes in contacts' status"]],
      [:terminal_bell_on_message, true,
       ["Ring the terminal bell on incoming message.",
        "Useful for setting the urgent hint on the terminal window:",
        "Set as so in your ~/.Xdefaults, might have to run xrdb -merge ~/.Xdefaults afterwards",
        "XTerm*bellIsUrgent: true",
        "or",
        "URxvt*urgentOnBell: true",
        "or just look it up on your terminal's man page, don't be lazy."]],
      [:status_priorities,
       {:chat => 55, :available => 50, :away => 40, :xa => 30, :dnd => 20},
       ["Default priority for each status"]],
      [:aliases, {"/h" => "/history", "/exit" => "/quit"},
       ["Command aliases.",
        "<command_alias> : <existing_command>",
        "Commands can be overloaded.",
        "For instance /who could be redefined like so to sort by status by default.",
        "/who : /who status"]]
   ]

   DEFAULT_ACCOUNTS_FILE = %Q{
      # Accounts go here. Separate each one with ---
      # First one is the default.

      #---
      #:name : an_account                  # the account name
      #:jabberid : fisk@example.com/lijab  # the resource is optional
      #:password : frosk                   # optional, will prompt if not present
      #:server : localhost                 # optional, will use the jid domain if not present
      #:port : 5222                        # optional
      #:use_ssl : no                       # deprecated in jabber, but might help sometimes
      #:log : yes                          # yes|no ; default no

      #---
      #:name : another_account
      #:jabberid : another_user@example.com/lijab

      #---
      #:name : gmail_account
      #:jabberid : blah@gmail.com/lijab
      #:server : talk.google.com
      ## might wanna try use_ssl if the normal settings don't work (e.g. in ubuntu afaik)
      ##:port : 5223
      ##:use_ssl : yes
      #:log : yes

   }.gsub!(/^ */, '')

   attr_reader     :jid, :account, :basedir, :dirs, :files, :opts
   module_function :jid, :account, :basedir, :dirs, :files, :opts
end

end

