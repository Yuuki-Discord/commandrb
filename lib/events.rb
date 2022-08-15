# frozen_string_literal: true

require 'discordrb'

module Discordrb
  module Events
    # Allows making an ApplicationCommandEvent closer to a MessageEvent.
    class ApplicationCommandEvent
      # Simple wrapper to help build embeds, similar to {Discordrb::Events::Respondable}.
      #
      # @param message [String] The message that should be sent along with the embed.
      #   If this is the empty string, only the embed will be shown.
      # @param embed [Discordrb::Webhooks::Embed, nil] The embed to start the building process with,
      #   or nil if one should be created anew.
      def self.send_embed(message = '', embed = nil, attachments = nil)
        embed ||= Discordrb::Webhooks::Embed.new
        yield(embed) if block_given?

        respond(message, embeds: [embed], attachments: attachments)
      end

      # Simple wrapper to allow respond not require the content keyword.
      # (see Interaction#respond)
      def respond(content, tts: nil, embeds: nil, allowed_mentions: nil, flags: 0, ephemeral: nil,
                  wait: false, components: nil, &block)
        @interaction.respond(
          content: content, tts: tts, embeds: embeds, allowed_mentions: allowed_mentions,
          flags: flags, ephemeral: ephemeral, wait: wait, components: components, &block
        )
      end
    end
  end
end
