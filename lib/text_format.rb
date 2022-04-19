# frozen_string_literal: true

require_relative 'format'

# TextFormat implements parsing arguments for text-based commands.
class TextFormat < Format
  # Parses a text command to have formatting, similar to slash commands.
  # @param [String] args Contents of the message.
  # @param [Hash{Symbol => Hash}] arg_format A hash describing arguments expected for a symbol.
  # @return [Hash{Symbol => Object}] A hash mapping an argument's symbol to its value.
  def self.derive_arguments(args, arg_format)
    return nil if arg_format.nil? || args.nil?

    # We may have to iterate through multiple arguments at a time for a type.
    arg_index = 0
    result_args = []

    arg_format.each do |format|
      arg_type = format[:type]
      current_arg = args[arg_index]

      case format[:type]
      when :user
        user = user_parse(current_arg)
        if user.nil? && format[:optional] == false
          raise FormatError.new 'No user given or found!', arg_type
        end

        result_args.push(user)
        arg_index += 1
      else
        raise FormatError.new 'Unimplemented type given!', arg_type
      end
    end

    result_args
  end
end
