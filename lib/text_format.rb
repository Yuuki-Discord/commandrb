# frozen_string_literal: true

require_relative 'text_reader'

# TextFormat implements parsing arguments for text-based commands.
class TextFormat
  # @return [Hash{Symbol => Object}] The format for the current argument.
  @format = nil

  # @return [Discordrb::Events::MessageEvent] The event for this message.
  @event = nil

  # @return [TextReader] The argument content to parse for this message.
  @reader = nil

  # A hash of argument name => formatting.
  # @return [Hash{Symbol => Object}]
  @all_formats = nil

  # Creates a TextFormat object to derive arguments.
  # @param [Discordrb::Events::MessageEvent] event The event for this message.
  # @param [String] args The string of arguments to this command.
  # @!macro arg_format
  def initialize(event, args, arg_format)
    @event = event
    # Hand off reading to our custom class.
    @reader = TextReader.new args unless args.nil?
    @all_formats = arg_format unless arg_format.nil?
  end

  # Parses a text command to have formatting, similar to slash commands.
  # @return [ArgumentHash{Symbol => Object}] A hash mapping an argument's symbol to its value.
  def derive_arguments
    # Return an ArgumentHash for dot-notation access.
    result_args = ArgumentHash.new

    @all_formats.each do |symbol, format|
      @format = format
      arg_type = @format[:type]

      # Determine the argument contents for the type.
      # Only for :remaining we call read_remaining.
      current_arg = if arg_type == :remaining
                      @reader.read_remaining
                    else
                      @reader.next_arg
                    end

      # If there are no more arguments...
      if current_arg.nil?
        # If we are an optional type, there's no issue.
        if @format[:optional]
          # Ensure we set the default.
          result_args[symbol] = determine_default
          break
        end

        # We shouldn't be finished. Raise an error.
        # TODO: provide argument information, i.e. remaining commands?
        raise NotEnoughArgumentsError
      end

      # Switch by argument type.
      arg_value = case arg_type
                  when :string, :remaining
                    parse_string current_arg
                  when :integer
                    parse_integer current_arg
                  when :number
                    parse_number current_arg
                  when :boolean
                    parse_boolean current_arg
                  when :user
                    parse_user current_arg
                  when :channel
                    parse_channel current_arg
                  else
                    format_error 'Unimplemented type given!'
                  end

      # If we have choices, we must now validate them.
      validate_choices(arg_value, format[:choices]) if format[:choices]

      # Set the obtained value.
      result_args[symbol] = arg_value
    end

    result_args
  end

  # Parses a boolean value from a string.
  # @param [String] boolean The boolean value to parse.
  # @raise [FormatError] if the given boolean is not a boolean value
  # @return [Bool] The parsed boolean value.
  def parse_boolean(boolean)
    case boolean
    when 'yes', 'true', '1'
      true
    when 'no', 'false', '0'
      false
    else
      format_error 'Invalid boolean type passed!'
    end
  end

  # Finds a channel from a string.
  # @param [String] given_channel The channel to parse.
  # @raise [FormatError] if the given channel does not pass validation
  # @return [Discordrb::Channel] The determined channel.
  def parse_channel(given_channel)
    arg_value = Helper.channel_parse(@event.bot, given_channel)
    format_error 'No channel given or found!' if arg_value.nil?
    arg_value
  end

  # Parses an integer value from a string.
  # @param [String] integer The integer to parse.
  # @raise [FormatError] if the given integer does not pass validation
  # @return [Integer] The parsed integer value.
  def parse_integer(integer)
    # TODO: implement bounds checks
    Integer(integer)
  rescue ArgumentError
    format_error 'Invalid integer value!'
  end

  # Parses a number (i.e. float) value from a string
  # @param [String] number The number to parse.
  # @raise [FormatError] if the given number does not pass validation
  # @return [Float] The parsed numerical value.
  def parse_number(number)
    # TODO: implement bounds checks
    Float(number)
  rescue ArgumentError
    format_error 'Invalid double value!'
  end

  # Validates a string from the given parameters.
  # @param [String] string The string to validate.
  # @raise [FormatError] if the given value does not pass validation
  # @return [String] The determined string value.
  def parse_string(string)
    # TODO: fully implement bounds checks

    # An upper character limit may be specified.
    if (@format.key? :max_char) && (string.length > @format[:max_char])
      format_error "Maximum character limit exceeded! (#{@format[:max_char]})"
    end

    string
  end

  # Finds a user from a string.
  # @param [String] given_user The user to parse.
  # @raise [FormatError] if the given user could not be resolved
  # @return [Discordrb::User] The determined user.
  def parse_user(given_user)
    user = Helper.user_parse(@event.bot, given_user)
    format_error 'No user given or found!' if user.nil?
    user
  end

  # Validates whether a given choice is a valid choice.
  # @param [String, Integer, Float] given_choice The choice given by the user.
  # @param [Array<Hash>] choices
  #   Available choices per the registered command.
  # @option choices [String] name The name of this choice value.
  # @option choices [String, Integer, Float] value The value of this choice.
  # @raise [FormatError] if the given value is not an applicable choice
  # @return [void]
  def validate_choices(given_choice, choices)
    found = false
    choices.each do |choice|
      # For text commands, we will allow both the name and internal value for backwards compat.
      found = true if choice[:name] == given_choice || choice[:value] == given_choice
    end

    format_error 'Invalid choice!' unless found
  end

  # Raises a formatting error for the current format.
  # @param [String] message Message to describe the format error.
  # @raise [FormatError] An error regarding the current format
  # @return [void]
  def format_error(message)
    raise FormatError.new @format, message
  end

  # Determines the default value for the current format.
  # @return [Object] Default value specified for the format.
  def determine_default
    return nil unless @format.key? :default

    # Users and channels can have symbols defaults, allowing context-aware defaults.
    default = @format[:default]
    type = @format[:type]

    if type == :user && default == :current_user
      @event.user
    elsif type == :channel && default == :current_channel
      @event.channel
    else
      # Use the provided default per the format.
      default
    end
  end
end
