
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

    # Librarian::commit(object)
    def self.commit(object)

        raise "(error: b18a080c-af1b-4411-bf65-1b528edc6121, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 09e002e4-71a2-448a-82e6-f2a7f949f40d, incorrect datetime)" if (object["datetime"] and !CommonUtils::isDateTime_UTC_ISO8601(object["datetime"]))

        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        db.close
    end
end
