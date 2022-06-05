
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
        db.execute("select * from _objects_ order by _ordinal_", []) do |row|
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
        db.execute("select * from _objects_ where _mikuType_=? order by _ordinal_", [mikuType]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # Librarian::getObjectsByMikuTypeAndUniverse(mikuType, universe)
    def self.getObjectsByMikuTypeAndUniverse(mikuType, universe)
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_", [mikuType, universe]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # Librarian::getObjectsByMikuTypeAndUniverseLimit(mikuType, universe, n)
    def self.getObjectsByMikuTypeAndUniverseLimit(mikuType, universe, n)
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_ limit ?", [mikuType, universe, n]) do |row|
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

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 3c0e7684-44fd-4c1d-92b9-bbc5bb15d4ba, incorrect datetime)" if (object["datetime"] and !CommonUtils::isDateTime_UTC_ISO8601(object["datetime"]))

        if object["ordinal"].nil? then
            object["ordinal"] = 0
        end

        if object["universe"].nil? then
            object["universe"] = "backlog"
        end

        if object["lxHistory"].nil? then
            object["lxHistory"] = []
        end

        object["lxHistory"] << SecureRandom.uuid

        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?, ?, ?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object), object["ordinal"], object["universe"]]
        db.close
    end

    # Librarian::commitWithoutUpdates(object)
    def self.commitWithoutUpdates(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 3c0e7684-44fd-4c1d-92b9-bbc5bb15d4ba, incorrect datetime)" if (object["datetime"] and !CommonUtils::isDateTime_UTC_ISO8601(object["datetime"]))

        raise "(error: 7fb476dc-94ce-4ef9-8253-04776dd550fb, missing attribute ordinal)" if object["ordinal"].nil?
        raise "(error: bcc0e0f0-b4cf-4815-ae70-0c4cf834bf8f, missing attribute universe)" if object["universe"].nil?
        raise "(error: 9fd3f77b-25a5-4fc1-b481-074f4d5444ce, missing attribute lxHistory)" if object["lxHistory"].nil?
        
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?, ?, ?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object), object["ordinal"], object["universe"]]
        db.close
    end

    # Librarian::objectIsAboutToBeDestroyed(object)
    def self.objectIsAboutToBeDestroyed(object)
        if object["i1as"] then
            object["i1as"].each{|nx111|
                if nx111["type"] == "Dx8Unit" then
                    unitId = nx111["unitId"]
                    location = Dx8UnitsUtils::dx8UnitFolder(unitId)
                    puts "removing Dx8Unit folder: #{location}"
                    LucilleCore::removeFileSystemLocation(location)
                end
            }
        end
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        if object = Librarian::getObjectByUUIDOrNull(uuid) then
            Librarian::objectIsAboutToBeDestroyed(object)
        end

        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        db.close
    end
end
