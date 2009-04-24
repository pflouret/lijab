
module Lijab

module Commands
   @registered = {}
   @overloaded = {}

   module CommandMixin
      def define_meta(*names)
         class_eval do
            names.each do |name|
               define_method(name) do |*args|
                  if args.size == 0
                     instance_variable_get("@#{name}")
                  else
                     instance_variable_set("@#{name}", *args)
                  end
               end
            end
         end
      end
   end

   class CommandError < RuntimeError
   end

   class Command
      class << self
         private :new
      end

      def self.define(name, &block)
         c = new
         c.instance_eval(&block)
         Commands::register(name.to_sym, c)
      end

      def completer(s)
      end

      def run(args)
      end

      extend CommandMixin
      define_meta :usage, :description
   end

   module_function

   def init
      files = Dir["#{File.dirname(File.expand_path(__FILE__))}/commands/*.rb"] + \
              Dir["#{Config.dirs[:commands]}/**/*.rb"]

      files.each { |f| load f }
      Config.opts[:aliases].each do |a, c|
         register_alias(a, c)
      end
   end

   def register(name, cmd)
      name = name.to_sym
      @overloaded[name] = @registered[name] if @registered.key?(name)
      @registered[name] = cmd
   end

   def register_alias(name, s)
      alias_cmd, alias_args = s.split(" ", 2)
      alias_cmd.strip!
      alias_cmd = alias_cmd[1..-1] if alias_cmd[0] == ?/
      name = name[1..-1] if name[0] == ?/

      Command.define name.to_sym do
         description %{Alias for "#{s}"}
         @alias_cmd = alias_cmd
         @alias_args = alias_args
         @name = name

         def run(args)
            Commands::run(@alias_cmd, [@alias_args, args].join(" "), true)
         end

         def completer(line)
            args = line.split(" ", 2)[1]
            Commands::completer("/#{@alias_cmd} #{@alias_args} #{args}").map do |r|
               r.gsub(/\/#{@alias_cmd}\s?/, "")
            end
         end
      end
   end

   def get(name)
      @registered[name.to_sym]
   end

   def registered?(name)
      @registered.key?(name.to_sym)
   end

   def run(cmd, args="", is_alias=false)
      cmd = cmd.strip.to_sym
      command = @overloaded[cmd] if is_alias
      command ||= @registered[cmd]
      if command
         begin
            command.run(args.strip)
         rescue CommandError => e
            Out::error("#{cmd}: #{e}", false)
         end
      else
         Out::error("no such command: /#{cmd}", false)
      end
   end

   def completer(line)
      cmd, args = line[1..-1].split(" ", 2).map { |p| p.strip }
      cmd ||= ""

      matches = @registered.keys.find_all { |c| c.to_s.match(/^#{Regexp.escape(cmd)}/) }

      if !cmd.empty? && (matches.length == 1 || args) && registered?(cmd)
         (@registered[cmd.to_sym].completer(line) || []).map { |s| "/#{cmd} #{s}" }
      else
         matches.map { |k| "/#{k}" }
      end
   end

   attr_reader :registered
   module_function :registered
end

end

