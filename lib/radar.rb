require "yaml"

require_relative "radar/item"
require_relative "radar/http"
require_relative "radar/store"
require_relative "radar/pipeline"
require_relative "radar/filters/keyword"
require_relative "radar/sources/github_issues"
require_relative "radar/sources/rss"
require_relative "radar/sources/page_watch"
require_relative "radar/sources/json_api"
require_relative "radar/notifiers/console"
require_relative "radar/notifiers/telegram"
require_relative "radar/cli"

module Radar
  # Para criar uma fonte nova: escreva a classe em sources/ e registre aqui.
  SOURCES = {
    "github_issues" => Sources::GithubIssues,
    "rss" => Sources::Rss,
    "page_watch" => Sources::PageWatch,
    "json_api" => Sources::JsonApi
  }.freeze

  # Monta um bot (pipeline) a partir de um arquivo config/<bot>.yml.
  def self.build(config_path, store:, notifier:)
    config = YAML.load_file(config_path)
    sources = Array(config["sources"]).map do |source|
      SOURCES.fetch(source.fetch("type")).new(**symbolize(source.except("type")))
    end
    filter = Filters::Keyword.new(**symbolize(config.fetch("filter", {})))

    Pipeline.new(name: config.fetch("name"), sources:, filter:, store:, notifier:)
  end

  def self.symbolize(hash) = hash.transform_keys(&:to_sym)
end
