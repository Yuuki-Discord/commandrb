# frozen_string_literal: true

# Allows registration and invocation of interactions
# (more commonly known as slash commands).
class SlashFormat
  # @return [CommandrbBot]
  attr_accessor :command_bot

  # @return [Discordrb::Bot]
  attr_accessor :bot

  # Allows manipulation of slash commands.
  # @param command_bot [CommandrbBot] The bot to interface with.
  def initialize(command_bot)
    @command_bot = command_bot
    @bot = command_bot.bot
  end

  # Registers a command against Discord.
  #
  # @param [Symbol] command_name The name of this command.
  # @param [Hash] command The command to register.
  def register_command(command_name, command)
    command_description = command[:description].to_s
    command_format = command[:arg_format]

    @bot.register_application_command(command_name, command_description) do |options|
      map_arg_format_to_options command_format, options
    end

    puts "Registered slash command #{command_name}" if @command_bot.debug_mode

    @bot.application_command(command_name) do |event|
      # TODO: handle
      puts "Ran slash command #{event.command_name}" if @command_bot.debug_mode

      args = derive_arguments command_format, event
      command[:code].call(event, args)
    end
  end

  def register_group(command)
    # TODO
  end

  # Maps our custom arg_format to the official builder.
  # @!macro arg_format
  # @param [Discordrb::Interactions::OptionBuilder] options
  def map_arg_format_to_options(arg_format, options)
    # Not all slash commands require a format.
    return nil if arg_format.nil?

    arg_format.each do |symbol, format|
      name = symbol.to_s
      description = format[:description]
      arg_type = format[:type]
      required = format[:optional] == false

      # Optional fields
      choices = nil
      min_value = nil
      max_value = nil

      # Map our Array(Hash(:name, :key)) to a simple hash.
      if format.key? :choices
        choices = {}
        format[:choices].each do |choice|
          choices[choice[:name]] = choice[:value]
        end
      end

      case arg_type
      when :string, :remaining
        options.string(name, description, required: required, choices: choices)
      when :integer
        options.integer(name, description, required: required, choices: choices)
      when :number
        options.number(name, description, required: required, min_value: min_value,
                                          max_value: max_value, choices: choices)
      when :boolean
        options.boolean(name, description, required: required)
      when :user
        options.user(name, description, required: required)
      when :channel
        options.channel(name, description, required: required)
      else
        format_error 'Unimplemented type given!'
      end
    end
  end

  # Maps our custom arg_format to the official builder.
  # @!macro arg_format
  # @param event [Discordrb::Events::ApplicationCommandEvent] The current event.
  # @return [ArgumentHash{Symbol => Object}] A hash mapping an argument's symbol to its value.
  def derive_arguments(arg_format, event)
    # Not all slash commands require a format.
    return nil if arg_format.nil?

    options = event.options
    # Return an ArgumentHash for dot-notation access.
    result_args = ArgumentHash.new

    # The format name is the name specified within arg_format itself,
    # and is what we use to identify an argument's value.
    arg_format.each do |format_name, format|
      # The Discord name is the name given to Discord to identify an option,
      # and is what they use to identify an argument's value.
      # This is needed to look up result values, and resolved types.
      discord_name = format[:name]
      arg_type = format[:type]

      # Ensure Discord gave us this parameter.
      discord_arg_value = options[discord_name]

      if discord_arg_value.nil?
        # If we aren't optional, this should not be nil.
        # TODO: properly handle error
        raise NotEnoughArgumentsError unless format[:optional]

        # Otherwise, ensure we set the default.
        result_args[format_name] = determine_default format, event
        next
      end

      # Switch by argument type.
      arg_value = case arg_type
                  when :string, :remaining, :integer, :number, :boolean
                    discord_arg_value
                  when :user
                    event.resolved.users[discord_name]
                  when :channel
                    event.resolved.channels[discord_name]
                  else
                    format_error 'Unimplemented type given!'
                  end
      result_args[format_name] = arg_value
    end

    result_args
  end

  # Determines the default value for the current format.
  # TODO: This is a derivation of text_format's determine_default -
  # we should likely consolidate them.
  # @param format The current arg_format.
  # @param event [ApplicationCommandEventHandler] The current event.
  # @return [Object] Default value specified for the format.
  def determine_default(format, event)
    return nil unless format.key? :default

    # Users and channels can have symbols defaults, allowing context-aware defaults.
    default = format[:default]
    type = format[:type]

    if type == :user && default == :current_user
      event.user
    elsif type == :channel && default == :current_channel
      event.channel
    else
      # Use the provided default per the format.
      default
    end
  end
end
