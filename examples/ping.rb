require 'discordrb'
require 'commandrb'

cbot = CommandrbBot.new(
    {
      token: '<insert token here>',
      client_id: 168123456789123456,
      prefixes: ['!']
    }
)

cbot.add_command(:ping, 
  code: proc { |event,args|
    event.respond('Pong!')
  }
)

cbot.bot.run
