
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'find'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/XCache.rb"
=begin
    XCache::setFlagTrue(key)
    XCache::setFlagFalse(key)
    XCache::flagIsTrue(key)

    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)
=end

# ------------------------------------------------------------------------

class Librarian0Utils

    # Librarian0Utils::filepathToContentHash(filepath) # nhash
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # Librarian0Utils::openUrlUsingSafari(url)
    def self.openUrlUsingSafari(url)
        system("open -a Safari '#{url}'")
    end

    # Librarian0Utils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = "#{SecureRandom.uuid}.txt"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # Librarian0Utils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # Librarian0Utils::atlas(pattern)
    def self.atlas(pattern)
        location = `/Users/pascal/Galaxy/LucilleOS/Binaries/atlas '#{pattern}'`.strip
        (location != "") ? location : nil
    end

    # Librarian0Utils::interactivelySelectDesktopLocationOrNull() 
    def self.interactivelySelectDesktopLocationOrNull()
        entries = Dir.entries("/Users/pascal/Desktop").select{|filename| !filename.start_with?(".") }.sort
        locationNameOnDesktop = LucilleCore::selectEntityFromListOfEntitiesOrNull("locationname", entries)
        return nil if locationNameOnDesktop.nil?
        "/Users/pascal/Desktop/#{locationNameOnDesktop}"
    end

    # Librarian0Utils::moveFileToBinTimeline(location)
    def self.moveFileToBinTimeline(location)
        return if !File.exists?(location)
        directory = "/Users/pascal/x-space/bin-timeline/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(directory)
        FileUtils.mv(location, directory)
    end

    # Librarian0Utils::commitFileToXCacheReturnPartsHashs(filepath)
    def self.commitFileToXCacheReturnPartsHashs(filepath)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)
        hashes = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            hashes << Librarian2DatablobsXCache::putBlob(blob)
        end
        f.close()
        hashes
    end

    # Librarian0Utils::uniqueStringLocationUsingFileSystemSearchOrNull(uniquestring)
    def self.uniqueStringLocationUsingFileSystemSearchOrNull(uniquestring)
        roots = [
            "/Users/pascal/Desktop"
        ]
        roots.each{|root|
            Find.find(root) do |path|
                if File.basename(path).downcase.include?(uniquestring.downcase) then
                    return path
                end
            end
        }
        nil
    end
end

class Librarian2DatablobsXCache

    # Librarian2DatablobsXCache::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set("FAF57B05-2EF0-4F49-B1C8-9E73D03939DE:#{nhash}", blob)
        nhash
    end

    # Librarian2DatablobsXCache::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        XCache::getOrNull("FAF57B05-2EF0-4F49-B1C8-9E73D03939DE:#{nhash}")
    end
end

class Librarian3ElizabethXCache

    def initialize()
    end

    def commitBlob(blob)
        Librarian2DatablobsXCache::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = Librarian2DatablobsXCache::getBlobOrNull(nhash)
        return blob if blob
        puts "(error: c052116a-dd92-47a8-88e4-22d7516863d1) could not find blob, nhash: #{nhash}"
        raise "(error: 521d8f17-a958-44ba-97c2-ffacbbca9724, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 4a667893-8d05-4bae-8ea8-d415066ac443) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class Librarian7ObjectsInfinity

    # Librarian7ObjectsInfinity::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::pathToInfinityDidactDataBankType1()}/objects.sqlite3"
    end

    # ------------------------------------------------------------------------
    # Below: Public Interface

    # Librarian7ObjectsInfinity::objects()
    def self.objects()
        db = SQLite3::Database.new(Librarian7ObjectsInfinity::databaseFilepath())
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
end

# ---------------------------------------------------------------------------
# 
# ---------------------------------------------------------------------------

class Librarian17Carriers

    # Librarian17Carriers::getCarrierContents(owneruuid)
    def self.getCarrierContents(owneruuid)
        Librarian19InMemoryObjectDatabase::getObjectsByMikuType("Nx60")
            .select{|claim| claim["owneruuid"] == owneruuid }
            .map{|claim| claim["targetuuid"] }
            .map{|uuid| Librarian19InMemoryObjectDatabase::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # Librarian17Carriers::addPrimitiveFilesToCarrierOrNothing(uuid)
    def self.addPrimitiveFilesToCarrierOrNothing(uuid)
        uploadFolder = LucilleCore::askQuestionAnswerAsString("upload folder: ")
        if !File.exists?(uploadFolder) then
            puts "This upload folder does not exists!"
            LucilleCore::pressEnterToContinue()
            return
        end
        locations = LucilleCore::locationsAtFolder(uploadFolder)
        # We make a fiirst pass to ensure everything is a file
        status = locations.all?{|location| File.file?(location) }
        if !status then
            puts "The upload folder has elements that are not files!"
            LucilleCore::pressEnterToContinue()
            return
        end
        locations.each{|filepath|
            primitiveFileObject = Nx100s::issuePrimitiveFileFromLocationOrNull(filepath)
            puts "Primitive file:"
            puts JSON.pretty_generate(primitiveFileObject)
            puts "Link: (owner: #{uuid}, file: #{primitiveFileObject["uuid"]})"
            Nx60s::issueClaim(uuid, primitiveFileObject["uuid"])
        }
        puts "Upload completed"
        LucilleCore::pressEnterToContinue()
    end
end

# ---------------------------------------------------------------------------
# 
# ---------------------------------------------------------------------------

class Librarian18ObjectLog

    # Librarian18ObjectLog::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::pathToLocalDidact()}/objects-global-log.sqlite3"
    end

    # Librarian18ObjectLog::logObject(object)
    def self.logObject(object)
        recorduuid = SecureRandom.uuid
        recordtime = Time.new.to_f
        db = SQLite3::Database.new(Librarian18ObjectLog::databaseFilepath())
        db.execute "insert into _objectslog_ (_recorduuid_, _recordtime_, _objectuuid_, _object_) values (?,?,?,?)", [recorduuid, recordtime, object["uuid"], JSON.generate(object)]
        db.close
    end

    # Librarian18ObjectLog::log()
    def self.log()
        db = SQLite3::Database.new(Librarian18ObjectLog::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objectslog_ order by _recordtime_", []) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end
end

$Librarian19InMemoryObjectDatabase = nil
$Librarian19DeletedObjectsUUIDs = []
$Librarian19DeployedSnapshot = nil

class Librarian19InMemoryObjectDatabase

    # Librarian19InMemoryObjectDatabase::createInMemoryDatabase()
    def self.createInMemoryDatabase()
        $Librarian19InMemoryObjectDatabase = SQLite3::Database.new(":memory:")
        $Librarian19InMemoryObjectDatabase.results_as_hash = true
        $Librarian19InMemoryObjectDatabase.busy_timeout = 117
        $Librarian19InMemoryObjectDatabase.busy_handler { |count| true }
        $Librarian19InMemoryObjectDatabase.execute "CREATE TABLE _objects_ (_objectuuid_ text primary key, _mikuType_ text, _object_ text, _ordinal_ float, _universe_ text);"
    end

    # Librarian19InMemoryObjectDatabase::processObjectFromLogStream(object)
    def self.processObjectFromLogStream(object)
        if object["deletion"] then
            $Librarian19DeletedObjectsUUIDs << object["uuid"]
            $Librarian19InMemoryObjectDatabase.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
            return
        end
        if $Librarian19DeletedObjectsUUIDs.include?(object["uuid"]) then
            # The object has already been deleted, so we ignore this one
            return
        end
        ordinal = object["ordinal"] || 0
        $Librarian19InMemoryObjectDatabase.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        $Librarian19InMemoryObjectDatabase.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), ordinal, object["universe"]]
    end

    # Librarian19InMemoryObjectDatabase::loadInMemoryDatabaseFromLog()
    def self.loadInMemoryDatabaseFromLog()
        Librarian19InMemoryObjectDatabase::createInMemoryDatabase()
        Librarian18ObjectLog::log().each{|item|
            Librarian19InMemoryObjectDatabase::processObjectFromLogStream(item)
        }
    end

    # Librarian19InMemoryObjectDatabase::rebuildInMemoryDatabaseFromObjects(objects)
    def self.rebuildInMemoryDatabaseFromObjects(objects)
        Librarian19InMemoryObjectDatabase::createInMemoryDatabase()
        objects.each{|object|
            ordinal = object["ordinal"] || 0
            $Librarian19InMemoryObjectDatabase.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), ordinal, object["universe"]]
        }
    end

    # -----------------------------------------------------------------

    # Librarian19InMemoryObjectDatabase::objects()
    def self.objects()
        answer = []
        $Librarian19InMemoryObjectDatabase.execute("select * from _objects_ order by _ordinal_", []) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryObjectDatabase::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        answer = []
        $Librarian19InMemoryObjectDatabase.execute("select * from _objects_ where _mikuType_=? order by _ordinal_", [mikuType]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryObjectDatabase::getObjectsByMikuTypeAndUniverse(mikuType, universe)
    def self.getObjectsByMikuTypeAndUniverse(mikuType, universe)
        answer = []
        $Librarian19InMemoryObjectDatabase.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_", [mikuType, universe]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryObjectDatabase::getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
    def self.getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
        answer = []
        $Librarian19InMemoryObjectDatabase.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_ limit ?", [mikuType, universe, n]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryObjectDatabase::commit(object)
    def self.commit(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        if Sx01Snapshots::snapshotIsDeployed() then
            puts "We are not expecting to commit objects while a snapshot is deployed".yellow
            puts JSON.pretty_generate(object).yellow
            LucilleCore::pressEnterToContinue()
            puts "Exiting"
            exit
        end

        ordinal = object["ordinal"] || 0
        if object["universe"].nil? then
            object["universe"] = "backlog"
        end

        $Librarian19InMemoryObjectDatabase.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        $Librarian19InMemoryObjectDatabase.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), ordinal, object["universe"]]


        Librarian18ObjectLog::logObject(object)
    end

    # Librarian19InMemoryObjectDatabase::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        answer = nil
        $Librarian19InMemoryObjectDatabase.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            answer = JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryObjectDatabase::destroy(uuid)
    def self.destroy(uuid)
        $Librarian19InMemoryObjectDatabase.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        deletionObject = {
            "uuid"     => uuid,
            "deletion" => true
        }
        Librarian18ObjectLog::logObject(deletionObject)
    end
end

class LibrarianCLI

    # LibrarianCLI::main()
    def self.main()

        if ARGV[0] == "alexandra-infinity-sync" then
            AlexandraDidactSynchronization::run()
            exit
        end

        if ARGV[0] == "fsck@infinity" then
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailure()
            exit
        end

        if ARGV[0] == "alexandra-infinity-sync+fsck@infinity" then
            AlexandraDidactSynchronization::run()
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailure()
            exit
        end

        if ARGV[0] == "reset-fsck-run-hash" then
            fsckrunhash = SecureRandom.hex
            XCache::set("1A07231B-8535-499B-BB2C-89A4EB429F51", fsckrunhash)
            puts "fsck run hash (re)set to #{fsckrunhash}"
            exit
        end

        if ARGV[0] == "show-object" and ARGV[1] then
            uuid = ARGV[1]
            object = Librarian19InMemoryObjectDatabase::getObjectByUUIDOrNull(uuid)
            if object then
                puts JSON.pretty_generate(object)
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not find an object with this uuid"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "edit-object" and ARGV[1] then
            uuid = ARGV[1]
            object = Librarian19InMemoryObjectDatabase::getObjectByUUIDOrNull(uuid)
            if object then
                object = Utils::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                Librarian19InMemoryObjectDatabase::commit(object)
            else
                puts "I could not find an object with this uuid"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "destroy-object-by-uuid-i" then
            uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
            Librarian19InMemoryObjectDatabase::destroy(uuid)
            exit
        end

        if ARGV[0] == "get-blob" and ARGV[1] then
            nhash = ARGV[1]
            blob = InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
            if blob then
                puts blob
            else
                puts "I could not find a blob with nhash: #{nhash}"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "fsck-object" then
            uuid = ARGV[1]
            item = Librarian19InMemoryObjectDatabase::getObjectByUUIDOrNull(uuid)
            if item then
                InfinityDriveFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(item, SecureRandom.hex)
            else
                puts "I could not find an item with this uuid"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "make-system-snapshot" then
            item = Sx01Snapshots::issueNewSnapshotUsingCurrentDatabaseObjects()
            puts JSON.pretty_generate(item)
            exit
        end

        puts "usage:"
        puts "    librarian alexandra-infinity-sync"
        puts "    librarian fsck@infinity"
        puts "    librarian alexandra-infinity-sync+fsck@infinity"
        puts "    librarian make-system-snapshot"
        puts "    librarian get-blob <nhash>"
        puts "    librarian show-object <uuid>"
        puts "    librarian edit-object <uuid>"
        puts "    librarian reset-fsck-run-hash"
        puts "    librarian fsck-object <uuid>"
        puts "    librarian destroy-object-by-uuid-i"
    end
end
