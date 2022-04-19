# frozen_string_literal: true

# Format is an interface for parsing a command.
# It should never be instantiated directly.
class Format
  # Derived from https://git.io/J1zsG, "Application Command Option Type" within
  # Discord's Interactions documentation.
  ARGUMENT_TYPES = %i[
    string
    integer
    boolean
    user
    channel
    role
    mentionable
    number
    remaining
  ].freeze
end

# FormatError is an error type thrown throughout argument parsing.
class FormatError < RuntimeError
  attr_reader :arg_type

  def initialize(msg, arg_type)
    @arg_type = arg_type
    super(msg)
  end
end
