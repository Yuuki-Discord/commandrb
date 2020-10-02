# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'commandrb'
  s.version     = '0.4.8'
  s.date        = '2020-10-03'
  s.summary     = 'Commandrb'
  s.description = 'A customisable and easy to use Commands System for Discordrb.'
  s.authors     = ['Erisa A']
  s.email       = 'seriel@erisa.moe'
  s.files       = ['lib/commandrb.rb', 'lib/helper.rb']
  s.required_ruby_version = '>= 2.4'
  s.homepage =
    'https://github.com/Yuuki-Discord/commandrb'
  s.license = 'MIT'
  s.add_runtime_dependency 'discordrb', '~> 3.1', '>= 3.1.0'
end
