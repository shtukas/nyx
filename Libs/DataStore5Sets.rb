class DataStore5Sets

    # datastore5-sets.sqlite3
    # create table _sets_ (_setuuid_ text, _itemuuid_ text)

    # DataStore5Sets::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/datastore5-sets.sqlite3"
    end

    # DataStore5Sets::itemuuids(setuuid)
    def self.itemuuids(setuuid)
        db = SQLite3::Database.new(DataStore5Sets::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        itemuuids = []
        db.execute("select * from _sets_ where _setuuid_=?", [setuuid]) do |row|
            itemuuids << row["_itemuuid_"]
        end
        db.close
        itemuuids
    end

    # DataStore5Sets::add(setuuid, itemuuid)
    def self.add(setuuid, itemuuid)
        db = SQLite3::Database.new(DataStore5Sets::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _sets_ where _setuuid_=? and _itemuuid_=?", [setuuid, itemuuid]
        db.execute "insert into _sets_ (_setuuid_, _itemuuid_) values (?, ?)", [setuuid, itemuuid]
        db.close
        SystemEvents::broadcast({
            "mikuType" => "datastore5-add",
            "setuuid"  => setuuid,
            "itemuuid" => itemuuid,
        })
        nil
    end

    # DataStore5Sets::remove(setuuid, itemuuid)
    def self.remove(setuuid, itemuuid)
        db = SQLite3::Database.new(DataStore5Sets::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _sets_ where _setuuid_=? and _itemuuid_=?", [setuuid, itemuuid]
        db.close
        SystemEvents::broadcast({
            "mikuType" => "datastore5-remove",
            "setuuid"  => setuuid,
            "itemuuid" => itemuuid,
        })
        nil
    end
end
