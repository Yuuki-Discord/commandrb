# frozen_string_literal: true

# ArgFormat has functions related to argument format validation.
class ArgFormat
  # Validates whether an array of arg_formats is valid.
  # @!macro arg_format
  # @raise [FormatError] if a format is invalid
  def self.validate_arg_formats(arg_format)
    seen_optional = false

    arg_format.each do |arg_name, format|
      # Once we've seen an optional arg, all args past it must be optional.
      is_optional = format[:optional] || false
      if seen_optional && !is_optional
        raise "#{arg_name} marked as non-optional after previous optional type!"
      end

      validate_arg_format(format)

      seen_optional = true if is_optional
    end
  end

  # Validates whether the given argument format is valid.
  # @raise [FormatError] if a format is invalid
  def self.validate_arg_format(format)
    name = format[:name].to_s
    type = format[:type]

    # Arguments require a name and a valid type.
    raise "Argument with #{type} lacks a name!" if name.nil?
    raise "#{name} has invalid argument type #{type}!" unless ARGUMENT_TYPES

    # You cannot specify max_char if not string/remaining.
    if !format[:max_char].nil? && !%i[string remaining].include?(type)
      raise "#{name} cannot specify a maximum character length if it is not a string type!"
    end

    return unless format.key? :choices
    # Ensure choices are sane.
    unless %i[string integer number].include?(type)
      # Choices are only available on string, integer, or number types.
      raise "#{name} with #{type} cannot contain choices!"
    end

    # Ensure choices are within range.
    return unless format[:choices].length > 25

    raise "#{name} has more than 25 choices!"
  end
end
