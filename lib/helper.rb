# frozen_string_literal: true

class CommandrbBot
  module Helper
    def self.error_embed(error: nil, footer: nil, colour: nil, color: nil, code_error: true)
      raise 'Invalid arguments for Helper.error_embed!' if error.nil? || footer.nil?

      colour = 0xFA0E30 if color.nil? && colour.nil?
      Discordrb::Webhooks::Embed.new(
        title: '#❌ An error has occured!',
        description: code_error ? "```ruby\n#{error}```" : error,
        colour: colour || color,
        footer: Discordrb::Webhooks::EmbedFooter.new(text: footer)
      )
    end
  end
end
