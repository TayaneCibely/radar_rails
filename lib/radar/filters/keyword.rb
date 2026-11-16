module Radar
  module Filters
    # Cada regra *_all_of é uma lista de grupos; cada grupo precisa de pelo menos um termo.
    #   all_of:          procura no texto inteiro (título, corpo e etiquetas).
    #   headline_all_of: procura só no título e nas etiquetas. Use para o que o corpo
    #                    cita à toa, como "júnior" em "você vai orientar devs júnior".
    #   none_of:         termos que eliminam o item, procurados só no título.
    # A comparação ignora acentos e maiúsculas e casa palavras inteiras.
    class Keyword
      def initialize(all_of: [], headline_all_of: [], none_of: [])
        @groups = compile(all_of)
        @headline_groups = compile(headline_all_of)
        @blocked = Array(none_of).map { |term| pattern(term) }
      end

      def match?(item)
        title = normalize(item.title)

        covers?(@groups, normalize(item.text)) &&
          covers?(@headline_groups, normalize(item.headline)) &&
          @blocked.none? { |term| title.match?(term) }
      end

      private

      def compile(groups) = Array(groups).map { |group| Array(group).map { |term| pattern(term) } }

      def covers?(groups, text) = groups.all? { |group| group.any? { |term| text.match?(term) } }

      def normalize(value)
        text = value.to_s
        text = text.dup.force_encoding(Encoding::UTF_8) unless text.encoding == Encoding::UTF_8
        text.scrub.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase
      end

      def pattern(term) = /(?<!\w)#{Regexp.escape(normalize(term))}(?!\w)/
    end
  end
end
