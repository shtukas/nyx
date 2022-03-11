
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

    # Librarian0Utils::commitFileReturnPartsHashs(filepath)
    def self.commitFileReturnPartsHashs(filepath)
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
end

class Librarian2DatablobsXCache

    # Librarian2DatablobsXCache::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, "FAF57B05-2EF0-4F49-B1C8-9E73D03939DE:#{nhash}", blob)
        nhash
    end

    # Librarian2DatablobsXCache::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        KeyValueStore::getOrNull(nil, "FAF57B05-2EF0-4F49-B1C8-9E73D03939DE:#{nhash}")
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
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "url",
            "payload"     => url
        }
    end

    # Librarian5Atoms::issueMatterAtomUsingLocation(location) # Atom
    def self.issueMatterAtomUsingLocation(location)
        raise "[Librarian: error: 2a6077f3-6572-4bde-a435-04604590c8d8]" if !File.exists?(location) # Caller needs to ensure file exists.
        rootnhash = AionCore::commitLocationReturnHash(Librarian14Elizabeth.new("standard usage"), location)
        Librarian0Utils::moveFileToBinTimeline(location)
        {
            "uuid"      => SecureRandom.uuid,
            "mikuType"  => "Atom",
            "unixtime"  => Time.new.to_f,
            "type"      => "matter",
            "rootnhash" => rootnhash
        }
    end

    # Librarian5Atoms::issueUniqueStringAtomUsingString(uniqueString) # Atom
    def self.issueUniqueStringAtomUsingString(uniqueString)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "unique-string",
            "payload"     => uniqueString
        }
    end

    # Librarian5Atoms::issueMarbleAtom(marbleId) # Atom
    def self.issueMarbleAtom(marbleId)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "marble",
            "payload"     => marbleId
        }
    end

    # Librarian5Atoms::interactivelyCreateNewAtomOrNull()
    def self.interactivelyCreateNewAtomOrNull()

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["description-only (default)", "text", "url", "matter", "marble", "unique-string"])

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

        if type == "matter" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return Librarian5Atoms::issueMatterAtomUsingLocation(location)
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
            blob = Librarian2DatablobsXCache::getBlobOrNull(nhash)
            return (JSON.parse(blob)["uuid"] == marbleId)
        end
    end

    # Librarian5Atoms::marbleIsInNhash(nhash, marbleId)
    def self.marbleIsInNhash(nhash, marbleId)
        # TODO:
        # This function can easily been memoised
        object = AionCore::getAionObjectByHash(Librarian14Elizabeth.new("marble search"), nhash)
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

        # Ok, so now we are going to look inside matter
        puts "I am going to look inside matter"
        Librarian6Objects::getObjectsByMikuType("Atom")
            .each{|atom|
                next if atom["type"] != "matter"
                nhash = atom["rootnhash"]
                if Librarian5Atoms::marbleIsInNhash(nhash, marbleId) then
                    puts "I have found the marble in atom matter: #{JSON.pretty_generate(atom)}"
                    puts "Accessing the atom"
                    Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
                    return
                end
            }

        puts "I could not find the marble inside matter"
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
        if atom["type"] == "matter" then
            nhash = atom["rootnhash"]
            AionCore::exportHashAtFolder(Librarian14Elizabeth.new("standard usage"), nhash, "/Users/pascal/Desktop")
            if LucilleCore::askQuestionAnswerAsBoolean("> edit matter ? ", false) then
                location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
                return if location.nil?
                rootnhash = AionCore::commitLocationReturnHash(Librarian14Elizabeth.new("standard usage"), location)
                atom["rootnhash"] = rootnhash
                Librarian6Objects::commit(atom)
                Librarian0Utils::moveFileToBinTimeline(location)
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
        if atom["type"] == "matter" then
            return "Atom (matter)"
        end
        if atom["type"] == "marble" then
            return "Atom (marble): #{atom["payload"]}"
        end
        if atom["type"] == "unique-string" then
            return "Atom (unique-string): #{atom["payload"]}"
        end
        raise "(1EDB15D2-9125-4947-924E-B24D5E67CAE3, atom: #{atom})"
    end
end

class Librarian6Objects

    # Librarian6Objects::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Databases/objects.sqlite3"
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
            "Wave"
        ]
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
        "/Users/pascal/Galaxy/DataBank/Librarian/Databases/notes.sqlite3"
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

    # Librarian7Notes::commitNote(note)
    def self.commitNote(note)
        noteuuid = note["noteuuid"]
        raise "(error: 96717e65-24d6-45d6-be03-0d9d80214eb5, #{note})" if noteuuid.nil?
        db = SQLite3::Database.new(Librarian7Notes::databaseFilepath())
        db.execute "delete from _notes_ where _noteuuid_=?", [noteuuid]
        db.execute "insert into _notes_ (_noteuuid_, _objectuuid_, _unixtime_, _text_) values (?,?,?,?)", [noteuuid, note["objectuuid"], note["unixtime"], note["text"]]
        db.close
    end

    # Librarian7Notes::deleteNote(noteuuid)
    def self.deleteNote(noteuuid)
        db = SQLite3::Database.new(Librarian7Notes::databaseFilepath())
        db.execute "delete from _notes_ where _noteuuid_=?", [noteuuid]
        db.close
    end

    # Librarian7Notes::noteLanding(note)
    def self.noteLanding(note)
        loop {
            system("clear")
            puts "note: #{note["text"].green}"
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["edit note", "delete note", "exit (default)"])
            break if action.nil?
            break if action == "exit (default)"
            if action == "edit note" then
                text = Utils::editTextSynchronously(note["text"])
                note["text"] = text
                Librarian7Notes::commitNote(note)
            end
            if action == "delete note" then
                Librarian7Notes::deleteNote(note["noteuuid"])
                break
            end
        }
    end

    # Librarian7Notes::notesLanding(objectuuid)
    def self.notesLanding(objectuuid)
        loop {
            system("clear")
            notes = Librarian7Notes::getObjectNotes(objectuuid)
            note = LucilleCore::selectEntityFromListOfEntitiesOrNull("note", notes, lambda{|note| note["text"].lines.first(5).join().strip })
            break if note.nil?
            Librarian7Notes::noteLanding(note)
        }
    end
end

class Librarian13DatablobsExternalDrive

    # Librarian13DatablobsExternalDrive::ensureDrive()
    def self.ensureDrive()
        if !File.exists?("/Volumes/Earth/Data/Librarian/Datablobs") then
            puts "I need the drive 🙏"
            LucilleCore::pressEnterToContinue()
        end
        if !File.exists?("/Volumes/Earth/Data/Librarian/Datablobs") then
            puts "I needed the drive 😞"
            exit
        end
    end

    # Librarian13DatablobsExternalDrive::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepathRemote = "/Volumes/Earth/Data/Librarian/Datablobs/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepathRemote)) then
            FileUtils.mkpath(File.dirname(filepathRemote))
        end
        File.open(filepathRemote, "w"){|f| f.write(blob) }
        nhash
    end

    # Librarian13DatablobsExternalDrive::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepathRemote = "/Volumes/Earth/Data/Librarian/Datablobs/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if !File.exists?(filepathRemote) then
            return nil
        end
        IO.read(filepathRemote)
    end
end

class Librarian14Elizabeth

    def initialize(style)
        styles = [
            "standard usage",
            "fsck",
            "marble search",
            "populate remote drive"
        ]
        if !styles.include?(style) then
            raise "(error: 743731ec-5c84-44cd-b076-60ff0385e7f9, style: #{style})"
        end
        @style = style
    end

    def commitBlob(blob)
        if @style == "standard usage"
            return Librarian2DatablobsXCache::putBlob(blob)
        end
        if @style == "fsck" then
            return Librarian2DatablobsXCache::putBlob(blob)
        end
        if @style == "marble search" then
            return Librarian2DatablobsXCache::putBlob(blob)
        end
        if @style == "populate remote drive" then
            # This case should not happen because this style should only be used to help move stuff from the local cache to the external drive
            raise "(error: a44755ea-6a6e-44de-8467-8418cee9ca00)"
        end
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        if @style == "standard usage"
            # normal user operations
            blob = Librarian2DatablobsXCache::getBlobOrNull(nhash)
            if blob.nil? then
                puts "downloading blob: #{nhash}"
                blob = Librarian13DatablobsExternalDrive::getBlobOrNull(nhash)
                if blob then
                    Librarian2DatablobsXCache::putBlob(blob)
                end
            end
        end
        if @style == "fsck" then
            # fsck
            blob = Librarian13DatablobsExternalDrive::getBlobOrNull(nhash)
        end
        if @style == "marble search" then
            # marble search
            blob = Librarian2DatablobsXCache::getBlobOrNull(nhash)
            if blob.nil? then
                blob = Librarian13DatablobsExternalDrive::getBlobOrNull(nhash)
            end
        end
        if @style == "populate remote drive" then
            # lifting data off xcache
            blob = Librarian13DatablobsExternalDrive::getBlobOrNull(nhash)
            if blob.nil? then
                blob = Librarian2DatablobsXCache::getBlobOrNull(nhash)
                if blob then
                    puts "uploading blob: #{nhash}"
                    Librarian13DatablobsExternalDrive::putBlob(blob)
                end
            end
        end

        return blob if blob
        raise "[error: 0573a059-5ca2-431d-a4b4-ab8f4a0a34fe, nhash: #{nhash}]" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            puts "fsck: validating blob: #{nhash}"
            return ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
        rescue
            false
        end
    end
end

class Librarian15Fsck

    # Librarian15Fsck::fsckAtom(atom) : Boolean
    def self.fsckAtom(atom)
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
        if atom["type"] == "matter" then
            nhash = atom["rootnhash"]
            status = AionFsck::structureCheckAionHash(Librarian14Elizabeth.new("fsck"), nhash)
            return status
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

    # Librarian15Fsck::fsck()
    def self.fsck()
        Librarian6Objects::objects().each{|item|
            next if item["mikuType"] == "Atom"
            puts JSON.pretty_generate(item)
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            if atom.nil? then
                puts "(error: b3fde618-5d36-4f50-b1dc-cbf29bc4d61e, atom not found)" 
                puts "item:"
                puts JSON.pretty_generate(item)
                exit
            end
            status = Librarian15Fsck::fsckAtom(atom)
            if !status then 
                puts "(error: d4f39eb1-7a3b-4812-bb99-7adeb9d8c37c, atom fsck returned false)" 
                puts "item:"
                puts JSON.pretty_generate(item)
                puts "atom:"
                puts JSON.pretty_generate(atom)
                exit
            end
        }
    end
end

class Librarian16Upload

    # Librarian16Upload::uploadAtom(atom) : Boolean
    def self.uploadAtom(atom)
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
        if atom["type"] == "matter" then
            nhash = atom["rootnhash"]
            status = AionFsck::structureCheckAionHash(Librarian14Elizabeth.new("populate remote drive"), nhash)
            return status
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

    # Librarian16Upload::upload()
    def self.upload()
        Librarian6Objects::objects().each{|item|
            next if item["mikuType"] == "Atom"
            puts JSON.pretty_generate(item)
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            if atom.nil? then
                puts "(error: b3fde618-5d36-4f50-b1dc-cbf29bc4d61e, atom not found)" 
                puts "item:"
                puts JSON.pretty_generate(item)
                exit
            end
            status = Librarian16Upload::uploadAtom(atom)
            if !status then 
                puts "(error: d4f39eb1-7a3b-4812-bb99-7adeb9d8c37c, atom fsck returned false)" 
                puts "item:"
                puts JSON.pretty_generate(item)
                puts "atom:"
                puts JSON.pretty_generate(atom)
                exit
            end
        }
    end
end
