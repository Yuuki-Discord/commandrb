# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'commandrb'
  s.version     = '0.4.8.0'
  s.date        = '2020-07-05'
  s.summary     = 'Commandrb'
  s.description = 'A customisable and easy to use Commands System for Discordrb.'
  s.authors     = ['Erisa A (Seriel)']
  s.email       = 'seriel@erisa.moe'
  s.files       = ['lib/commandrb.rb', 'lib/helper.rb']
  s.required_ruby_version = '>= 2.4'
  s.homepage =
    'https://github.com/Yuuki-Discord/commandrb'
  s.license = 'MIT'
  s.add_runtime_dependency 'discordrb', '~> 3.1', '>= 3.1.0'
end
