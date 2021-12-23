
# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

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

# -------------------------------------------------------------------------------

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

class CoreDataElizabeth

    def initialize()

    end

    def commitBlob(blob)
        CoreDataUtils::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = CoreDataUtils::getBlobOrNull(nhash)
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

class CoreDataUtils

    # CoreDataUtils::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/CoreData"
    end

    # CoreDataUtils::datablobsRoot()
    def self.datablobsRoot()
        "#{CoreDataUtils::path()}/DataBlobs2"
    end

    # CoreDataUtils::foldersRepositoryPath()
    def self.foldersRepositoryPath()
        "#{CoreDataUtils::path()}/Folders"
    end

    # CoreDataUtils::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # CoreDataUtils::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{CoreDataUtils::datablobsRoot()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # CoreDataUtils::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        folderpath = "#{CoreDataUtils::datablobsRoot()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end

    # CoreDataUtils::openUrlUsingSafari(url)
    def self.openUrlUsingSafari(url)
        system("open -a Safari '#{url}'")
    end

    # CoreDataUtils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = "#{SecureRandom.uuid}.txt"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # CoreDataUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # CoreDataUtils::atlas(pattern)
    def self.atlas(pattern)
        location = `/Users/pascal/Galaxy/LucilleOS/Binaries/atlas '#{pattern}'`.strip
        (location != "") ? location : nil
    end

    # CoreDataUtils::interactivelyMakeNewManagedFolderReturnName()
    def self.interactivelyMakeNewManagedFolderReturnName()
        foldername = CoreDataUtils::timeStringL22()
        folderpath = "#{CoreDataUtils::foldersRepositoryPath()}/#{foldername}"
        FileUtils.mkdir(folderpath)
        FileUtils.touch("#{folderpath}/01 README.txt")
        puts "opening core data folder #{folderpath}"
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue()
        foldername
    end

    # CoreDataUtils::interactivelyDropNewMarbleFileOnDesktop() # Marble
    def self.interactivelyDropNewMarbleFileOnDesktop()
        marble = {
            "uuid" => SecureRandom.uuid
        }
        filepath = "/Users/pascal/Desktop/nyx-marble.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(marble)) }
        puts "CoreData2 marble generated on the Desktop, drop it at the right location"
        LucilleCore::pressEnterToContinue()
        marble
    end

    # CoreDataUtils::interactivelySelectDesktopLocationOrNull() 
    def self.interactivelySelectDesktopLocationOrNull()
        entries = Dir.entries("/Users/pascal/Desktop").select{|filename| !filename.start_with?(".") }.sort
        locationNameOnDesktop = LucilleCore::selectEntityFromListOfEntitiesOrNull("locationname", entries)
        return nil if locationNameOnDesktop == ""
        "/Users/pascal/Desktop/#{locationNameOnDesktop}"
    end

    # CoreDataUtils::locationToAionRootNamedHash(location)
    def self.locationToAionRootNamedHash(location)
        raise "[CoreDataUtils: error: a1ac8255-45ed-4347-a898-d306c49f230c, location: #{location}]" if !File.exists?(location) # Caller needs to ensure file exists.
        AionCore::commitLocationReturnHash(CoreDataElizabeth.new(), location)
    end

    # CoreDataUtils::marbleLocationOrNullUseTheForce(uuid)
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

    # CoreDataUtils::marbleLocationOrNullUsingCache(uuid)
    def self.marbleLocationOrNullUsingCache(uuid)
        path = KeyValueStore::getOrNull(nil, "5d7f5599-0b2c-4f16-acc6-a8ead29c272f:#{uuid}")
        return nil if path.nil?
        return nil if !File.exists?(path)
        return nil if File.basename(path) != "nyx-marble.json"
        marble = JSON.parse(IO.read(path))
        return nil if marble["uuid"] != uuid
        path
    end

    # CoreDataUtils::moveFileToBinTimeline(location)
    def self.moveFileToBinTimeline(location)
        directory = "/Users/pascal/x-space/bin-timeline/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(directory)
        FileUtils.mv(location, directory)
    end
end

class CoreData5

    # -- Makers ---------------------------------------

    # CoreData5::issueDescriptionOnlyAtom() # Atom
    def self.issueDescriptionOnlyAtom()
        {
            "uuid"        => SecureRandom.uuid,
            "unixtime"    => Time.new.to_f,
            "type"        => "description-only",
            "payload"     => nil
        }
    end

    # CoreData5::issueTextAtomUsingText(text) # Atom
    def self.issueTextAtomUsingText(text)
        {
            "uuid"        => SecureRandom.uuid,
            "unixtime"    => Time.new.to_f,
            "type"        => "text",
            "payload"     => text
        }
    end

    # CoreData5::issueUrlAtomUsingUrl(url) # Atom
    def self.issueUrlAtomUsingUrl(url)
        {
            "uuid"        => SecureRandom.uuid,
            "unixtime"    => Time.new.to_f,
            "type"        => "url",
            "payload"     => url
        }
    end

    # CoreData5::issueAionPointAtomUsingLocation(location) # Atom
    def self.issueAionPointAtomUsingLocation(location)
        raise "[CoreData5: error: 201d6b31-e08b-4e64-955c-807e717138d6]" if !File.exists?(location) # Caller needs to ensure file exists.
        nhash = CoreDataUtils::locationToAionRootNamedHash(location)
        CoreDataUtils::moveFileToBinTimeline(location)
        {
            "uuid"     => SecureRandom.uuid,
            "unixtime" => Time.new.to_f,
            "type"     => "aion-point",
            "payload"  => nhash
        }
    end

    # CoreData5::issueUniqueStringAtomUsingString(uniqueString) # Atom
    def self.issueUniqueStringAtomUsingString(uniqueString)
        {
            "uuid"        => SecureRandom.uuid,
            "unixtime"    => Time.new.to_f,
            "type"        => "unique-string",
            "payload"     => uniqueString
        }
    end

    # CoreData5::issueFolderAtom() # Atom
    def self.issueFolderAtom()
        foldername = CoreDataUtils::interactivelyMakeNewManagedFolderReturnName()
        {
            "uuid"        => SecureRandom.uuid,
            "unixtime"    => Time.new.to_f,
            "type"        => "managed-folder",
            "payload"     => foldername
        }
    end

    # CoreData5::issueMarbleAtom(marbleId) # Atom
    def self.issueMarbleAtom(marbleId)
        {
            "uuid"        => SecureRandom.uuid,
            "unixtime"    => Time.new.to_f,
            "type"        => "marble",
            "payload"     => marbleId
        }
    end

    # CoreData5::interactivelyCreateNewAtomOrNull()
    def self.interactivelyCreateNewAtomOrNull()

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["description-only (default)", "text", "url", "aion-point", "marble", "managed-folder", "unique-string"])

        if type.nil? or type == "description-only (default)" then
            return CoreData5::issueDescriptionOnlyAtom()
        end

        if type == "text" then
            text = CoreDataUtils::editTextSynchronously("")
            return CoreData5::issueTextAtomUsingText(text)
        end

        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return CoreData5::issueUrlAtomUsingUrl(url)
        end

        if type == "aion-point" then
            location = CoreDataUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return CoreData5::issueAionPointAtomUsingLocation(location)
        end

        if type == "marble" then
            marble = CoreDataUtils::interactivelyDropNewMarbleFileOnDesktop()
            return CoreData5::issueMarbleAtom(marble["uuid"])
        end

        if type == "managed-folder" then
            return CoreData5::issueFolderAtom()
        end

        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (use '#{SecureRandom.hex(6)}' if need one): ")
            return nil if uniquestring == ""
            return CoreData5::issueUniqueStringAtomUsingString(uniquestring)
        end

        raise "[CoreData5] [D2BDF2BC-D0B8-4D76-B00F-9EBB328D4CF7, type: #{type}]"
    end

    # -- Update ------------------------------------------

    # CoreData5::accessWithOptionToEdit(atom): Atom or null
    def self.accessWithOptionToEdit(atom)
        if atom["type"] == "description-only" then
            puts "atom: description-only (atom payload is empty)"
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if atom["type"] == "text" then
            puts atom["payload"].strip
            if LucilleCore::askQuestionAnswerAsBoolean("> edit ? ", false) then
                text = CoreDataUtils::editTextSynchronously(atom["payload"])
                atom["payload"] = text
                return atom
            end
            return nil
        end
        if atom["type"] == "url" then
            CoreDataUtils::openUrlUsingSafari(atom["payload"])
            if LucilleCore::askQuestionAnswerAsBoolean("> edit url ? ", false) then
                url = LucilleCore::askQuestionAnswerAsString("url (empty to abort) : ")
                if url.size > 0 then
                    atom["payload"] = url
                    return atom
                end
            end
            return nil
        end
        if atom["type"] == "aion-point" then
            AionCore::exportHashAtFolder(CoreDataElizabeth.new(), atom["payload"], "/Users/pascal/Desktop")
            if LucilleCore::askQuestionAnswerAsBoolean("> edit aion-point ? ", false) then
                location = CoreDataUtils::interactivelySelectDesktopLocationOrNull()
                return nil if location.nil?
                nhash = CoreDataUtils::locationToAionRootNamedHash(location)
                CoreDataUtils::moveFileToBinTimeline(location)
                atom["payload"] = nhash
                return atom
            end
            return nil
        end
        if atom["type"] == "marble" then
            marbleId = atom["payload"]
            location = CoreDataUtils::marbleLocationOrNullUsingCache(marbleId)
            if location then
                puts "found marble at: #{location}"
                system("open '#{File.dirname(location)}'")
                return nil
            end
            puts "I could not find the location of the marble in the cache"
            return nil if !LucilleCore::askQuestionAnswerAsBoolean("Would you like me to use the Force ? ")
            location = CoreDataUtils::marbleLocationOrNullUseTheForce(marbleId)
            if location then
                puts "found marble at: #{location}"
                system("open '#{File.dirname(location)}'")
                return nil
            end
            return nil
        end
        if atom["type"] == "managed-folder" then
            foldername = atom["payload"]
            folderpath = "#{CoreDataUtils::foldersRepositoryPath()}/#{foldername}"
            puts "opening core data folder #{folderpath}"
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if atom["type"] == "unique-string" then
            payload = atom["payload"]
            puts "unique string: #{payload}"
            location = CoreDataUtils::atlas(payload)
            if location then
                puts "location: #{location}"
                if LucilleCore::askQuestionAnswerAsBoolean("open ? ", true) then
                    system("open '#{location}'")
                end
            else
                puts "[CoreData5] Could not find location for unique string: #{payload}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        raise "(503e9474-bb0c-4eba-8270-850d99d8238b, uuid: #{uuid})"
    end

    # -- Data ------------------------------------------

    # CoreData5::toString(atom)
    def self.toString(atom)
        "[atom] #{atom["type"]}"
    end

    # CoreData5::atomPayloadToTextOrNull(atom)
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
        if atom["type"] == "marble" then
            return "Atom (marble): #{atom["payload"]}"
        end
        if atom["type"] == "managed-folder" then
            return "Atom (managed-folder): #{atom["payload"]}"
        end
        if atom["type"] == "unique-string" then
            return "Atom (unique-string): #{atom["payload"]}"
        end
        raise "(1EDB15D2-9125-4947-924E-B24D5E67CAE3, atom: #{atom})"
    end

    # CoreData5::fsck(atom) : Boolean
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
            return AionFsck::structureCheckAionHash(CoreDataElizabeth.new(), nhash)
        end
        if atom["type"] == "marble" then
            return true
        end
        if atom["type"] == "managed-folder" then
            foldername = atom["payload"]
            return File.exists?("#{CoreDataUtils::foldersRepositoryPath()}/#{foldername}")
        end
        if atom["type"] == "unique-string" then
            # Technically we should be checking if the target exists, but that takes too long
            return true
        end
        raise "(F446B5E4-A795-415D-9D33-3E6B5E8E0AFF: non recognised atom type: #{atom})"
    end
end

