# frozen_string_literal: true

require 'pry'
require_relative 'format'
require_relative 'helper'

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
    if attributes.key? :arg_format
      # Do an extremely brief check that all types are valid.
      attributes[:arg_format].each do |argument|
        type = argument[:type]
        raise "Command #{name} has invalid argument type #{type}!" unless ARGUMENT_TYPES
      end
    end

    @commands[name.to_sym] = attributes
  end

  def remove_command(name)
    begin
      @commands.delete(name)
    rescue StandardError
      return false
    end
    true
  end

  # By defining this sepearately. we allow you to overwrite it and use your own owner list.
  # Your checks will instead be run by commandrb and allow you to use :owner_only as normal.
  def owner?(id)
    @config[:owners].include?(id)
  end

  alias is_owner? owner?

  def initialize(init_hash)
    @debug_mode = ENV['COMMANDRB_MODE'] == 'debug'

    # Setup the variables for first use.
    @commands = {}
    @prefixes = []
    @config = init_hash

    # Load sane defaults for options that aren't specified.

    # @config[:prefix_type] = 'rescue' if @config[:prefix_type].nil?
    @config[:typing_default] = false if @config[:typing_default].nil?
    @config[:delete_activators] = false if @config[:delete_activators].nil?

    raise 'No token supplied in init hash!' if @config[:token].nil? || (init_hash[:token] == '')

    init_parse_self = begin
      init_hash[:parse_self]
    rescue StandardError
      nil
    end
    init_type = @config[:type]

    if init_type == :bot && init_hash[:client_id].nil?
      raise 'No client ID or invalid client ID supplied in init hash!'
    end

    @config[:owners] = init_hash[:owners]
    @config[:owners] = [] if @config[:owners].nil?

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
      chosen_activator = nil
      args = nil
      message_content = nil
      used_prefix = ''

      # If we have a usable prefix, get the raw arguments for this command.
      @prefixes.each do |prefix|
        next unless event.message.content.start_with?(prefix)

        # Store the message's content, sans its prefix.
        # Strip leading spaces in the event a prefix ends with a space.
        message_content = event.message.content
        used_prefix = message_content.slice! prefix
        break
      end

      # Otherwise, do not continue processing.
      next if message_content.nil?

      @commands.each do |key, command|
        puts ":: Considering #{key}" if @debug_mode == true
        triggers = command[:triggers].nil? ? [key.to_s] : command[:triggers]

        triggers.each do |trigger|
          activator = trigger.to_s.downcase
          puts activator if @debug_mode == true
          next unless event.message.content.downcase.start_with?(activator)

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
          else
            puts 'Match failed...' if @debug_mode == true
            next
            # If you haven't chosen yet, get choosing!
          end
        end

        puts "Result: #{chosen_activator}" if @debug_mode == true

        next if chosen_activator.nil?

        command_run = used_prefix + chosen_activator
        puts "Final result: #{command_run}" if @debug_mode == true

        # Command flag defaults
        command[:owners_only] = false if command[:owners_only].nil?
        command[:server_only] = false if command[:server_only].nil?
        command[:typing] = @config[:typing_default] if command[:typing_default].nil?
        command[:delete_activator] = @config[:delete_activators] if command[:delete_activator].nil?
        command[:owner_override] = false if command[:owner_override].nil?

        # If the settings are to delete activating messages, then do that.
        # I'm *hoping* this doesn't cause issues with argument extraction.
        event.message.delete if command[:delete_activator]

        # If the command is only for use in servers, display error and abort.
        if command[:server_only] && event.channel.private?
          event.channel.send_embed error_embed(
            error: 'This command can only be used in servers!',
            footer: "Command: `#{command_run}`"
          )
          break
        end

        # If the user is a bot and the command is set to not pass bots
        # OR the user is a bot and the global config is to not parse bots...
        # ...then abort :3
        if event.user.bot_account? && \
           (command[:parse_bots] == false || @config[:parse_bots] == false)
          # Abort!
          break
        end

        # If the config is setup to show typing messages, then do so.
        event.channel.start_typing if command[:typing]

        # Our arguments are the message's contents, minus the activator.
        args = message_content
        args.slice! chosen_activator
        args = args.split

        command[:required_permissions]&.each do |x|
          if event.user.on(event.server).permission?(x, event.channel) \
            || (command[:owner_override] && @config[:owners].include?(event.user.id))
            next
          end

          event.channel.send_embed '', error_embed(
            error: "You don't have permission for that!\nPermission required: `#{x}`",
            footer: "Command: `#{command_run}`"
          )
          break
        end

        # If the command is set to owners only and the user is not the owner,
        # show an error and abort.
        puts "[DEBUG] Command being processed: '#{command}'" if @debug_mode == true
        puts "[DEBUG] Owners only? #{command[:owners_only]}" if @debug_mode == true
        if command[:owners_only] && !owner?(event.user.id)
          event.channel.send_embed '', error_embed(
            error: "You don't have permission for that!\n"\
                   'Only owners are allowed to access this command.',
            footer: "Command: `#{command_run}`"
          )
          break
        end

        # Run the command code!
        begin
          command_format = derive_arguments(args, command[:arg_format])
        rescue FormatError => e
          # Arguments were not provided properly.
          # Inform the user of this.
          # TODO: Provide a nicer format of displaying this, instead of a raw error
          # We may wish to supply command help as well.
          event.channel.send_embed '', error_embed(
            error: "Invalid argument for command:\n#{e.message}",
            footer: "Command: `#{command_run}`"
          )
          break
        end

        # TODO: determine a good method to log other errors as made via the command.
        # Without, we will simply log to console.
        command[:code].call(event, *command_format)

        # All done here.
        puts "Finished!! Executed command: #{chosen_activator}" if @debug_mode == true
        break
      end
    end
  end
end
