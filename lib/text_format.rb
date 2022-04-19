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
        # If we are an optional type, use the default.
        if format[:optional]
          result_args[symbol] = format[:default] if format[:default]
          break
        end

        # We shouldn't be finished. Raise an error.
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
      when :number
        # Similarly, double (er... float) values must be validated.
        begin
          arg_value = Float(current_arg)
        rescue ArgumentError
          raise FormatError.new arg_type, 'Invalid double value!'
        end
      when :boolean
        # Attempt to determine common boolean representations.
        case current_arg
        when 'yes', 'true', '1'
          arg_value = true
        when 'no', 'false', '0'
          arg_value = false
        else
          raise FormatError.new arg_type, 'Invalid boolean type passed!'
        end
      when :user
        # We must attempt parsing a user via several methods.
        arg_value = Helper.user_parse(bot, current_arg)
        raise FormatError.new arg_type, 'No user given or found!' if arg_value.nil?
      else
        raise FormatError.new arg_type, 'Unimplemented type given!'
      end

      # If we have choices, we must now validate them.
      if format[:choices]
        valid = false
        format[:choices].each do |choice|
          # For text commands, we will allow both the name and internal value for backwards compat.
          valid = true if choice[:name] == arg_value || choice[:value] == arg_value
        end

        raise FormatError.new arg_type, 'Invalid choice!' unless valid
      end

      # Set the obtained value.
      result_args[symbol] = arg_value
    end

    result_args
  end
end
