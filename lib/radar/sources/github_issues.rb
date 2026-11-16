require "json"
require "uri"

module Radar
  module Sources
    # Repositórios que publicam vagas como issues (ex.: backend-br/vagas).
    class GithubIssues
      def initialize(repo:, labels: [], per_page: 50)
        @repo = repo
        @labels = Array(labels)
        @per_page = per_page
      end

      def fetch
        query = URI.encode_www_form(state: "open", labels: @labels.join(","), per_page: @per_page)
        issues = JSON.parse(Http.get("https://api.github.com/repos/#{@repo}/issues?#{query}", headers:))

        # A API devolve pull requests junto com as issues.
        issues.reject { |issue| issue.key?("pull_request") }.map do |issue|
          Item.new(source: "github:#{@repo}", key: issue["number"].to_s, title: issue["title"],
                   url: issue["html_url"], body: issue["body"],
                   tags: issue["labels"].map { |label| label["name"] })
        end
      end

      private

      # Sem token funciona, mas com limite de 60 requisições por hora.
      def headers
        token = ENV["GITHUB_TOKEN"].to_s
        base = { "Accept" => "application/vnd.github+json" }
        token.empty? ? base : base.merge("Authorization" => "Bearer #{token}")
      end
    end
  end
end
