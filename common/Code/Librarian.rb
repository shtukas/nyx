
# encoding: UTF-8

class Librarian

    # --------------------------------------------------
    # Fx12

    # Librarian::pathToFx12sRepository()
    def self.pathToFx12sRepository()
        "#{Config::pathToDataBankCatalyst()}/Fx12s"
    end

    # Librarian::getFx12Filepath(uuid)
    def self.getFx12Filepath(uuid)
        hash1 = Digest::SHA1.hexdigest(uuid)
        folderpath = "#{Librarian::pathToFx12sRepository()}/#{hash1[0, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        "#{folderpath}/#{uuid}.fx12"
    end

    # Librarian::commitObjectToFx12File(object)
    def self.commitObjectToFx12File(object)
        filepath = Librarian::getFx12Filepath(object["uuid"])
        Fx12s::kvstore_set(filepath, "object", JSON.generate(object))
    end

    # ---------------------------------------------------
    # Objects

    # Librarian::pathToObjectsStoreDatabase()
    def self.pathToObjectsStoreDatabase()
        "#{Config::pathToDataBankCatalyst()}/objects-store.sqlite3"
    end

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::objects()
    def self.objects()
        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        objects = []
        db.execute("select * from _objects_ order by _ordinal_", []) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects
    end

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        objects = []
        db.execute("select * from _objects_ where _mikuType_=? order by _ordinal_", [mikuType]) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects
    end

    # Librarian::getObjectsByMikuTypeAndUniverse(mikuType, universe)
    def self.getObjectsByMikuTypeAndUniverse(mikuType, universe)
        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        objects = []
        db.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_", [mikuType, universe]) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects
    end

    # Librarian::getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
    def self.getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        objects = []
        db.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_ limit ?", [mikuType, universe, n]) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects
    end

    # Librarian::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        object = nil
        db.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            object = JSON.parse(row['_object_'])
        end
        db.close
        object
    end

    # Librarian::getObjectIncludedLogicallyDeletedByUUIDOrNull(uuid)
    def self.getObjectIncludedLogicallyDeletedByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        object = nil
        db.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            object = JSON.parse(row['_object_'])
        end
        db.close
        object
    end

    # ---------------------------------------------------
    # Objects Writing

    # Librarian::commit(object)
    def self.commit(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

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

        Librarian::commitObjectToFx12File(object)

        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }

        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), object["ordinal"], object["universe"]]

        db.close
    end

    # Librarian::commitWithoutUpdates(object)
    def self.commitWithoutUpdates(object)
        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 7fb476dc-94ce-4ef9-8253-04776dd550fb, missing attribute ordinal)" if object["ordinal"].nil?
        raise "(error: bcc0e0f0-b4cf-4815-ae70-0c4cf834bf8f, missing attribute universe)" if object["universe"].nil?
        raise "(error: 9fd3f77b-25a5-4fc1-b481-074f4d5444ce, missing attribute lxHistory)" if object["lxHistory"].nil?

        Librarian::commitObjectToFx12File(object)

        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }

        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), object["ordinal"], object["universe"]]

        db.close
    end

    # Librarian::objectIsAboutToBeDestroyed(object)
    def self.objectIsAboutToBeDestroyed(object)
        if object["i1as"] then
            object["i1as"].each{|nx111|
                nx111["type"] == "Dx8Unit"
                unitId = nx111["unitId"]
                location = Dx8UnitsUtils::dx8UnitFolder(unitId)
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)

        if object = Librarian::getObjectByUUIDOrNull(uuid) then
            Librarian::objectIsAboutToBeDestroyed(object)
        end

        filepath = Librarian::getFx12Filepath(uuid)
        if File.exists?(filepath) then
            puts "removing file: #{filepath}"
            FileUtils.rm(filepath)
        end

        db = SQLite3::Database.new(Librarian::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        db.close
    end
end
