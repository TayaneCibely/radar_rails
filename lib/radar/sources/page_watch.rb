require "nokogiri"
require "uri"

module Radar
  module Sources
    # Vigia uma página (ex.: "processo seletivo" de um programa de mestrado):
    # cada link vira um item, então um link novo que passe no filtro gera aviso.
    class PageWatch
      IGNORED = ["#", "javascript:", "mailto:", "tel:"].freeze

      def initialize(url:, name:, selector: "a[href]")
        @url = url
        @name = name
        @selector = selector
      end

      def fetch = parse(Http.get(@url))

      def parse(html)
        Nokogiri::HTML(html).css(@selector).filter_map do |anchor|
          link = absolute(anchor["href"])
          next unless link

          Item.new(source: "pagina:#{@name}", key: link, url: link, title: text_of(anchor), body: link)
        end.uniq(&:uid)
      end

      private

      # Junta os textos com espaço: em <span>Júnior</span><span>PJ</span> o texto
      # corrido seria "JúniorPJ" e o filtro por palavra inteira não acharia "júnior".
      def text_of(node)
        node.xpath(".//text()").map(&:text).join(" ").gsub(/\s+/, " ").strip
      end

      def absolute(href)
        href = href.to_s.strip
        return if href.empty? || href.start_with?(*IGNORED)

        URI.join(@url, href).to_s
      rescue URI::Error
        nil
      end
    end
  end
end
