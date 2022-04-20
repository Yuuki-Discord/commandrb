# frozen_string_literal: true

# The below macro is present only to define usage for arg_format.

# @macro [new] arg_format
#   @param arg_format [Array<Hash>] An array of formatting arguments used to parse values.
#   @option arg_format [String] :name The name of this argument.
#   @option arg_format [String] :description (nil) A description of this argument.
#   @option arg_format [Bool] :optional (false) whether the argument is optional and
#     does not need to be present
#   @option arg_format [Bool] :default (nil) a default value for the type.
#     Used if the argument is marked as optional.
#   @option arg_format [Symbol] :type The type of the command, one of {ARGUMENT_TYPES}.
#   @option arg_format [Array<Hash{Symbol=>String,Integer,Float}>] :choices An array of choices
#     available for this format. Only applicable if this type is 'string', 'integer', or 'number'.
#   @option arg_format [Integer] :max_char (nil) The maximum amount of characters permitted.
#    Only set if this type is 'string' or 'remaining'.

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
  # @return [Array<Hash>] the format related to this error.
  attr_reader :arg_format

  # Creates a FormatError for the given argument type.
  # @macro arg_format
  # @param [String] msg The contents of this error.
  def initialize(arg_format, msg)
    @arg_format = arg_format
    super(msg)
  end
end

# NotEnoughArgumentsError can be raised when there are not enough arguments
# given to fully process a command.
class NotEnoughArgumentsError < RuntimeError
end
