
class Blades

    # Blades::respository()
    def self.respository()
        "#{Config::pathToGalaxy()}/DataHub/First-Light-Weaves-Living-Song/blades"
    end

    # Blades::ensureBlade(bladeuuid)
    def self.ensureBlade(bladeuuid)
        filepath = "#{Blades::respository()}/#{bladeuuid}.blade"
        return if File.exist?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("CREATE TABLE datablobs (key TEXT PRIMARY KEY, datablob BLOB);", [])
        db.commit
        db.close
    end

    # Blades::putBlob(bladeuuid, datablob) # nhash
    def self.putBlob(bladeuuid, datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        Blades::ensureBlade(bladeuuid)
        filepath = "#{Blades::respository()}/#{bladeuuid}.blade"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("INSERT OR REPLACE INTO datablobs (key, datablob) VALUES (?, ?)", [nhash, datablob])
        db.commit
        db.close
        nhash
    end

    # Blades::getBlobOrNull(bladeuuid, nhash)
    def self.getBlobOrNull(bladeuuid, nhash) # data | nil
        filepath = "#{Blades::respository()}/#{bladeuuid}.blade"
        return nil if File.exist?(filepath)
        datablob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from datablobs where key=?", [nhash]) do |row|
            datablob = row["datablob"]
        end
        db.close
        datablob
    end
end
