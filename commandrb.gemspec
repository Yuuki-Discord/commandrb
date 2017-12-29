Gem::Specification.new do |s|
  s.name        = 'commandrb'
  s.version     = '0.4.7'
  s.date        = '2017-12-29'
  s.summary     = 'Commandrb'
  s.description = 'A customisable and easy to use Commands System for Discordrb.'
  s.authors     = ['Erisa Komuro (Seriel)']
  s.email       = 'seriel@fl0.co'
  s.files       = ['lib/commandrb.rb', 'lib/helper.rb']
  s.required_ruby_version = '>= 2.1'
  s.homepage    =
      'https://github.com/Seriell/commandrb'
  s.license       = 'MIT'
  s.add_runtime_dependency 'discordrb', '~> 3.1', '>= 3.1.0'
end