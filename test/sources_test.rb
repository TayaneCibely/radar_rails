require "minitest/autorun"
require "radar"

class SourcesTest < Minitest::Test
  FIELDS = { "key" => "id", "title" => %w[position company], "url" => "url",
             "body" => "description", "tags" => "tags" }.freeze

  def test_json_api_mapeia_campos_e_ignora_entrada_sem_chave
    source = Radar::Sources::JsonApi.new(url: "https://exemplo.test", name: "api", fields: FIELDS)
    json = [{ "legal" => "aviso" },
            { "id" => 7, "position" => "Rails Dev", "company" => "Acme", "url" => "https://exemplo.test/7",
              "description" => "Vaga júnior", "tags" => ["ruby"] }].to_json

    items = source.parse(json)

    assert_equal 1, items.size
    assert_equal "api:api:7", items.first.uid
    assert_equal "Rails Dev - Acme", items.first.title
    assert_equal ["ruby"], items.first.tags
  end

  def test_json_api_le_lista_dentro_de_uma_chave
    source = Radar::Sources::JsonApi.new(url: "https://exemplo.test", name: "api", items: "jobs",
                                         fields: FIELDS.merge("title" => "position"))

    items = source.parse({ "jobs" => [{ "id" => "1", "position" => "Dev", "url" => "u" }] }.to_json)

    assert_equal ["Dev"], items.map(&:title)
    assert_empty items.first.tags
  end

  def test_page_watch_separa_textos_e_resolve_links
    source = Radar::Sources::PageWatch.new(url: "https://exemplo.test/vagas", name: "site", selector: ".vaga a[href]")
    html = <<~HTML
      <a href="/fora">Fora do seletor</a>
      <div class="vaga"><a href="/jobs/1"><h3>Dev Rails</h3><span>Júnior</span><span>PJ</span></a></div>
      <div class="vaga"><a href="#topo">Âncora</a><a href="/jobs/1">Repetido</a></div>
    HTML

    items = source.parse(html)

    assert_equal ["https://exemplo.test/jobs/1"], items.map(&:url)
    assert_equal "Dev Rails Júnior PJ", items.first.title
  end
end
