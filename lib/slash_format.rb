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
      # Not all slash commands require a format.
      next if command_format.nil?

      map_arg_format_to_options command_format, options
    end

    puts "Registered slash command #{command_name}" if @command_bot.debug_mode

    @bot.application_command(command_name) do |event|
      # TODO: handle
      puts "Ran command #{event.command_name}"
    end
  end

  def register_group(command)
    # TODO
  end

  # Maps our custom arg_format to the official builder.
  # @!macro arg_format
  # @param [Discordrb::Interactions::OptionBuilder] options
  def map_arg_format_to_options(arg_format, options)
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
end
