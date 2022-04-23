#!/usr/bin/env ruby

# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

cbot = CommandrbBot.new(
  {
    token: ENV.fetch('COMMANDRB_TOKEN', nil),
    client_id: ENV.fetch('COMMANDRB_CLIENTID', nil),
    prefixes: ['!']
  }
)

cbot.add_command(:ping) do |event|
  event.respond('Pong!')
end

cbot.bot.run
