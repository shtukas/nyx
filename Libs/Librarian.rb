
# encoding: UTF-8

class Librarian

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::pathToDatabaseFile()
    def self.pathToDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/objects-store.sqlite3"
    end

    # Librarian::objects()
    def self.objects()
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_", []) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_ where _mikuType_=?", [mikuType]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # Librarian::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            answer = JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # ---------------------------------------------------
    # Objects Writing

    # Librarian::objectHasBeenCommitted(object)
    def self.objectHasBeenCommitted(object)

        # If that object was in the TxTodo cache, we update it there.
        if object["mikyType"] == "TxTodo" then
            if XCacheSets::getOrNull(TxTodos::cacheLocation(), object["uuid"]) then
                XCacheSets::set(TxTodos::cacheLocation(), item["uuid"], item)
            end
        end
    end

    # Librarian::commit(object)
    def self.commit(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 3c0e7684-44fd-4c1d-92b9-bbc5bb15d4ba, incorrect datetime)" if (object["datetime"] and !CommonUtils::isDateTime_UTC_ISO8601(object["datetime"]))

        if object["lxHistory"].nil? then
            object["lxHistory"] = []
        end

        object["lxHistory"] << SecureRandom.uuid

        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
    end

    # Librarian::commitWithoutUpdates(object)
    def self.commitWithoutUpdates(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 3c0e7684-44fd-4c1d-92b9-bbc5bb15d4ba, incorrect datetime)" if (object["datetime"] and !CommonUtils::isDateTime_UTC_ISO8601(object["datetime"]))

        raise "(error: 9fd3f77b-25a5-4fc1-b481-074f4d5444ce, missing attribute lxHistory)" if object["lxHistory"].nil?
        
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
    end

    # Librarian::objectIsAboutToBeDeleted(object)
    def self.objectIsAboutToBeDeleted(object)

        # If that object was in the TxTodo cache, we delete it.
        if object["mikyType"] == "TxTodo" then
            XCacheSets::destroy(TxTodos::cacheLocation(), object["uuid"])
        end
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        if object = Librarian::getObjectByUUIDOrNull(uuid) then
            Librarian::objectIsAboutToBeDeleted(object)
        end

        object = {
            "uuid"     => uuid,
            "mikuType" => "NxDeleted",
            "unixtime" => Time.new.to_i,
            "datetime" => Time.new.utc.iso8601,
        }
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
    end
end
