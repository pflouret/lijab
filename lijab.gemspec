# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{lijab}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pablo Flouret"]
  s.date = %q{2009-05-05}
  s.default_executable = %q{lijab}
  s.email = %q{quuxbaz@gmail.com}
  s.executables = ["lijab"]
  s.extensions = ["ext/extconf.rb"]
  s.files = ["ext/extconf.rb", "ext/readline_extra.c", "lib/lijab/commands/contacts.rb", "lib/lijab/commands/options.rb", "lib/lijab/commands/simple.rb", "lib/lijab/commands/status.rb", "lib/lijab/commands/subscription.rb", "lib/lijab/commands.rb", "lib/lijab/config.rb", "lib/lijab/contacts.rb", "lib/lijab/history.rb", "lib/lijab/hooks.rb", "lib/lijab/input.rb", "lib/lijab/main.rb", "lib/lijab/out.rb", "lib/lijab/term/ansi.rb", "lib/lijab/version.rb", "lib/lijab/xmpp4r/message.rb", "lib/lijab.rb", "lib/readline/extra.rb", "bin/lijab"]
  s.homepage = %q{http://github.com/palbo/lijab}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.0")
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Extensible line oriented jabber client}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<file-tail>, [">= 0"])
      s.add_runtime_dependency(%q<term-ansicolor>, [">= 0"])
      s.add_runtime_dependency(%q<xmpp4r>, [">= 0"])
    else
      s.add_dependency(%q<file-tail>, [">= 0"])
      s.add_dependency(%q<term-ansicolor>, [">= 0"])
      s.add_dependency(%q<xmpp4r>, [">= 0"])
    end
  else
    s.add_dependency(%q<file-tail>, [">= 0"])
    s.add_dependency(%q<term-ansicolor>, [">= 0"])
    s.add_dependency(%q<xmpp4r>, [">= 0"])
  end
end
