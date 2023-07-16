# frozen_string_literal: true

require 'discordrb'
require 'arg_format'
require_relative 'format'
require_relative 'events'
require_relative 'helper'
require_relative 'text_format'
require_relative 'slash_format'

# CommandrbBot manages prefixes and command registration for a bot.
class CommandrbBot
  # The loaded configuration. It is safe to adjust this during runtime.
  attr_accessor :config

  # Needed to run the bot, or create custom events.
  attr_accessor :bot

  # A store of registered commands. Do not manipulate this throughout runtime.
  attr_accessor :commands

  # Whether this bot is currently in debug mode.
  attr_accessor :debug_mode

  # A list of global prefixes. It is not recommended to change this while the bot is running.
  attr_accessor :prefixes

  # An interface to working with slash commands.
  # @!return [SlashFormat]
  attr_accessor :slash_format

  # Registers a command with the command handler.
  # @param [Symbol] name The name of the command to run.
  # @param [Hash] attributes Options about the command.
  # @option attributes [Bool] :delete_activator (false) Whether the
  #   invoking message should be deleted upon execution.
  # @option attributes [Array<Symbol>] :required_permissions (nil)
  #   An array of permissions the user must have to execute.
  #   See {Discordrb::Permissions::FLAGS} for a complete list.
  # @option attributes [Bool] :typing (false) Whether the
  #   bot should start typing while executing a command, i.e.
  #   to signify a long-running command.
  # @option attributes [Symbol] :group (nil) A group of commands.
  #
  #   For example, consider command "bar" in group "foo".
  #   The resulting command would be "prefix!foo bar" for text-based commands,
  #   or as a registered sub-command for interaction-based commands.
  # @option attributes [Bool] :text_command (false) If the command is in a group,
  #   this "flattens" the command for text-based invocations.
  #   Via this, command "bar" in group "foo" would still be invoked as "prefix!bar".
  #   This allows category of commands far too numerous for individual slash commands
  #   to still function as individual commands.
  # @option attributes [Bool] :text_only (false) If set,
  #   does not register as an interaction-based command.
  # @option attributes [Symbol] :slash_trigger (default name) Overrides
  #   the name of the interaction-based command for this command.
  #   This is especially helpful for commands like 'help', which are polluted.
  # @option attributes [String] :description A description of this command.
  # @option attributes [Array<String>] :triggers (command name) An array of
  #   strings that can be used to invoke this command.
  #
  #   Note that if the command is present within a command group without text_subcommand,
  #   triggers will be prefixed with the group.
  # @option attributes [Bool] :server_only (false) Whether the
  #   command should only be run in servers and not be available in DMs.
  # @!macro arg_format
  # @option attributes [Bool] :owners_only (false) Whether this command
  #   should only be run by bot owners.
  # @option attributes [Bool] :owner_override (false) Whether channel
  #   permissions should be ignored because the user is a bot owner.
  # @yieldparam [Discordrb::Events::MessageEvent] event The event corresponding
  #   to this command invocation.
  # @yieldparam [ArgumentHash] args Arguments run alongside the command.
  # @yieldparam [String] message_contents The full contents of the invoking message.
  # @return [void]
  def add_command(name, attributes = {}, &block)
    raise "Command #{name} has no block specified!" if block.nil?

    if attributes.key? :arg_format
      # Check that all types are valid.
      ArgFormat.validate_arg_formats(attributes[:arg_format])
    end

    # Owner-only commands should remain text-only for the time being.
    attributes[:text_only] = true if attributes[:owners_only] == true

    # We need to enforce a description if not text-only.
    unless attributes.key? :text_only
      attributes[:text_only] = false

      raise "#{name} is missing a command description!" unless attributes.key? :description

      if attributes[:description].length > 100
        raise "#{name} has a command description exceeding 100 characters!"
      end
    end

    if attributes[:text_only] && (attributes.key? :slash_trigger)
      raise "#{name} is attempting to override a slash trigger on a text-only command!"
    end

    # Register with text handler
    @commands[name.to_sym] = attributes
    @commands[name.to_sym][:code] = block

    # Text-only commands should not be registered for slash commands.
    return if attributes[:text_only] == true

    # Register with slash handler if not in group.
    # (Group commands will be registered upon run to avoid duplicates.)
    return if attributes.key? :group

    @slash_format.register_command(name.to_sym, @commands[name.to_sym])
  end

  # Determines whether the given ID is an owner.
  #
  # By defining this separately, we allow you to overwrite it and use your own owner list.
  # Your checks will instead be run by commandrb and allow you to use :owner_only as normal.
  # @param [Integer] id ID of the user to check against.
  # @return [Bool] whether the user is an owner of the bot
  def owner?(id)
    @config[:owners].include?(id)
  end

  alias is_owner? owner?

  # Initializes Commandrb for the given token and credentials.
  # @param [Hash] init_hash Attributes for the bot to use.
  # @option init_hash [String] :token A bot token provided by Discord.
  # @option init_hash [Integer] :client_id The client ID for this bot as provided by Discord.
  # @option init_hash [Array<Integer>] :owners An array of owners for :owner_only commands.
  # @option init_hash [Bool] :typing_default (false) Whether to begin typing upon
  #   command invocation.
  # @option init_hash [Bool] :delete_activators (false) Whether to delete the invocation message.
  # @option init_hash [Bool] :parse_bots (false) Whether to respond to messages from other bots.
  # @option init_hash [Array<String>] :prefixes List of prefixes to respond to.
  # @option init_hash [Proc] :ready A proc to invoke upon the gateway ready event.
  # @option init_hash [Bool] :disable_text_commands (false) If true,
  #   disables text-based command handling.
  def initialize(init_hash)
    @debug_mode = ENV.fetch('COMMANDRB_MODE', nil) == 'debug'

    # Setup the variables for first use.
    @commands = {}
    @prefixes = init_hash[:prefixes] || []
    @config = init_hash

    # Load sane defaults for options that aren't specified.
    @config[:typing_default] = false if @config[:typing_default].nil?
    @config[:delete_activators] = false if @config[:delete_activators].nil?
    @config[:disable_text_commands] = false if @config[:disable_text_commands].nil?
    @config[:owners] = [] if @config[:owners].nil?
    @config[:parse_bots] = false if @config[:parse_bots].nil?

    raise 'No token supplied in init hash!' if @config[:token].nil? || (init_hash[:token] == '')

    raise 'No client ID or invalid client ID supplied in init hash!' if init_hash[:client_id].nil?

    @bot = Discordrb::Bot.new(
      token: @config[:token],
      client_id: @config[:client_id],
      parse_self: false,
      ignore_bots: @config[:parse_bots] == false,
      intents: @config[:intents]
    )

    unless init_hash[:ready].nil?
      @bot.ready do |event|
        event.bot.game = @config[:game] unless config[:game].nil?
        init_hash[:ready].call(event)
      end
    end

    # Command processing
    @slash_format = SlashFormat.new self

    return if @config[:disable_text_commands] == true

    @bot.message do |event|
      handle_text_command event
    end
  end

  # Handles evaluating logic for text commands.
  # @param [Discordrb::MessageEvent] event The text command event to process.
  def handle_text_command(event)
    chosen_activator = nil
    message_content = event.message.content
    chosen_command = nil

    # Determine whether we have a usable prefix on this message.
    # Otherwise, do not continue processing.
    used_prefix = determine_prefix message_content
    return if used_prefix.nil?

    # Next, determine the command being run.
    # We remove the length of the prefix in order to permit case-insensitivity.
    message_content = message_content[used_prefix.length..]

    @commands.each do |name, command|
      puts ":: Considering #{name}" if @debug_mode == true
      chosen_activator = determine_activator name, command, message_content

      puts "Result: #{chosen_activator}" if @debug_mode == true
      next if chosen_activator.nil?

      # As a valid activator was utilized, we will use this command.
      chosen_command = command
      break
    end

    # If we have no chosen command, it is likely the command does not exist
    # or the prefix itself was run.
    return if chosen_command.nil?

    command_run = used_prefix + chosen_activator
    puts "Final result: #{command_run}" if @debug_mode == true

    # Command flag defaults
    chosen_command[:owners_only] = false if chosen_command[:owners_only].nil?
    chosen_command[:server_only] = false if chosen_command[:server_only].nil?
    chosen_command[:typing] = @config[:typing_default] if chosen_command[:typing_default].nil?
    if chosen_command[:delete_activator].nil?
      chosen_command[:delete_activator] =
        @config[:delete_activators]
    end
    chosen_command[:owner_override] = false if chosen_command[:owner_override].nil?

    # If the settings are to delete activating messages, then do that.
    event.message.delete if chosen_command[:delete_activator]

    # If the command is only for use in servers, display error and abort.
    if chosen_command[:server_only] && event.channel.private?
      event.channel.send_embed Helper.error_embed(
        error: 'This command can only be used in servers!',
        footer: "Command: `#{command_run}`"
      )
      return
    end

    # If the config is setup to show typing messages, then do so.
    event.channel.start_typing if chosen_command[:typing]

    no_permission = false

    chosen_command[:required_permissions]&.each do |x|
      # No need to respect permissions if we have an owner override.
      next if chosen_command[:owner_override] && @config[:owners].include?(event.user.id)

      next if event.user.on(event.server).permission?(x, event.channel)

      event.channel.send_embed '', Helper.error_embed(
        error: "You don't have permission for that!\nPermission required: `#{x}`",
        footer: "Command: `#{command_run}`"
      )
      no_permission = true
      break
    end

    return if no_permission

    # If the command is set to owners only and the user is not the owner,
    # show an error and abort.
    puts "[DEBUG] Command being processed: '#{chosen_command}'" if @debug_mode == true
    puts "[DEBUG] Owners only? #{chosen_command[:owners_only]}" if @debug_mode == true
    if chosen_command[:owners_only] && !owner?(event.user.id)
      event.channel.send_embed '', Helper.error_embed(
        error: "You don't have permission for that!\n" \
               'Only owners are allowed to access this command.',
        footer: "Command: `#{command_run}`"
      )
      return
    end

    # Handle arguments accordingly.
    # We remove the length of the activator in order to permit case-insensitivity.
    message_content = message_content[chosen_activator.length..]
    args = message_content.strip
    args = if chosen_command[:arg_format].nil?
             # Our arguments are the message's contents, minus the activator.
             args.split
           else
             # We rely on the command's specified formatting for parsing.
             format = TextFormat.new event, args, chosen_command[:arg_format]
             format.derive_arguments
           end

    # Run the command code!
    # TODO: determine a good method to log other errors as made via the command.
    # Without, we will simply log to console.
    chosen_command[:code].call(event, args)

    # All done here.
    puts "Finished!! Executed command: #{chosen_activator}" if @debug_mode == true
  end

  # Determines the prefix used for the given message.
  # @param message The message to determine a prefix from.
  # @return [String] The prefix used in this message.
  # @return [nil] If no prefix was present.
  def determine_prefix(message)
    @prefixes.each do |prefix|
      next unless message.downcase.start_with?(prefix.downcase)

      return prefix
    end

    # It seems we could not find a prefix.
    nil
  end

  # Determines the best activator given a command.
  # @param [String] name The name of the command being determined.
  # @param [Hash] command The command to determine via.
  # @param [String] message The message being parsed.
  # @return [String] The activator used to invoke this command.
  # @return [nil] If no activator was present for the given command.
  def determine_activator(name, command, message)
    # Used to keep track of better activators throughout loop duration.
    chosen_activator = nil

    # If the command has no triggers, we only utilize its name.
    triggers = if command[:triggers].nil?
                 [name]
               else
                 command[:triggers]
               end

    # If this command is in a group and is not a text subcommand,
    # its triggers must be prefixed with the group name.
    if !command[:group].nil? && command[:text_subcommand] != true
      group = command[:group].to_s
      triggers.map! do |trigger|
        "#{group} #{trigger}"
      end
    end

    triggers.each do |trigger|
      activator = trigger.to_s.downcase
      puts "Considering activator #{activator}" if @debug_mode == true
      next unless message.downcase.start_with?(activator)

      puts "Prefix matched! #{activator}" if @debug_mode == true

      # Continue only if you've already chosen a choice.
      if chosen_activator.nil?
        puts 'First match obtained!' if @debug_mode == true
        chosen_activator = activator

        # If the new activator begins with the chosen one, then override it.
        # Example: sh is chosen, shell is the new one.
        # In this example, shell would override sh, preventing ugly bugs.
      elsif activator.start_with?(chosen_activator)
        puts "#{activator} just overrode #{chosen_activator}" if @debug_mode == true
        chosen_activator = activator
        # Otherwise, just give up.
      elsif @debug_mode == true
        puts 'Match failed...'
      end
    end

    chosen_activator
  end
end
