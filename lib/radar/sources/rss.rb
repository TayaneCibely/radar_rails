require "rss"

module Radar
  module Sources
    # Qualquer feed RSS ou Atom.
    class Rss
      def initialize(url:, name:)
        @url = url
        @name = name
      end

      def fetch
        feed = RSS::Parser.parse(Http.get(@url), false)
        raise Http::Error, "feed inválido em #{@url}" unless feed

        feed.items.map do |entry|
          link = unwrap(entry.link, :href)
          Item.new(source: "rss:#{@name}", key: link, title: unwrap(entry.title, :content),
                   url: link, body: body_of(entry))
        end
      end

      private

      # No RSS os campos são strings; no Atom são objetos.
      def unwrap(value, attribute) = value.respond_to?(attribute) ? value.public_send(attribute) : value

      def body_of(entry)
        return entry.description if entry.respond_to?(:description)

        unwrap(entry.summary || entry.content, :content)
      end
    end
  end
end
