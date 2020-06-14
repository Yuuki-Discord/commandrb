# frozen_string_literal: true

require 'discordrb'
require 'commandrb'

cbot = CommandrbBot.new(
  {
    token: '<insert token here>',
    client_id: 168_123_456_789_123_456,
    prefixes: ['!']
  }
)

cbot.add_command(:ping,
                 code: proc { |event, _args|
                   event.respond('Pong!')
                 })

cbot.bot.run
