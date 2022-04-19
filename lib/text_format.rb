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
      current_arg = reader.next_arg

      case arg_type
      when :user
        user = Helper.user_parse(bot, current_arg)
        if user.nil? && format[:optional] == true
          raise FormatError.new arg_type, 'No user given or found!'
        end

        result_args[symbol] = user
      else
        raise FormatError.new arg_type, 'Unimplemented type given!'
      end
    end

    result_args
  end
end
