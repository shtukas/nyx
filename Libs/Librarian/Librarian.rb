
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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ------------------------------------------------------------------------

class Librarian0Utils

    # Librarian0Utils::filepathToContentHash(filepath)
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

    # Librarian0Utils::interactivelyDropNewMarbleFileOnDesktop() # Marble
    def self.interactivelyDropNewMarbleFileOnDesktop()
        marble = {
            "uuid" => SecureRandom.uuid
        }
        filepath = "/Users/pascal/Desktop/nyx-marble.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(marble)) }
        puts "Librarian marble generated on the Desktop, drop it at the right location"
        LucilleCore::pressEnterToContinue()
        marble
    end

    # Librarian0Utils::interactivelySelectDesktopLocationOrNull() 
    def self.interactivelySelectDesktopLocationOrNull()
        entries = Dir.entries("/Users/pascal/Desktop").select{|filename| !filename.start_with?(".") }.sort
        locationNameOnDesktop = LucilleCore::selectEntityFromListOfEntitiesOrNull("locationname", entries)
        return nil if locationNameOnDesktop.nil?
        "/Users/pascal/Desktop/#{locationNameOnDesktop}"
    end

    # Librarian0Utils::locationToAionPointRootNamedHash(location)
    def self.locationToAionPointRootNamedHash(location)
        raise "[Librarian0Utils: error: a1ac8255-45ed-4347-a898-d306c49f230c, location: #{location}]" if !File.exists?(location) # Caller needs to ensure file exists.
        AionCore::commitLocationReturnHash(Librarian4Elizabeth.new(), location)
    end

    # Librarian0Utils::gluonIdToFilepath(gluonId)
    def self.gluonIdToFilepath(gluonId)
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/GluonFiles/#{gluonId}.sqlite3"
    end

    # Librarian0Utils::locationToGluonRootNamedHash(gluonId, location)
    def self.locationToGluonRootNamedHash(gluonId, location)
        raise "[Librarian0Utils: error: f3f9e10f-d9e6-4e12-bf35-12954231ae18, location: #{location}]" if !File.exists?(location) # Caller needs to ensure file exists.
        filepath = Librarian0Utils::gluonIdToFilepath(gluonId)
        AionCore::commitLocationReturnHash(Librarian11GluonElizabeth.new(filepath), location)
    end

    # Librarian0Utils::marbleLocationOrNullUseTheForce(uuid)
    def self.marbleLocationOrNullUseTheForce(uuid)
        Find.find("/Users/pascal/Galaxy") do |path|

            Find.prune() if path.include?("/Users/pascal/Galaxy/DataBank")
            Find.prune() if path.include?("/Users/pascal/Galaxy/Software")

            next if !File.file?(path)
            next if File.basename(path) != "nyx-marble.json" # We look for equality since at the moment we do not expect them to be renamed.

            marble = JSON.parse(IO.read(path))

            # We have a marble. We are going to cache its location.
            # We cache the location against the marble's uuid.
            KeyValueStore::set(nil, "5d7f5599-0b2c-4f16-acc6-a8ead29c272f:#{marble["uuid"]}", path)

            next if marble["uuid"] != uuid
            return path
        end
    end

    # Librarian0Utils::marbleLocationOrNullUsingCache(uuid)
    def self.marbleLocationOrNullUsingCache(uuid)
        path = KeyValueStore::getOrNull(nil, "5d7f5599-0b2c-4f16-acc6-a8ead29c272f:#{uuid}")
        return nil if path.nil?
        return nil if !File.exists?(path)
        return nil if File.basename(path) != "nyx-marble.json"
        marble = JSON.parse(IO.read(path))
        return nil if marble["uuid"] != uuid
        path
    end

    # Librarian0Utils::moveFileToBinTimeline(location)
    def self.moveFileToBinTimeline(location)
        return if !File.exists?(location)
        directory = "/Users/pascal/x-space/bin-timeline/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(directory)
        FileUtils.mv(location, directory)
    end
end

class Librarian2DataBlobs

    # Librarian2DataBlobs::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/Datablobs"
    end

    # Librarian2DataBlobs::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # Librarian2DataBlobs::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{Librarian2DataBlobs::repositoryFolderPath()}/#{nhash[7, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # Librarian2DataBlobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        folderpath = "#{Librarian2DataBlobs::repositoryFolderPath()}/#{nhash[7, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        if File.exists?(filepath) then
            return IO.read(filepath)
        end
        nil
    end
end

=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, nhash, blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

class Librarian4Elizabeth

    def initialize()
    end

    def commitBlob(blob)
        Librarian2DataBlobs::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = Librarian2DataBlobs::getBlobOrNull(nhash)
        return blob if blob
        raise "(Librarian4Elizabeth, readBlobErrorIfNotFound, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

class Librarian5Atoms

    # -- Makers ---------------------------------------

    # Librarian5Atoms::issueDescriptionOnlyAtom() # Atom
    def self.issueDescriptionOnlyAtom()
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "description-only",
            "payload"     => nil
        }
    end

    # Librarian5Atoms::issueTextAtomUsingText(text) # Atom
    def self.issueTextAtomUsingText(text)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "text",
            "payload"     => text
        }
    end

    # Librarian5Atoms::issueUrlAtomUsingUrl(url) # Atom
    def self.issueUrlAtomUsingUrl(url)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "url",
            "payload"     => url
        }
    end

    # Librarian5Atoms::issueAionPointAtomUsingLocation(location) # Atom
    def self.issueAionPointAtomUsingLocation(location)
        raise "[Librarian: error: 201d6b31-e08b-4e64-955c-807e717138d6]" if !File.exists?(location) # Caller needs to ensure file exists.
        nhash = Librarian0Utils::locationToAionPointRootNamedHash(location)
        Librarian0Utils::moveFileToBinTimeline(location)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime" => Time.new.to_f,
            "type"     => "aion-point",
            "payload"  => nhash
        }
    end

    # Librarian5Atoms::issueGluonAtomUsingLocation(gluonId, location) # Atom
    def self.issueGluonAtomUsingLocation(gluonId, location)
        raise "[Librarian: error: 2a6077f3-6572-4bde-a435-04604590c8d8]" if !File.exists?(location) # Caller needs to ensure file exists.
        nhash = Librarian0Utils::locationToGluonRootNamedHash(gluonId, location)
        Librarian0Utils::moveFileToBinTimeline(location)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime" => Time.new.to_f,
            "type"     => "gluon",
            "gluonId"  => gluonId,
            "payload"  => nhash
        }
    end

    # Librarian5Atoms::issueUniqueStringAtomUsingString(uniqueString) # Atom
    def self.issueUniqueStringAtomUsingString(uniqueString)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "unique-string",
            "payload"     => uniqueString
        }
    end

    # Librarian5Atoms::issueMarbleAtom(marbleId) # Atom
    def self.issueMarbleAtom(marbleId)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "marble",
            "payload"     => marbleId
        }
    end

    # Librarian5Atoms::interactivelyCreateNewAtomOrNull()
    def self.interactivelyCreateNewAtomOrNull()

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["description-only (default)", "text", "url", "aion-point (deprecated)", "gluon", "marble", "unique-string"])

        if type.nil? or type == "description-only (default)" then
            return Librarian5Atoms::issueDescriptionOnlyAtom()
        end

        if type == "text" then
            text = Librarian0Utils::editTextSynchronously("")
            return Librarian5Atoms::issueTextAtomUsingText(text)
        end

        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return Librarian5Atoms::issueUrlAtomUsingUrl(url)
        end

        if type == "aion-point (deprecated)" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return Librarian5Atoms::issueAionPointAtomUsingLocation(location)
        end

        if type == "gluon" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            gluonId = SecureRandom.uuid
            return Librarian5Atoms::issueGluonAtomUsingLocation(gluonId, location)
        end

        if type == "marble" then
            marble = Librarian0Utils::interactivelyDropNewMarbleFileOnDesktop()
            return Librarian5Atoms::issueMarbleAtom(marble["uuid"])
        end

        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (use '#{SecureRandom.hex(6)}' if need one): ")
            return nil if uniquestring == ""
            return Librarian5Atoms::issueUniqueStringAtomUsingString(uniquestring)
        end

        raise "[Librarian] [D2BDF2BC-D0B8-4D76-B00F-9EBB328D4CF7, type: #{type}]"
    end

    # -- Update ------------------------------------------

    # Librarian5Atoms::marbleIsInAionPointObject(object, marbleId)
    def self.marbleIsInAionPointObject(object, marbleId)
        if object["aionType"] == "indefinite" then
            return false
        end
        if object["aionType"] == "directory" then
            return object["items"].any?{|nhash| Librarian5Atoms::marbleIsInNhash(nhash, marbleId) }
        end
        if object["aionType"] == "file" then
            return false if (object["name"] != "nyx-marble.json")
            nhash = object["hash"]
            blob = Librarian2DataBlobs::getBlobOrNull(nhash)
            return (JSON.parse(blob)["uuid"] == marbleId)
        end
    end

    # Librarian5Atoms::marbleIsInNhash(nhash, marbleId)
    def self.marbleIsInNhash(nhash, marbleId)
        # TODO:
        # This function can easily been memoised
        object = AionCore::getAionObjectByHash(Librarian4Elizabeth.new(), nhash)
        Librarian5Atoms::marbleIsInAionPointObject(object, marbleId)
    end

    # Librarian5Atoms::findAndAccessMarble(marbleId)
    def self.findAndAccessMarble(marbleId)
        location = Librarian0Utils::marbleLocationOrNullUsingCache(marbleId)
        if location then
            puts "found marble at: #{location}"
            system("open '#{File.dirname(location)}'")
            return nil
        end
        puts "I could not find the location of the marble in the cache"

        return nil if !LucilleCore::askQuestionAnswerAsBoolean("Would you like me to use the Force ? ")
        location = Librarian0Utils::marbleLocationOrNullUseTheForce(marbleId)
        if location then
            puts "found marble at: #{location}"
            system("open '#{File.dirname(location)}'")
            return nil
        end
        puts "I could not find the marble in Galaxy using the Force"

        # Ok, so now we are going to look inside aion-points
        puts "I am going to look inside aion-points"
        Librarian6Objects::getObjectsByMikuType("Atom")
            .each{|atom|
                next if atom["type"] != "aion-point"
                nhash = atom["payload"]
                if Librarian5Atoms::marbleIsInNhash(nhash, marbleId) then
                    puts "I have found the marble in atom aion-point: #{JSON.pretty_generate(atom)}"
                    puts "Accessing the atom"
                    Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
                    return
                end
            }

        puts "I could not find the marble inside aion-points"
        LucilleCore::pressEnterToContinue()
        return nil
    end

    # Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
    def self.accessWithOptionToEditOptionalAutoMutation(atom)
        if atom["type"] == "description-only" then
            puts "atom: description-only (atom payload is empty)"
            LucilleCore::pressEnterToContinue()
        end
        if atom["type"] == "text" then
            text1 = atom["payload"]
            text2 = Librarian0Utils::editTextSynchronously(text1)
            if text1 != text2 then
                atom["payload"] = text2
                Librarian6Objects::commit(atom)
            end
        end
        if atom["type"] == "url" then
            Librarian0Utils::openUrlUsingSafari(atom["payload"])
            if LucilleCore::askQuestionAnswerAsBoolean("> edit url ? ", false) then
                url = LucilleCore::askQuestionAnswerAsString("url (empty to abort) : ")
                if url.size > 0 then
                    atom["payload"] = url
                    Librarian6Objects::commit(atom)
                end
            end
        end
        if atom["type"] == "aion-point" then
            AionCore::exportHashAtFolder(Librarian4Elizabeth.new(), atom["payload"], "/Users/pascal/Desktop")
            if LucilleCore::askQuestionAnswerAsBoolean("> edit aion-point ? ", false) then
                location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
                return nil if location.nil?
                nhash = Librarian0Utils::locationToAionPointRootNamedHash(location)
                Librarian0Utils::moveFileToBinTimeline(location)
                atom["payload"] = nhash
                Librarian6Objects::commit(atom)
            end
        end
        if atom["type"] == "gluon" then
            gluonId = atom["gluonId"]
            filepath = Librarian0Utils::gluonIdToFilepath(gluonId)
            AionCore::exportHashAtFolder(Librarian11GluonElizabeth.new(filepath), atom["payload"], "/Users/pascal/Desktop")
            if LucilleCore::askQuestionAnswerAsBoolean("> edit gluon ? ", false) then
                location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
                return if location.nil?
                nhash = Librarian0Utils::locationToGluonRootNamedHash(gluonId, location)
                Librarian0Utils::moveFileToBinTimeline(location)
                atom["payload"] = nhash
                Librarian6Objects::commit(atom)
            end
        end
        if atom["type"] == "marble" then
            marbleId = atom["payload"]
            Librarian5Atoms::findAndAccessMarble(marbleId)
        end
        if atom["type"] == "unique-string" then
            payload = atom["payload"]
            puts "unique string: #{payload}"
            location = Librarian0Utils::atlas(payload)
            if location then
                puts "location: #{location}"
                if LucilleCore::askQuestionAnswerAsBoolean("open ? ", true) then
                    system("open '#{location}'")
                end
            else
                puts "[Librarian] Could not find location for unique string: #{payload}"
                LucilleCore::pressEnterToContinue()
            end
        end
    end

    # -- Data ------------------------------------------

    # Librarian5Atoms::toString(atom)
    def self.toString(atom)
        "[atom] #{atom["type"]}"
    end

    # Librarian5Atoms::atomPayloadToTextOrNull(atom)
    def self.atomPayloadToTextOrNull(atom)
        if atom["type"] == "description-only" then
            return nil
        end
        if atom["type"] == "text" then
            text = [
                "-- Atom (text) --",
                atom["payload"].strip,
            ].join("\n")
            return text
        end
        if atom["type"] == "url" then
            return "Atom (url): #{atom["payload"]}"
        end
        if atom["type"] == "aion-point" then
            return "Atom (aion-point): #{atom["payload"]}"
        end
        if atom["type"] == "gluon" then
            return "Atom (gluon): #{atom["payload"]}"
        end
        if atom["type"] == "marble" then
            return "Atom (marble): #{atom["payload"]}"
        end
        if atom["type"] == "unique-string" then
            return "Atom (unique-string): #{atom["payload"]}"
        end
        raise "(1EDB15D2-9125-4947-924E-B24D5E67CAE3, atom: #{atom})"
    end

    # Librarian5Atoms::fsck(atom) : Boolean
    def self.fsck(atom)
        puts JSON.pretty_generate(atom)
        if atom["type"] == "description-only" then
            return true
        end
        if atom["type"] == "text" then
            return true
        end
        if atom["type"] == "url" then
            return true
        end
        if atom["type"] == "aion-point" then
            nhash = atom["payload"]
            return AionFsck::structureCheckAionHash(Librarian4Elizabeth.new(), nhash)
        end
        if atom["type"] == "gluon" then
            gluonId = atom["gluonId"]
            filepath = Librarian0Utils::gluonIdToFilepath(gluonId)
            nhash = atom["payload"]
            return AionFsck::structureCheckAionHash(Librarian11GluonElizabeth.new(filepath), nhash)
        end
        if atom["type"] == "marble" then
            return true
        end
        if atom["type"] == "unique-string" then
            # Technically we should be checking if the target exists, but that takes too long
            return true
        end
        raise "(F446B5E4-A795-415D-9D33-3E6B5E8E0AFF: non recognised atom type: #{atom})"
    end
end

class Librarian6Objects

    # Librarian6Objects::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/objects.sqlite3"
    end

    # Librarian6Objects::validMikuTypes()
    def self.validMikuTypes()
        [
            "Atom",
            "Nx31",
            "TxCalendarItem",
            "TxDated",
            "TxDrop",
            "TxFloat",
            "TxTodo",
            "TxTodo-Overflow",
            "Wave"
        ]
    end

    # Librarian6Objects::objects2RepositoryFolderPath()
    def self.objects2RepositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/Objects"
    end

    # Librarian6Objects::objectsFilepathsEnumerator()
    def self.objectsFilepathsEnumerator()
        Enumerator.new do |filepaths|
            Find.find(Librarian6Objects::objects2RepositoryFolderPath()) do |location|
                next if !File.file?(location)
                next if location[-5, 5] != ".json"
                filepaths << location
            end
        end
    end

    # Librarian6Objects::objectUUIDToFilepath(uuid)
    def self.objectUUIDToFilepath(uuid)
        trace = Digest::SHA1.hexdigest(uuid)
        fragment = trace[0, 2]
        folder2 = "#{Librarian6Objects::objects2RepositoryFolderPath()}/#{fragment}"
        if !File.exists?(folder2) then
            FileUtils.mkdir(folder2)
        end
        filepath = "#{folder2}/#{trace}.json"
        filepath
    end

    # ------------------------------------------------------------------------
    # Below: Public Interface

    # Librarian6Objects::objects()
    def self.objects()
        db = SQLite3::Database.new(Librarian6Objects::databaseFilepath())
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

    # Librarian6Objects::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        db = SQLite3::Database.new(Librarian6Objects::databaseFilepath())
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

    # Librarian6Objects::getObjectsByMikuTypeLimitByOrdinal(mikuType, n)
    def self.getObjectsByMikuTypeLimitByOrdinal(mikuType, n)
        db = SQLite3::Database.new(Librarian6Objects::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_ where _mikuType_=? order by _ordinal_ limit ?", [mikuType, n]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # Librarian6Objects::commit(object)
    def self.commit(object)
        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?
        raise "(error: 23273f9d-b6a0-4cdc-a826-b10c3a3955c5, non valid mikuType: #{object["mikuType"]})" if !Librarian6Objects::validMikuTypes().include?(object["mikuType"])

        ordinal = object["ordinal"] || 0

        db = SQLite3::Database.new(Librarian6Objects::databaseFilepath())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_) values (?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), ordinal]
        db.close
    end

    # Librarian6Objects::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Librarian6Objects::databaseFilepath())
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

    # Librarian6Objects::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(Librarian6Objects::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        db.close
    end
end

class Librarian7Notes

    # Librarian7Notes::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/notes.sqlite3"
    end

    # Librarian7Notes::getObjectNotes(objectuuid)
    def self.getObjectNotes(objectuuid)
        db = SQLite3::Database.new(Librarian7Notes::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _notes_ where _objectuuid_=?", [objectuuid]) do |row|
            answer << {
                "noteuuid"   => row['_noteuuid_'],
                "objectuuid" => row['_objectuuid_'],
                "unixtime"   => row['_unixtime_'],
                "text"       => row['_text_'],
            }
        end
        db.close
        answer
    end

    # Librarian7Notes::addNote(objectuuid, text)
    def self.addNote(objectuuid, text)
        noteuuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        db = SQLite3::Database.new(Librarian7Notes::databaseFilepath())
        db.execute "insert into _notes_ (_noteuuid_, _objectuuid_, _unixtime_, _text_) values (?,?,?,?)", [noteuuid, objectuuid, unixtime, text]
        db.close
    end

    # Librarian7Notes::deleteNote(noteuuid)
    def self.deleteNote(noteuuid)
        db = SQLite3::Database.new(Librarian7Notes::databaseFilepath())
        db.execute "delete from _notes_ where _noteuuid_=?", [noteuuid]
        db.close
    end
end

class Librarian9NonStandardOps
    
    # Librarian9NonStandardOps::commitFileReturnPartsHashs(filepath)
    def self.commitFileReturnPartsHashs(filepath)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)
        hashes = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            hashes << Librarian2DataBlobs::putBlob(blob)
        end
        f.close()
        hashes
    end
end

class Librarian11GluonElizabeth

    # @filepath

    def initialize(filepath)
        @filepath = filepath
    end

    def commitBlob(blob)

        filepath = @filepath

        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "create table _data_ (_key_ string, _blob_ blob)", []
            db.close
        end

        raise "a57bb88e-d792-4b15-bb7d-3ff7d41ee3ce" if !File.exists?(filepath)

        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [nhash]
        db.execute "insert into _data_ (_key_, _blob_) values (?,?)", [nhash, blob]
        db.commit 
        db.close
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)

        filepath = @filepath

        raise "71fadc7b-0aec-4ece-a0e7-b881cc5b3ca9" if !File.exists?(filepath)

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _data_ where _key_=?", [nhash]) do |row|
            blob = row['_blob_']
        end
        db.close
        return blob if blob

        raise "[Error: 3CCC5678-E1FE-4729-B72B-C7E5D7951983, nhash: #{nhash}]"
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

