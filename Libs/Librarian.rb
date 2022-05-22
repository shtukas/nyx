
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
            hashes << XCacheExtensionsDatablobs::putBlob(blob)
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

# ---------------------------------------------------------------------------
# Objects
# ---------------------------------------------------------------------------

$Librarian19DB = nil
$Librarian19DeployedSnapshot = nil

class Librarian19InMemoryDatabase

    # Librarian19InMemoryDatabase::rebuildInMemoryDatabaseFromObjects(objects)
    def self.rebuildInMemoryDatabaseFromObjects(objects)
        $Librarian19DB = SQLite3::Database.new(":memory:")
        $Librarian19DB.results_as_hash = true
        $Librarian19DB.busy_timeout = 117
        $Librarian19DB.busy_handler { |count| true }
        $Librarian19DB.execute "CREATE TABLE _objects_ (_objectuuid_ text primary key, _mikuType_ text, _object_ text, _ordinal_ float, _universe_ text);"

        objects.each{|object|
            ordinal = object["ordinal"] || 0
            $Librarian19DB.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), ordinal, object["universe"]]
        }
    end

    # ---------------------------------------------------
    # Reading

    # Librarian19InMemoryDatabase::objects()
    def self.objects()
        answer = []
        $Librarian19DB.execute("select * from _objects_ order by _ordinal_", []) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryDatabase::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        answer = []
        $Librarian19DB.execute("select * from _objects_ where _mikuType_=? order by _ordinal_", [mikuType]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryDatabase::getObjectsByMikuTypeAndUniverse(mikuType, universe)
    def self.getObjectsByMikuTypeAndUniverse(mikuType, universe)
        answer = []
        $Librarian19DB.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_", [mikuType, universe]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryDatabase::getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
    def self.getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
        answer = []
        $Librarian19DB.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_ limit ?", [mikuType, universe, n]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # Librarian19InMemoryDatabase::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        answer = nil
        $Librarian19DB.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            answer = JSON.parse(row['_object_'])
        end
        answer
    end

    # ---------------------------------------------------
    # Writing

    # Librarian19InMemoryDatabase::commit(object)
    def self.commit(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        puts "We are not expecting to commit objects while a snapshot is deployed".yellow
        puts JSON.pretty_generate(object).yellow
        LucilleCore::pressEnterToContinue()
        puts "Exiting"
        exit

        #ordinal = object["ordinal"] || 0
        #if object["universe"].nil? then
        #    object["universe"] = "backlog"
        #end

        #$Librarian19DB.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        #$Librarian19DB.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), ordinal, object["universe"]]
    end

    # Librarian19InMemoryDatabase::destroy(uuid)
    def self.destroy(uuid)
        puts "We are not expecting to destroy objects while a snapshot is deployed".yellow
        puts "uuid: #{uuid}"
        puts "Exiting".yellow
        exit

        #$Librarian19DB.execute "delete from _objects_ where _objectuuid_=?", [uuid]
    end
end

class Librarian20LocalObjectsStore

    # Librarian20LocalObjectsStore::pathToObjectsStoreDatabase()
    def self.pathToObjectsStoreDatabase()
        "#{Config::pathToLocalDidact()}/objects-store.sqlite3"
    end

    # ---------------------------------------------------
    # Reading

    # Librarian20LocalObjectsStore::objects()
    def self.objects()

        if $Librarian19DB then
            return Librarian19InMemoryDatabase::objects()
        end

        db = SQLite3::Database.new(Librarian20LocalObjectsStore::pathToObjectsStoreDatabase())
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

    # Librarian20LocalObjectsStore::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)

        if $Librarian19DB then
            return Librarian19InMemoryDatabase::getObjectsByMikuType(mikuType)
        end

        db = SQLite3::Database.new(Librarian20LocalObjectsStore::pathToObjectsStoreDatabase())
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

    # Librarian20LocalObjectsStore::getObjectsByMikuTypeAndUniverse(mikuType, universe)
    def self.getObjectsByMikuTypeAndUniverse(mikuType, universe)

        if $Librarian19DB then
            return Librarian19InMemoryDatabase::getObjectsByMikuTypeAndUniverse(mikuType, universe)
        end

        db = SQLite3::Database.new(Librarian20LocalObjectsStore::pathToObjectsStoreDatabase())
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

    # Librarian20LocalObjectsStore::getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
    def self.getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)

        if $Librarian19DB then
            return Librarian19InMemoryDatabase::getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
        end

        db = SQLite3::Database.new(Librarian20LocalObjectsStore::pathToObjectsStoreDatabase())
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

    # Librarian20LocalObjectsStore::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)

        if $Librarian19DB then
            return Librarian19InMemoryDatabase::getObjectByUUIDOrNull(uuid)
        end

        db = SQLite3::Database.new(Librarian20LocalObjectsStore::pathToObjectsStoreDatabase())
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

    # ---------------------------------------------------
    # Writing

    # Librarian20LocalObjectsStore::commit(object)
    def self.commit(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        if $Librarian19DB then
            puts "We are not expecting to commit objects while a snapshot is deployed".yellow
            puts JSON.pretty_generate(object).yellow
            puts "Exiting".yellow
            exit
        end

        if object["ordinal"].nil? then
            object["ordinal"] = 0
        end

        if object["universe"].nil? then
            object["universe"] = "backlog"
        end

        object["lxVariantId"] = SecureRandom.uuid

        # TODO: implement lxGenealogy

        db = SQLite3::Database.new(Librarian20LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }

        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), object["ordinal"], object["universe"]]

        db.close
    end

    # Librarian20LocalObjectsStore::logicaldelete(uuid)
    def self.logicaldelete(uuid)

        if $Librarian19DB then
            puts "We are not expecting to delete objects while a snapshot is deployed".yellow
            puts "uuid: #{uuid}"
            puts "Exiting".yellow
            exit
        end

        object = Librarian20LocalObjectsStore::getObjectByUUIDOrNull(uuid)
        return if object.nil?
        object["lxDeleted"] = true
        Librarian20LocalObjectsStore::commit(object)
    end

    # Librarian20LocalObjectsStore::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(Librarian20LocalObjectsStore::pathToObjectsStoreDatabase())
        db.results_as_hash = true
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        db.close
    end
end

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

class LibrarianCLI

    # LibrarianCLI::main()
    def self.main()

        if ARGV[0] == "alexandra-infinity-sync" then
            LibrarianSynchronization::run()
            exit
        end

        if ARGV[0] == "show-object" and ARGV[1] then
            uuid = ARGV[1]
            object = Librarian20LocalObjectsStore::getObjectByUUIDOrNull(uuid)
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
            object = Librarian20LocalObjectsStore::getObjectByUUIDOrNull(uuid)
            if object then
                object = Utils::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                Librarian20LocalObjectsStore::commit(object)
            else
                puts "I could not find an object with this uuid"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "destroy-object-by-uuid-i" then
            uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
            Librarian20LocalObjectsStore::logicaldelete(uuid)
            exit
        end

        if ARGV[0] == "get-blob" and ARGV[1] then
            nhash = ARGV[1]
            blob = EnergyGridDatablobs::getBlobOrNull(nhash)
            if blob then
                puts blob
            else
                puts "I could not find a blob with nhash: #{nhash}"
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
        puts "    librarian make-system-snapshot"
        puts "    librarian get-blob <nhash>"
        puts "    librarian show-object <uuid>"
        puts "    librarian edit-object <uuid>"
        puts "    librarian destroy-object-by-uuid-i"
    end
end
