require "json"
require "net/http"
require "uri"

module Radar
  module Http
    Error = Class.new(StandardError)

    USER_AGENT = "radar-bot".freeze

    def self.get(url, headers: {}, redirects: 5)
      raise Error, "redirecionamentos demais em #{url}" if redirects.zero?

      uri = URI(url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                                     open_timeout: 10, read_timeout: 20) do |http|
        http.get(uri.request_uri, { "User-Agent" => USER_AGENT }.merge(headers))
      end

      case response
      when Net::HTTPSuccess then response.body
      when Net::HTTPRedirection
        get(URI.join(url, response["location"]).to_s, headers:, redirects: redirects - 1)
      else raise Error, "HTTP #{response.code} em #{url}"
      end
    end

    # Devolve o código de status; quem chama decide o que é erro
    # (a URL pode conter segredo, então ela não entra em mensagem nenhuma aqui).
    def self.post_json(url, payload)
      Net::HTTP.post(URI(url), payload.to_json, "Content-Type" => "application/json").code.to_i
    end
  end
end
