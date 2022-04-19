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
  def respond_to_missing?(name)
    # Return whether we have a key by this name.
    key? name
  end

  def method_missing(name, *args)
    # Check if this symbol is available.
    if key? name
      self[name]
    else
      super
    end
  end
end

# FormatError is an error type thrown throughout argument parsing.
class FormatError < RuntimeError
  attr_reader :arg_type

  def initialize(arg_type, msg)
    @arg_type = arg_type
    super(msg)
  end
end
