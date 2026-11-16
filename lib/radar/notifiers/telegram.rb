module Radar
  module Notifiers
    class Telegram
      Error = Class.new(StandardError)

      def self.configured?
        !ENV["TELEGRAM_BOT_TOKEN"].to_s.empty? && !ENV["TELEGRAM_CHAT_ID"].to_s.empty?
      end

      def initialize(token: ENV.fetch("TELEGRAM_BOT_TOKEN"), chat_id: ENV.fetch("TELEGRAM_CHAT_ID"))
        @token = token
        @chat_id = chat_id
      end

      def deliver(bot, item)
        status = Http.post_json("https://api.telegram.org/bot#{@token}/sendMessage",
                                chat_id: @chat_id, disable_web_page_preview: true,
                                text: "[#{bot}] #{item.title}\n#{item.url}")
        raise Error, "Telegram respondeu HTTP #{status}" unless status == 200

        sleep 1 # o Telegram limita cerca de uma mensagem por segundo por chat
      end
    end
  end
end
