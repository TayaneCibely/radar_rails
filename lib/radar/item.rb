module Radar
  # Formato único que toda fonte devolve: vaga, edital ou qualquer outra coisa.
  Item = Struct.new(:source, :key, :title, :url, :body, :tags, keyword_init: true) do
    # Identidade usada para não notificar o mesmo item duas vezes.
    def uid = "#{source}:#{key}"

    # Texto completo em que o filtro procura as palavras-chave.
    def text = [title, body, *tags].compact.join(" ")

    # Só o que o autor escolheu destacar: título e etiquetas.
    def headline = [title, *tags].compact.join(" ")
  end
end
