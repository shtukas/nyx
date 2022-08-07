
# encoding: UTF-8

class DxPure

    # DxPure::makeNewPureFile(filepath)
    def self.makeNewPureFile(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _dx_ (_key_ text primary key, _value_ blob)", [])
        db.close
    end

    # DxPure::insertIntoPure(filepath, key, value)
    def self.insertIntoPure(filepath, key, value)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from _dx_ where _key_=?", [key])
        db.execute("insert into _dx_ (_key_, _value_) values (?, ?)", [key, value])
        db.close
    end

    # DxPure::toString(sha1)
    def self.toString(sha1)
        
    end

    # DxPure::access(sha1)
    def self.access(sha1)
        
    end
end
