
# encoding: UTF-8

require 'sqlite3'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::readFirstValueOrNull(channel)
    Mercury::dequeueFirstValueOrNull(channel)
    Mercury::isEmpty(channel)
=end

class LocalObjectsStore

    # LocalObjectsStore::pathToObjectsStoreDatabase()
    def self.pathToObjectsStoreDatabase()
        "/Users/pascal/Galaxy/DataBank/Didact/objects-store.sqlite3"
    end

    # ---------------------------------------------------
    # Reading

    # LocalObjectsStore::objects()
    def self.objects()
        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        objects = []
        db.execute("select * from _objects_ order by _ordinal_", []) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects.select{|object| !object["lxDeleted"] }
    end

    # LocalObjectsStore::objectsIncludingLogicallyDeleted()
    def self.objectsIncludingLogicallyDeleted()
        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
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

    # LocalObjectsStore::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        objects = []
        db.execute("select * from _objects_ where _mikuType_=? order by _ordinal_", [mikuType]) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects.select{|object| !object["lxDeleted"] }
    end

    # LocalObjectsStore::getObjectsByMikuTypeAndUniverse(mikuType, universe)
    def self.getObjectsByMikuTypeAndUniverse(mikuType, universe)
        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        objects = []
        db.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_", [mikuType, universe]) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects.select{|object| !object["lxDeleted"] }
    end

    # LocalObjectsStore::getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
    def self.getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        objects = []
        db.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_ limit ?", [mikuType, universe, n]) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects.select{|object| !object["lxDeleted"] }
    end

    # LocalObjectsStore::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        object = nil
        db.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            object = JSON.parse(row['_object_'])
            if object["lxDeleted"] then
                object = nil
            end
        end
        db.close
        object
    end

    # LocalObjectsStore::getObjectIncludedLogicallyDeletedByUUIDOrNull(uuid)
    def self.getObjectIncludedLogicallyDeletedByUUIDOrNull(uuid)
        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
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
    # Writing

    # LocalObjectsStore::commit(object)
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

        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }

        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), object["ordinal"], object["universe"]]

        db.close
    end

    # LocalObjectsStore::commitWithoutUpdates(object)
    def self.commitWithoutUpdates(object)
        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        raise "(error: 7fb476dc-94ce-4ef9-8253-04776dd550fb, missing attribute ordinal)" if object["ordinal"].nil?
        raise "(error: bcc0e0f0-b4cf-4815-ae70-0c4cf834bf8f, missing attribute universe)" if object["universe"].nil?
        raise "(error: 9fd3f77b-25a5-4fc1-b481-074f4d5444ce, missing attribute lxHistory)" if object["lxHistory"].nil?

        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }

        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), object["ordinal"], object["universe"]]

        db.close
    end

    # LocalObjectsStore::objectIsAboutToBeLogicallyDeleted(object)
    def self.objectIsAboutToBeLogicallyDeleted(object)
        if object["iam"] and object["iam"]["type"] == "Dx8Unit" then
            unitId = object["iam"]["unitId"]
            location = Dx8UnitsUtils::dx8UnitFolder(unitId)
            if File.exists?(location) then
                LucilleCore::removeFileSystemLocation(location)
            else
                # (comment group: 5ade8f50-4e5d-48f6-a892-9e1cb540efe6)
                puts "Scheduling Dx8UnitId: #{unitId} for later deletion"
                Mercury::postValue("434BAAEC-EBA5-46AE-990E-85C86888A9D7", unitId)
            end
        end
    end

    # LocalObjectsStore::logicaldelete(uuid)
    def self.logicaldelete(uuid)
        object = LocalObjectsStore::getObjectByUUIDOrNull(uuid)
        return if object.nil?
        Mercury::postValue("2d70b692-49f0-4a11-85a9-c378537f8ef1", uuid) # object deletion message for ListingDataDriver
        LocalObjectsStore::objectIsAboutToBeLogicallyDeleted(object)
        object["lxHistory"] << SecureRandom.uuid
        object["lxDeleted"] = true
        LocalObjectsStore::commit(object)
    end

    # LocalObjectsStore::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        db.close
    end
end
