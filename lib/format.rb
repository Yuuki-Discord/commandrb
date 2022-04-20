# frozen_string_literal: true

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

# ArgumentHash is a special type of hash, allowing dot-notation access of keys.
# This allows hash.key to be equivalent to hash[:key].
class ArgumentHash < Hash
  # We want to handle all available keys.
  # @param [Symbol] name Name of method.
  # @return [Bool] whether we want to handle this name
  def respond_to_missing?(name)
    # Return whether we have a key by this name.
    key? name
  end

  # Default handler for non-existent methods.
  # In this case, we use it to permit dot notation key lookup.
  # @param [Symbol] name Name of the invoked method.
  # @param [Array<Object>] args Passed arguments for the method.
  #   As we wish to only handle keys, this should always be empty.
  # @raise [NoMethodError] if arguments are given alongside a method
  # @return [Object] Value of the key by the given name.
  def method_missing(name, *args)
    # We do not want to handle calls with arguments.
    super unless args.empty?

    # Access this key normally.
    self[name]
  end
end

# FormatError is an error type thrown throughout argument parsing.
class FormatError < RuntimeError
  # @!attribute Hash[]
  attr_reader :arg_format

  # Creates a FormatError for the given argument type.
  def initialize(arg_format, msg)
    @arg_format = arg_format
    super(msg)
  end
end

# NotEnoughArgumentsError can be raised when there are not enough arguments
# given to fully process a command.
class NotEnoughArgumentsError < RuntimeError
end
