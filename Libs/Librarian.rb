
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

        raise "(error: b18a080c-af1b-4411-bf65-1b528edc6121, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 09e002e4-71a2-448a-82e6-f2a7f949f40d, incorrect datetime)" if (object["datetime"] and !CommonUtils::isDateTime_UTC_ISO8601(object["datetime"]))

        if object["lxHistory"].nil? then
            object["lxHistory"] = []
        end

        object["lxHistory"] << SecureRandom.uuid

        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close

        SyncEventSpecific::postObjectUpdateEvent(object, Machines::theOtherMachine())
    end

    # Librarian::commitWithoutUpdates(object)
    def self.commitWithoutUpdates(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 3c0e7684-44fd-4c1d-92b9-bbc5bb15d4ba, incorrect datetime)" if (object["datetime"] and !CommonUtils::isDateTime_UTC_ISO8601(object["datetime"]))

        if object["mikuType"] != "NxDeleted" then
            raise "(error: 9fd3f77b-25a5-4fc1-b481-074f4d5444ce, missing attribute lxHistory)" if object["lxHistory"].nil?
        end

        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close


        SyncEventSpecific::postObjectUpdateEvent(object, Machines::theOtherMachine())
    end

    # Librarian::commitWithoutUpdatesNoEvents(object)
    def self.commitWithoutUpdatesNoEvents(object)

        raise "(error: edeebbed-b445-43f3-9aa2-6c3879feeabc, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: e412b7f9-08fe-4c87-85b5-8de584d050c3, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 67d7e579-95c4-4a11-836d-82e3bfb7c0b3, incorrect datetime)" if (object["datetime"] and !CommonUtils::isDateTime_UTC_ISO8601(object["datetime"]))

        if object["mikuType"] != "NxDeleted" then
            raise "(error: 842c14b5-102e-41b8-9575-2f0d795a6b00, missing attribute lxHistory)" if object["lxHistory"].nil?
        end
        
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

        SyncEventSpecific::postObjectUpdateEvent(object, Machines::theOtherMachine())
    end
end
