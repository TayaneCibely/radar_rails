module Radar
  module CLI
    ROOT = File.expand_path("../..", __dir__)

    # Devolve o código de saída: 0 ok, 1 alguma fonte falhou, 2 uso incorreto.
    def self.run(argv)
      flags, names = argv.partition { |arg| arg.start_with?("--") }
      dry_run = flags.include?("--dry-run")
      seed = flags.include?("--seed")

      available = Dir[File.join(ROOT, "config", "*.yml")].map { |path| File.basename(path, ".yml") }.sort
      names = available if names == ["all"]
      if names.empty? || (names - available).any?
        warn "uso: radar <#{available.join('|')}|all> [--dry-run] [--seed]"
        return 2
      end

      store = Store.new(ENV.fetch("RADAR_DB", File.join(ROOT, "data", "radar.db")))
      notifier = dry_run || !Notifiers::Telegram.configured? ? Notifiers::Console.new : Notifiers::Telegram.new

      names.map do |name|
        pipeline = Radar.build(File.join(ROOT, "config", "#{name}.yml"), store:, notifier:)
        result = pipeline.run(notify: !seed, mark: !dry_run)

        puts "#{name}: #{result.collected} coletados, #{result.matched} no filtro, #{result.fresh} novos"
        result.failures.each { |failure| warn "  falha: #{failure}" }
        result.failures.empty?
      end.all? ? 0 : 1
    end
  end
end
