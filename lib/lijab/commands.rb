# Copyright (c) 2009 pablo flouret <quuxbaz@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


module Lijab

module Commands
   @registered = {}

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
   end

   def register(name, cmd)
      @registered[name] = cmd
   end

   def register_alias(name, s)
      alias_cmd, alias_args = s.split(" ", 2)
      alias_cmd.strip!
      alias_cmd = alias_cmd[1..-1] if alias_cmd[0] == ?/

      Command.define name.to_sym do
         description %{Alias for "#{s}"}
         @alias_cmd = alias_cmd
         @alias_args = alias_args
         @name = name

         def run(args)
            Commands::run(@alias_cmd, [@alias_args, args].join(" "))
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

   def run(cmd, args="")
      cmd = cmd.strip.to_sym
      if @registered.key?(cmd)
         begin
            @registered[cmd].run(args.strip)
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

