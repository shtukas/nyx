
# encoding: UTF-8

class Librarian

    # Librarian::knownMikuTypes()
    def self.knownMikuTypes()
        [
            "Ax1Text",
            "NxAnniversary",
            "NxArrow",
            "NxBankOp",
            "NxCollection",
            "NxDataNode",
            "NxDNSU",
            "NxFrame",
            "NxPerson",
            "NxRelation",
            "NxShip",
            "NxTimeline",
            "TxDated",
            "TxTodo",
            "Wave"
        ]
    end

    # Librarian::pathToDatabaseFile()
    def self.pathToDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/objects.sqlite3"
    end

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        #puts "Librarian::getObjectsByMikuType(#{mikuType})"
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

    # Librarian::commitNoEvent(object)
    def self.commitNoEvent(object)
        raise "(error: b18a080c-af1b-4411-bf65-1b528edc6121, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?

        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
    end

    # Librarian::commit(object)
    def self.commit(object)
        Librarian::commitNoEvent(object)
        LocalEventLogBufferOut::issueEventForObject(object)
    end

    # --------------------------------------------------------------
    # Object destroy

    # Librarian::destroyNoEvent(uuid)
    def self.destroyNoEvent(uuid)
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.close
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyNoEvent(uuid)
        object = {
            "uuid"     => uuid,
            "mikuType" => "NxDeleted",
        }
        LocalEventLogBufferOut::issueEventForObject(object)
    end

    # --------------------------------------------------------------
    # Incoming Events

    # Librarian::incomingEventFromOutside(event)
    def self.incomingEventFromOutside(event)
        if event["mikuType"] == "NxDeleted" then
            Librarian::destroyNoEvent(event["uuid"])
            return
        end
        Librarian::commitNoEvent(object)
    end
end
