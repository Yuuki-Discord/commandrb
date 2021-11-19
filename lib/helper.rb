# frozen_string_literal: true

class CommandrbBot
  # Utilizes several methods to attempt to determine a user.
  def user_parse(context)
    # Can't do anything if there's nothing to begin with.
    return nil if context.nil?

    # Catches cases such as "0": obviously invalid, attempted nonetheless.
    context = context.to_s

    # If it's an ID.
    id_check = bot.user(context)
    return id_check unless id_check.nil?

    # If it's a mention!
    matches = /<@!?(\d+)>/.match(context)
    return bot.user(matches[1]) unless matches.nil?

    # Might be a username...
    return bot.find_user(context)[0] unless bot.find_user(context).nil?

    nil
  end

  # Generates a usable error embed with defaults.
  def error_embed(error: nil, footer: nil, colour: nil, color: nil)
    raise 'Invalid arguments for Helper.error_embed!' if error.nil? || footer.nil?

    colour = 0xFA0E30 if color.nil? && colour.nil?
    Discordrb::Webhooks::Embed.new(
      title: '❌ An error has occurred!',
      description: error,
      colour: colour || color,
      footer: Discordrb::Webhooks::EmbedFooter.new(text: footer)
    )
  end

  # Generates a usable error embed with defaults, and a formatted error.
  def code_embed(error: nil, footer: nil, colour: nil, color: nil)
    raise 'Invalid arguments for Helper.code_embed!' if error.nil? || footer.nil?

    # Format to have a code block with formatting.
    error = "```ruby\n#{error}```"

    error_embed(error: error, footer: footer, colour: colour, color: color)
  end
end
