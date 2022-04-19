# frozen_string_literal: true

require_relative 'text_reader'

# TextFormat implements parsing arguments for text-based commands.
class TextFormat
  # Parses a text command to have formatting, similar to slash commands.
  # @param [Discordrb::CommandBot] bot The bot handling this message.
  # @param [String] args Contents of the message.
  # @param [Hash{Symbol => Hash}] arg_format A hash describing arguments expected for a symbol.
  # @return [Hash{Symbol => Object}] A hash mapping an argument's symbol to its value.
  def self.derive_arguments(bot, args, arg_format)
    return nil if arg_format.nil? || args.nil?

    # Hand off reading to our custom class.
    reader = TextReader.new args

    # We may have to iterate through multiple arguments at a time for a type.
    result_args = ArgumentHash.new

    arg_format.each do |symbol, format|
      arg_type = format[:type]

      # Determine the argument contents for the type.
      # Only for :remaining we call read_remaining.
      current_arg = if arg_type == :remaining
                      reader.read_remaining
                    else
                      reader.next_arg
                    end

      # If there are no more arguments...
      if current_arg.nil?
        # and we are an optional type, use the default.
        if format[:optional]
          result_args[symbol] = format[:default] if format[:default]
          break
        end

        # Otherwise, we need to raise an error.
        # TODO: provide argument information, i.e. remaining commands?
        raise NotEnoughArgumentsError
      end

      # We switch by argument type.
      case arg_type
      when :string, :remaining
        # We simply use the next argument for string values.
        arg_value = current_arg

        # An upper character limit may be specified.
        if (format.key? :max_char) && (arg_value.length > format[:max_char])
          raise FormatError.new arg_type, "Maximum character limit exceeded! (#{format[:max_char]})"
        end
      when :integer
        # Integer values must be validated.
        begin
          arg_value = Integer(current_arg)
        rescue ArgumentError
          raise FormatError.new arg_type, 'Invalid integer value!'
        end
      when :user
        # We must attempt parsing a user via several methods.
        arg_value = Helper.user_parse(bot, current_arg)
        raise FormatError.new arg_type, 'No user given or found!' if arg_value.nil?
      else
        raise FormatError.new arg_type, 'Unimplemented type given!'
      end

      # Set the obtained value.
      result_args[symbol] = arg_value
    end

    result_args
  end
end
