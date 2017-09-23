class CommandrbBot

  # Be able to adjust the config on the fly.
  attr_accessor :config

  # Needed to run the bot, or create custom events.
  attr_accessor :bot

  # Can manually manipulate commands using this.
  attr_accessor :commands

  # Lets you change global prefixes while the bot is running (Not recommended!)
  attr_accessor :prefixes


  def add_command(name, attributes = {})
    @commands[name.to_sym] = attributes
  end

  def remove_command(name)
    begin
      @commands.delete(name)
    rescue
      return false
    end
    true
  end

  def initialize(init_hash)

    # Setup the variables for first use.
    @commands = {}
    @prefixes = []
    @config = init_hash

    # Load sane defaults for options that aren't specified.

    # @config[:prefix_type] = 'rescue' if @config[:prefix_type].nil?
    @config[:typing_default] = false if @config[:typing_default].nil?
    @config[:selfbot] =  false if  @config[:selfbot].nil?
    @config[:delete_activators] = false if @config[:delete_activators].nil?

    if @config[:token].nil? or init_hash[:token] == ''
      puts 'No token supplied in init hash!'
      return false
    end

    init_parse_self = init_hash[:parse_self] rescue nil
    init_type = @config[:type]

    if init_type == :bot
      if init_hash[:client_id].nil?
        puts 'No client ID or invalid client ID supplied in init hash!'
        return false
      end
    end

    @config[:owners] = init_hash[:owners]

    @prefixes = init_hash[:prefixes]

    @bot = Discordrb::Bot.new(
        token: @config[:token],
        client_id: @config[:client_id],
        parse_self: init_parse_self,
        type: @config[:type]
    )

    unless init_hash[:ready].nil?
      @bot.ready do |event|
        event.bot.game = @config[:game] unless config[:game].nil?
        init_hash[:ready].call(event)
      end
    end


    # Command processing
    @bot.message do |event|
      @command = nil
      @event = nil
      @chosen = nil
      @args = nil
      @rawargs = nil
      @continue = false
      @prefixes.each { |prefix|
        if event.message.content.start_with?(prefix)

          @commands.each { | key, command |
            triggers =  command[:triggers].nil? ? [key.to_s] : command[:triggers]

            triggers.each { |trigger|
              @activator = prefix + trigger.to_s
              @activator = @activator.downcase
              if event.message.content.downcase.start_with?(@activator)

                # Continue only if you've already chosen a choice.
                unless @chosen.nil?
                  # If the new activator begins with the chosen one, then override it.
                  # Example: sh is chosen, shell is the new one.
                  # In this example, shell would override sh, preventing ugly bugs.
                  if @activator.start_with?(@chosen)
                    @chosen = @activator
                  # Otherwhise, just give up.
                  else
                    next
                  end
                # If you haven't chosen yet, get choosing!
                else
                    @continue = true
                    @chosen = @activator
                end
              end
            }

            next unless @continue

            break if @config[:selfbot] && event.user.id != @bot.profile.id

            # Command flag defaults
            command[:catch_errors] = @config[:catch_errors] if command[:catch_errors].nil?
            command[:owners_only] = false if command[:owners_only].nil?
            command[:max_args] = 2000 if command[:max_args].nil?
            command[:server_only] = false if command[:server_only].nil?
            command[:typing] = @config[:typing_default] if command[:typing_default].nil?
            command[:delete_activator] = @config[:delete_activators] if command[:delete_activator].nil?

            # If the command is set to owners only and the user is not the owner, show error and abort.
            if command[:owners_only]
              unless @config[:owners].include?(event.user.id)
                event.respond('❌ You don\'t have permission for that!')
                next
              end
            end

            # If the settings are to delete activating messages, then do that.
            # I'm *hoping* this doesn't cause issues with argument extraction.
            event.message.delete if command[:delete_activator]

            # If the command is only for use in servers, display error and abort.
            if command[:server_only] && event.channel.private?
              # For selfbots, a fancy embed will be used. WIP.
              if @config[:selfbot]
                event.channel.send_embed do |embed|
                  embed.colour = 0x221461
                  embed.title = '❌ An error has occured!'
                  embed.description = 'This command can only be used in servers!'
                  embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Command: '#{event.message.content}'")
                end
              else
                # If its not a selfbot, an ordinary message will be shown, may be changed to embed later.
                event.respond('❌ This command will only work in servers!')
              end
              # Abort!
              next
            end

            # If the user is a bot and the command is set to not pass bots OR the user is a bot and the global config is to not parse bots...
            # ...then abort :3
            if (event.user.bot_account? && command[:parse_bots] == false) || (event.user.bot_account? && @config[:parse_bots] == false)
              # Abort!
              next
            end

            # If the config is setup to show typing messages, then do so.
            event.channel.start_typing if command[:typing]

            # Grabs the arguments from the command message without the command part.
            args = event.message.content.slice!(@activator.length, event.message.content.size)
            # Split the arguments into an array for easy usage.
            rawargs = args
<<<<<<< HEAD
            args = args.split(' ')
=======
            args = args.split(/ /)
>>>>>>> fb6b1a9c7a757e934830139d7b72a2c97f245090

            # Check the number of args for the command.
            if args.length > command[:max_args]
              # May be replaced with an embed.
              event.respond("❌ Too many arguments! \nMax arguments: `#{command[:max_args]}`")
              next
            end

<<<<<<< HEAD
            # If the command is configured to catch all errors, thy shall be done.
            if !command[:catch_errors] || @config['catch_errors']
              # Run the command code!
              command[:code].call(event, args, rawargs)
            else
              # Run the command code, but catch all errors and output accordingly.
              begin
                command[:code].call(event, args, rawargs)
              rescue Exception => e
                event.respond("❌ An error has occured!! ```ruby\n#{e}```Please contact the bot owner with the above message for assistance.")
              end
            end

            # All done here.
=======
            # All done here.
            @command = command
            @event = event
            @args = args
            @rawargs = rawargs
>>>>>>> fb6b1a9c7a757e934830139d7b72a2c97f245090
            break
          }
          # If the command is configured to catch all errors, thy shall be done.
          if !@command[:catch_errors] || @config['catch_errors']
            # Run the command code!
            @command[:code].call(@event, @args, @rawargs)
          else
            # Run the command code, but catch all errors and output accordingly.
            begin
              @command[:code].call(@event, @args, @rawargs)
            rescue Exception => e
              event.respond("❌ An error has occured!! ```ruby\n#{e}```Please contact the bot owner with the above message for assistance.")
            end
          end
          break
        end
      }
    end
  end
end