class CommandrbBot
  attr_accessor :commands
  attr_accessor :prefixes
  attr_accessor :bot
  attr_accessor :prefix_type
  attr_accessor :owners
  attr_accessor :typing_default

  def initialize(init_hash)

    @commands = {}
    @prefixes = []
    @config = init_hash

    @config[:prefix_type] = 'rescue' if @config[:prefix_type].nil?
    @config[:typing_default] =  false if @config[:typing_default].nil?

    if @config[:token].nil? or init_hash[:token] == ''
      puts 'No token supplied in init hash!'
      return false
    end

    init_parse_self = init_hash[:parse_self] rescue nil
    init_type = init_hash[:type] rescue :bot

    if init_type == :bot
      if init_hash[:client_id].nil?
        puts 'No client ID or invalid client ID supplied in init hash!'
        return false
      end
    end

    @prefixes = []

    @config[:owners] = init_hash[:owners]
    puts 'Invalid owners supplied in init hash!'

    @prefixes = init_hash[:prefixes]
    puts 'Invalid prefixes supplied in init hash!'

    @bot = Discordrb::Bot.new(
        token: @config[:token],
        client_id: @config[:client_id],
        parse_self: init_parse_self,
        type: init_type
    )

    unless init_hash[:ready].nil?
      @bot.ready do |event|
        init_hash[:ready].call(event)
      end
    end

    def add_command(name, attributes = {})
      @commands[name.to_sym] = attributes
    end

    # Command processing
    @bot.message do |event|
      @continue = false
      @prefixes.each { |prefix|
        if event.message.content.start_with?(prefix)

          @commands.each { | key, command |
            if command[:triggers].nil?
              triggers = [key.to_s]
            else
              triggers = command[:triggers]
            end

            triggers.each { |trigger|
              @activator = prefix + trigger
              if event.message.content.start_with?(@activator)
                puts '@activator picked.'
                @continue = true
                break
              else
                next
              end
            }

            next unless @continue

            # Command flag defaults
            command[:catch_errors] = @config[:catch_errors] if command[:catch_errors].nil?
            command[:owners_only] = false if command[:owners_only].nil?
            command[:max_args] = 2000 if command[:max_args].nil?
            command[:server_only] = false if command[:server_only].nil?
            command[:typing] = @config[:typing_default] if command[:typing_default].nil?

            if command[:owners_only]
              unless YuukiBot.config['owners'].include?(event.user.id)
                event.respond('❌ You don\'t have permission for that!')
                break
              end
            end

            if command[:server_only] && event.channel.private?
              event.respond('❌ This command will only work in servers!')
              next
            end

            if (event.user.bot_account? && command[:parse_bots] == false) || (event.user.bot_account? && @config[:parse_bots] == false)
              next
            end

            event.channel.start_typing if command[:typing]

            args = event.message.content.slice!(@activator.length, event.message.content.size)
            args = args.split(' ')

            if args.length > command[:max_args]
              event.respond("❌ Too many arguments! \nMax arguments: `#{command[:max_args]}`")
              next
            end
            if !command[:catch_errors] || @config['catch_errors']
              command[:code].call(event, args)
            else
              begin
                command[:code].call(event, args)
              rescue Exception => e
                event.respond("❌ An error has occured!! ```ruby\n#{e}```Please contact the bot owner with the above message for assistance.")
              end
            end
            break
          }
          break
        end
      }
    end
  end
end