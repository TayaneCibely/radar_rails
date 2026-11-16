require "fileutils"
require "sqlite3"
require "time"

module Radar
  # Memória do bot: quais itens já foram notificados.
  class Store
    def initialize(path)
      FileUtils.mkdir_p(File.dirname(path)) unless path == ":memory:"
      @db = SQLite3::Database.new(path)
      @db.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS seen (
          bot     TEXT NOT NULL,
          uid     TEXT NOT NULL,
          seen_at TEXT NOT NULL,
          PRIMARY KEY (bot, uid)
        )
      SQL
    end

    def seen?(bot, uid)
      !@db.get_first_value("SELECT 1 FROM seen WHERE bot = ? AND uid = ?", [bot, uid]).nil?
    end

    def mark(bot, uid)
      @db.execute("INSERT OR IGNORE INTO seen (bot, uid, seen_at) VALUES (?, ?, ?)",
                  [bot, uid, Time.now.utc.iso8601])
    end
  end
end
