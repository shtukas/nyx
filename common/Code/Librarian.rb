
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
        objects.select{|object| !object["lxDeleted"] }
    end

    # Librarian::objectsIncludingLogicallyDeleted()
    def self.objectsIncludingLogicallyDeleted()
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
        objects.select{|object| !object["lxDeleted"] }
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
        objects.select{|object| !object["lxDeleted"] }
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
        objects.select{|object| !object["lxDeleted"] }
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
            if object["lxDeleted"] then
                object = nil
            end
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

    # Librarian::objectIsAboutToBeLogicallyDeleted(object)
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

    # Librarian::logicaldelete(uuid)
    def self.logicaldelete(uuid)
        object = Librarian::getObjectByUUIDOrNull(uuid)
        return if object.nil?
        Mercury::postValue("2d70b692-49f0-4a11-85a9-c378537f8ef1", uuid) # object deletion message for ListingDataDriver
        Librarian::objectIsAboutToBeLogicallyDeleted(object)
        object["lxDeleted"] = true
        Librarian::commit(object)
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
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

    # ---------------------------------------------------
    # Datablobs

    # Librarian::putBlob(blob)
    def self.putBlob(blob)
        XCacheDatablobs::putBlob(blob)
    end

    # Librarian::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)

        # We first try XCache
        puts "reading #{nhash} from xcache"
        blob = XCacheDatablobs::getBlobOrNull(nhash)
        return blob if blob

        # Then we look up the drive
        puts "reading #{nhash} from the drive"
        filepath = "/Volumes/Infinity/Data/Pascal/Librarian/DatablobsDepth2/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        puts "reading #{nhash} from the drive (#{filepath})"
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            XCacheDatablobs::putBlob(blob)
            return blob
        end

        nil
    end

    # ---------------------------------------------------
    # Datablobs (Fx12)

    # Librarian::putBlobFx12(filepath, blob)
    def self.putBlobFx12(filepath, blob)
        Fx12s::commitBlob(filepath, blob)
    end

    # Librarian::getBlobOrNullFx12(filepath, nhash)
    def self.getBlobOrNullFx12(filepath, nhash)
        Fx12s::getBlobOrNull(filepath, nhash)
    end
end

class LibrarianFx12Elizabeth

    def initialize(uuid)
        @filepath = Librarian::getFx12Filepath(uuid)
    end

    def commitBlob(blob)
        Librarian::putBlobFx12(@filepath, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Librarian::getBlobOrNullFx12(@filepath, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 7ffc6f95-4977-47a2-b9fd-eecd8312ebbe) could not find blob, nhash: #{nhash}"
        raise "(error: 47f74e9a-0255-44e6-bf04-f12ff7786c65, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 479c057e-d77b-4cd9-a6ba-df082e93f6b5) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
