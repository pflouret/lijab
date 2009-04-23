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
              Dir["#{Config.commands_dir}/**/*.rb"]

      files.each { |f| load f }
   end

   def register(name, cmd)
      @registered[name] = cmd
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
      cmd = line[1..-1].split(" ", 2)[0]
      if cmd
         cmd = cmd.strip
         if !cmd.empty? && @registered.key?(cmd.to_sym)
            (@registered[cmd.to_sym].completer(line) || []).map { |s| "/#{cmd} #{s}" }
         else
            matches = @registered.keys.select { |k| k.to_s.match(/^#{Regexp.escape(cmd)}/) }
            matches.length == 1 && "/#{matches[0]}" || matches.map { |k| "/#{k}" }
         end
      else
         @registered.keys.map { |k| "/#{k}" }
      end
   end
end

end

