
module Lijab
module Commands

   Command.define :set do
      usage "/set <option> [<value>]"
      description "Modify the options. Print the current value if no <value> is given.\n" \
                  "See #{Config.files[:config]} for the available options."
      def run(args)
         option, value = args.split(nil, 2).strip

         option = option.to_sym if option

         if !(Config.opts[option].is_a?(String) ||
              Config.opts[option].is_a?(Numeric) ||
              [true, false, nil].include?(Config.opts[option])) &&
            Config.opts.key?(option)
            raise CommandError, %{can't change "#{option} with /set"}
         elsif !Config.opts.key?(option)
            raise CommandError, %{no such option "#{option}"}
         end

         if value && !value.empty?
            begin
               val = YAML.load(value)
               #raise TypeError unless val.is_a?(Config.opts[option].class)
               Config.opts[option] = val
            rescue
               Out::error("invalid value", false)
            end
         else
            puts YAML.dump(Config.opts[option])[4..-1].chomp
         end

      end

      def completer(line)
         option = line.split(nil, 2).strip[1] || ""
         Config.opts.keys.find_all do |k|
            k.to_s =~ /^#{Regexp.escape(option)}/ &&
            (Config.opts[k].is_a?(String) ||
             Config.opts[k].is_a?(Numeric) ||
             [true, false, nil].include?(Config.opts[k]))
         end
      end
   end

end
end
