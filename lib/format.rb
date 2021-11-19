# frozen_string_literal: true

class CommandrbBot
  # Derived from https://git.io/J1zsG
  # ("Application Command Option Type" within Discord's Interactions documentation)
  # We do not handle sub-commands or sub-command groups here.
  ARGUMENT_TYPES = %i[
    string
    integer
    boolean
    user
    channel
    role
    mentionable
    number
  ].freeze

  def derive_arguments(args, arg_format)
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

class FormatError < RuntimeError
  attr_reader :arg_type

  def initialize(msg, arg_type)
    @arg_type = arg_type
    super(msg)
  end
end
