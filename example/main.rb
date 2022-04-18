#!/usr/bin/env ruby

# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

cbot = CommandrbBot.new(
  {
    token: ENV['COMMANDRB_TOKEN'],
    client_id: ENV['COMMANDRB_CLIENTID'],
    prefixes: ['!']
  }
)

cbot.add_command(:ping) do |event|
  event.respond('Pong!')
end

cbot.bot.run
