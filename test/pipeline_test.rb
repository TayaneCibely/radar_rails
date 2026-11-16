require "minitest/autorun"
require "radar"

class PipelineTest < Minitest::Test
  FakeSource = Struct.new(:items) do
    def fetch = items
  end

  class BrokenSource
    def fetch = raise("fora do ar")
  end

  class Recorder
    attr_reader :delivered

    def initialize = @delivered = []
    def deliver(_bot, item) = @delivered << item
  end

  def setup
    @store = Radar::Store.new(":memory:")
    @notifier = Recorder.new
    @vaga = Radar::Item.new(source: "teste", key: "1", title: "Dev Rails Jr", url: "https://exemplo.test/1")
  end

  def pipeline(*sources, name: "vagas")
    Radar::Pipeline.new(name:, sources:, filter: Radar::Filters::Keyword.new, store: @store, notifier: @notifier)
  end

  def test_notifica_item_novo_uma_unica_vez
    2.times { pipeline(FakeSource.new([@vaga])).run }

    assert_equal [@vaga], @notifier.delivered
  end

  def test_mesmo_item_em_duas_fontes_conta_uma_vez
    result = pipeline(FakeSource.new([@vaga]), FakeSource.new([@vaga])).run

    assert_equal 1, result.fresh
  end

  def test_fonte_com_erro_nao_derruba_as_outras
    result = pipeline(BrokenSource.new, FakeSource.new([@vaga])).run

    assert_equal [@vaga], @notifier.delivered
    assert_equal 1, result.failures.size
  end

  def test_seed_marca_sem_notificar
    pipeline(FakeSource.new([@vaga])).run(notify: false)
    pipeline(FakeSource.new([@vaga])).run

    assert_empty @notifier.delivered
  end

  def test_dry_run_nao_marca
    pipeline(FakeSource.new([@vaga])).run(mark: false)

    refute @store.seen?("vagas", @vaga.uid)
  end

  def test_cada_bot_tem_sua_propria_memoria
    pipeline(FakeSource.new([@vaga]), name: "vagas").run
    pipeline(FakeSource.new([@vaga]), name: "editais").run

    assert_equal 2, @notifier.delivered.size
  end
end
