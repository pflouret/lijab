
Gem::Specification.new do |s|

   s.name = 'lijab'
   s.version = '0.1'
   s.date = Time.now.to_s
   s.required_ruby_version = ">=1.8.0"

   s.summary = "Extensible line oriented jabber client"

   s.executables = ['lijab']
   s.files = Dir["ext/readlinep/*.{rb,c}"] +
             Dir["lib/**/*.rb"]

   s.extensions << 'ext/readlinep/extconf.rb'
   s.require_path = 'lib'

   s.add_dependency "file-tail"
   s.add_dependency "term-ansicolor"
   s.add_dependency "xmpp4r"

   s.author = "Pablo Flouret"
   s.email = "quuxbaz@gmail.com"
   s.homepage = "http://github.com/palbo/lijab"

end
