class DataStore4KVObjects

    # datastore4-kv-objects.sqlite3
    # create table _objects_ (_key_ text, _object_ text, _unixtime_ float)

    # DataStore4KVObjects::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/datastore4-kv-objects.sqlite3"
    end

    # DataStore4KVObjects::getObjectOrNull(key)
    def self.getObjectOrNull(key)
        db = SQLite3::Database.new(DataStore4KVObjects::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        object = nil
        db.execute("select * from _objects_ where _key_=?", [key]) do |row|
            object = JSON.parse(row["_object_"])
        end
        db.close
        object
    end

    # DataStore4KVObjects::setObject(key, object)
    def self.setObject(key, object)
        db = SQLite3::Database.new(DataStore4KVObjects::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _objects_ where _key_=?", [key]
        db.execute "insert into _objects_ (_key_, _object_, _unixtime_) values (?, ?, ?)", [key, JSON.generate(object), Time.new.to_f]
        db.close
        SystemEvents::broadcast({
            "mikuType"  => "datastore4-kv-object-set",
            "key"       => key,
            "object"    => object,
        })
        nil
    end
end
