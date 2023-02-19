
class NxOrbital

    # NxOrbital.new(filepath)
    def initialize(filepath)
         @filepath= filepath
    end

    # ----------------------------------------------------
    # Generic IO

    def get(key)
        data = nil
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from orbital where _key_=?", [key]) do |row|
            data = row["_data_"]
        end
        db.close
        data
    end

    def set(key, data)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from orbital where _key_=?", [key]
        db.execute "insert into orbital (_key_, _data_) values (?, ?)", [key, data]
        db.close
    end

    def collection_get(cname)
        records = []
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from orbital where _collection_=?", [cname]) do |row|
            records << {
                "key"        => row["_key_"],
                "collection" => row["_collection_"],
                "data"       => row["_data_"],
            }
        end
        db.close
        records
    end

    def collection_add(key, collection, data)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from orbital where _key_=?", [key]
        db.execute "insert into orbital (_key_, _collection_, _data_) values (?, ?, ?)", [key, collection, data]
        db.close
    end

    def collection_remove(key)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from orbital where _key_=?", [key]
        db.close
    end

    # ----------------------------------------------------
    # Convenience Getters

    def uuid()
        self.get("uuid")
    end

    def unixtime()
        self.get("unixtime")
    end

    def toString()
        "(orbital) #{self.get("description")}"
    end

    def coredataref()
        self.get("coredataref")
    end

    # ----------------------------------------------------
    # Convenience Setters

    def coredataref_set(coredataref)
        self.set("coredataref", coredataref)
    end

end
