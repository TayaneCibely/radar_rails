require "json"

module Radar
  module Sources
    # Qualquer API que devolva uma lista de objetos JSON (ex.: RemoteOK, Remotive).
    # O mapeamento de campos vem do .yml:
    #   items:  chave onde está a lista (omita se a resposta já for a lista)
    #   fields: key, title (um campo ou vários), url, body, tags
    class JsonApi
      def initialize(url:, name:, fields:, items: nil)
        @url = url
        @name = name
        @fields = fields
        @items = items
      end

      def fetch = parse(Http.get(@url))

      def parse(json)
        data = JSON.parse(json)
        entries = @items ? data.fetch(@items) : data

        entries.filter_map do |entry|
          # Entradas sem identificador não são itens (a RemoteOK abre a lista com um aviso legal).
          key = entry[@fields.fetch("key")]
          next if key.nil?

          Item.new(source: "api:#{@name}", key: key.to_s, url: entry[@fields.fetch("url")],
                   title: Array(@fields.fetch("title")).filter_map { |field| entry[field] }.join(" - "),
                   body: entry[@fields["body"]], tags: Array(entry[@fields["tags"]]))
        end
      end
    end
  end
end
