# frozen_string_literal: true

require 'pry'

# TextReader allows somewhat buffered argument parsing.
# You can wrap a TextReader around a string and read through space-delimited arguments,
# or allow it to parse segments within quotes.
class TextReader
  @contents = ''

  # Creates a new TextReader for the given string.
  # @param [String] contents String to wrap
  # @return [TextReader] new reader
  def initialize(contents)
    @contents = contents
  end

  # Reads until the next space-delimited argument, or quote-enclosed string.
  # @return [String, nil] Argument contents, or nil if arguments have been exhausted
  def next_arg
    # Determine whether we are exhausted.
    return nil if @contents.empty?

    # If we start with a quotation mark, hand off logic to read_quotation.
    if quotation?
      read_quotation
    else
      read_space_delimiter
    end
  end

  # Determines whether our current contents begin with a quotation mark,
  # implying a variable length argument.
  # @return [Bool] if the string begins with a quotation mark
  def quotation?
    @contents[0] == '"' || @contents[0] == '“'
  end

  # Reads until the end of a quotation mark.
  # If no closing quotation mark is found, it reads until the end of the given contents.
  # @return [String] Argument contents
  def read_quotation
    result = @contents[1..]
    # Determine the index of the ending quotation mark.
    index = result.index('"') || result.index('”')

    if index.nil?
      # It appears we have no ending quotation mark.
      # We return the remaining contents and exhaust ourselves.
      value = result
      result = ''
    else
      # We read until immediately before the quotation mark.
      value = result[..index - 1]
      # Our new contents are the index to the end.
      result = result[index + 1..]
      result = result.strip!
    end

    @contents = result
    value
  end

  # Reads until the next space-delimited argument.
  # If no ending space is found, it reads until the end of the given contents.
  # @return [String] Argument contents
  def read_space_delimiter
    # Determine the index of our delimiting space.
    index = @contents.index(' ')

    if index.nil?
      value = @contents
    else
      value = @contents[..index]
      # Update our contents to reflect we've read past this space.
      @contents = @contents[index..].strip!
    end

    value
  end

  # Reads the remaining text stored.
  # @return [String] Argument contents
  def read_remaining
    @contents.strip
  end
end
