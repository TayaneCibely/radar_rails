require "minitest/autorun"
require "radar"

class FilterTest < Minitest::Test
  def setup
    @filter = Radar::Filters::Keyword.new(all_of: [%w[ruby rails], %w[junior jr]], none_of: %w[senior])
  end

  def item(title, body: nil, tags: nil)
    Radar::Item.new(source: "teste", key: title, title:, body:, tags:)
  end

  def test_ignora_acentos_e_maiusculas
    assert @filter.match?(item("Desenvolvedor RUBY Júnior"))
  end

  def test_exige_um_termo_de_cada_grupo
    refute @filter.match?(item("Desenvolvedor Python Júnior"))
    refute @filter.match?(item("Desenvolvedor Rails"))
  end

  def test_casa_apenas_palavras_inteiras
    refute @filter.match?(item("Rails para o estúdio jrpg"))
  end

  def test_procura_tambem_no_corpo_e_nas_tags
    assert @filter.match?(item("Backend", body: "Stack: Rails", tags: ["Júnior"]))
  end

  def test_none_of_olha_so_o_titulo
    assert @filter.match?(item("Dev Rails Jr", body: "Você terá apoio de um dev sênior"))
    refute @filter.match?(item("Dev Rails Sênior ou Jr"))
  end

  def test_headline_all_of_ignora_o_corpo
    filter = Radar::Filters::Keyword.new(all_of: [%w[rails]], headline_all_of: [%w[junior jr]])

    refute filter.match?(item("Editor assistente", body: "Rails. Você vai orientar devs júnior"))
    assert filter.match?(item("Dev Jr", body: "Stack: Rails"))
    assert filter.match?(item("Dev backend", body: "Stack: Rails", tags: ["Júnior"]))
  end

  def test_sem_regras_aceita_tudo
    assert Radar::Filters::Keyword.new.match?(item("qualquer coisa"))
  end
end
