module Radar
  # O fluxo comum aos dois bots: coletar -> filtrar -> descartar vistos -> notificar.
  class Pipeline
    Result = Struct.new(:collected, :matched, :fresh, :failures, keyword_init: true)

    def initialize(name:, sources:, filter:, store:, notifier:)
      @name = name
      @sources = sources
      @filter = filter
      @store = store
      @notifier = notifier
    end

    # notify: false -> só registra como visto (para "zerar" a primeira execução).
    # mark: false   -> só mostra, sem registrar (teste de filtro).
    def run(notify: true, mark: true)
      failures = []
      collected = collect(failures)
      matched = collected.select { |item| @filter.match?(item) }.uniq(&:uid)
      fresh = matched.reject { |item| @store.seen?(@name, item.uid) }

      fresh.each do |item|
        @notifier.deliver(@name, item) if notify
        # Só marca depois de notificar: se o envio falhar, o item volta na próxima execução.
        @store.mark(@name, item.uid) if mark
      end

      Result.new(collected: collected.size, matched: matched.size, fresh: fresh.size, failures:)
    end

    private

    # Uma fonte fora do ar não derruba as outras.
    def collect(failures)
      @sources.flat_map do |source|
        source.fetch
      rescue StandardError => e
        failures << "#{source.class.name}: #{e.message}"
        []
      end
    end
  end
end
