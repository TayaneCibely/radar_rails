module Radar
  module Notifiers
    # Usado em --dry-run e quando o Telegram não está configurado.
    class Console
      def deliver(bot, item)
        puts "[#{bot}] #{item.title}\n  #{item.url}\n  (#{item.source})"
      end
    end
  end
end
