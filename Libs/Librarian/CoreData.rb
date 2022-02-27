# require "/Users/pascal/Galaxy/Software/Librarian/CoreData.rb"

# encoding: UTF-8

# --------------------------------------------------------------------------------------
# This file is used both in Catalyst and Nyx. The Catalyst version is the master version
# --------------------------------------------------------------------------------------

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

class CoreData0Utils

    # CoreData0Utils::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # CoreData0Utils::openUrlUsingSafari(url)
    def self.openUrlUsingSafari(url)
        system("open -a Safari '#{url}'")
    end

    # CoreData0Utils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = "#{SecureRandom.uuid}.txt"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # CoreData0Utils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # CoreData0Utils::atlas(pattern)
    def self.atlas(pattern)
        location = `/Users/pascal/Galaxy/LucilleOS/Binaries/atlas '#{pattern}'`.strip
        (location != "") ? location : nil
    end

    # CoreData0Utils::interactivelyDropNewMarbleFileOnDesktop() # Marble
    def self.interactivelyDropNewMarbleFileOnDesktop()
        marble = {
            "uuid" => SecureRandom.uuid
        }
        filepath = "/Users/pascal/Desktop/nyx-marble.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(marble)) }
        puts "CoreData5 marble generated on the Desktop, drop it at the right location"
        LucilleCore::pressEnterToContinue()
        marble
    end

    # CoreData0Utils::interactivelySelectDesktopLocationOrNull() 
    def self.interactivelySelectDesktopLocationOrNull()
        entries = Dir.entries("/Users/pascal/Desktop").select{|filename| !filename.start_with?(".") }.sort
        locationNameOnDesktop = LucilleCore::selectEntityFromListOfEntitiesOrNull("locationname", entries)
        return nil if locationNameOnDesktop.nil?
        "/Users/pascal/Desktop/#{locationNameOnDesktop}"
    end

    # CoreData0Utils::locationToAionRootNamedHash(location)
    def self.locationToAionRootNamedHash(location)
        raise "[CoreData0Utils: error: a1ac8255-45ed-4347-a898-d306c49f230c, location: #{location}]" if !File.exists?(location) # Caller needs to ensure file exists.
        AionCore::commitLocationReturnHash(LibrarianElizabeth.new(), location)
    end

    # CoreData0Utils::marbleLocationOrNullUseTheForce(uuid)
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

    # CoreData0Utils::marbleLocationOrNullUsingCache(uuid)
    def self.marbleLocationOrNullUsingCache(uuid)
        path = KeyValueStore::getOrNull(nil, "5d7f5599-0b2c-4f16-acc6-a8ead29c272f:#{uuid}")
        return nil if path.nil?
        return nil if !File.exists?(path)
        return nil if File.basename(path) != "nyx-marble.json"
        marble = JSON.parse(IO.read(path))
        return nil if marble["uuid"] != uuid
        path
    end

    # CoreData0Utils::moveFileToBinTimeline(location)
    def self.moveFileToBinTimeline(location)
        return if !File.exists?(location)
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
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "description-only",
            "payload"     => nil
        }
    end

    # CoreData5::issueTextAtomUsingText(text) # Atom
    def self.issueTextAtomUsingText(text)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "text",
            "payload"     => text
        }
    end

    # CoreData5::issueUrlAtomUsingUrl(url) # Atom
    def self.issueUrlAtomUsingUrl(url)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "url",
            "payload"     => url
        }
    end

    # CoreData5::issueAionPointAtomUsingLocation(location) # Atom
    def self.issueAionPointAtomUsingLocation(location)
        raise "[CoreData5: error: 201d6b31-e08b-4e64-955c-807e717138d6]" if !File.exists?(location) # Caller needs to ensure file exists.
        nhash = CoreData0Utils::locationToAionRootNamedHash(location)
        CoreData0Utils::moveFileToBinTimeline(location)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime" => Time.new.to_f,
            "type"     => "aion-point",
            "payload"  => nhash
        }
    end

    # CoreData5::issueUniqueStringAtomUsingString(uniqueString) # Atom
    def self.issueUniqueStringAtomUsingString(uniqueString)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "unique-string",
            "payload"     => uniqueString
        }
    end

    # CoreData5::issueMarbleAtom(marbleId) # Atom
    def self.issueMarbleAtom(marbleId)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "marble",
            "payload"     => marbleId
        }
    end

    # CoreData5::interactivelyCreateNewAtomOrNull()
    def self.interactivelyCreateNewAtomOrNull()

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["description-only (default)", "text", "url", "aion-point", "marble", "unique-string"])

        if type.nil? or type == "description-only (default)" then
            return CoreData5::issueDescriptionOnlyAtom()
        end

        if type == "text" then
            text = CoreData0Utils::editTextSynchronously("")
            return CoreData5::issueTextAtomUsingText(text)
        end

        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return CoreData5::issueUrlAtomUsingUrl(url)
        end

        if type == "aion-point" then
            location = CoreData0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return CoreData5::issueAionPointAtomUsingLocation(location)
        end

        if type == "marble" then
            marble = CoreData0Utils::interactivelyDropNewMarbleFileOnDesktop()
            return CoreData5::issueMarbleAtom(marble["uuid"])
        end

        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (use '#{SecureRandom.hex(6)}' if need one): ")
            return nil if uniquestring == ""
            return CoreData5::issueUniqueStringAtomUsingString(uniquestring)
        end

        raise "[CoreData5] [D2BDF2BC-D0B8-4D76-B00F-9EBB328D4CF7, type: #{type}]"
    end

    # -- Update ------------------------------------------

    # CoreData5::marbleIsInAionPointObject(object, marbleId)
    def self.marbleIsInAionPointObject(object, marbleId)
        if object["aionType"] == "indefinite" then
            return false
        end
        if object["aionType"] == "directory" then
            return object["items"].any?{|nhash| CoreData5::marbleIsInNhash(nhash, marbleId) }
        end
        if object["aionType"] == "file" then
            return false if (object["name"] != "nyx-marble.json")
            nhash = object["hash"]
            blob = LibrarianDataBlobs::getBlobOrNull(nhash)
            return (JSON.parse(blob)["uuid"] == marbleId)
        end
    end

    # CoreData5::marbleIsInNhash(nhash, marbleId)
    def self.marbleIsInNhash(nhash, marbleId)
        # TODO:
        # This function can easily been memoised
        object = AionCore::getAionObjectByHash(LibrarianElizabeth.new(), nhash)
        CoreData5::marbleIsInAionPointObject(object, marbleId)
    end

    # CoreData5::findAndAccessMarble(marbleId)
    def self.findAndAccessMarble(marbleId)
        location = CoreData0Utils::marbleLocationOrNullUsingCache(marbleId)
        if location then
            puts "found marble at: #{location}"
            system("open '#{File.dirname(location)}'")
            return nil
        end
        puts "I could not find the location of the marble in the cache"

        return nil if !LucilleCore::askQuestionAnswerAsBoolean("Would you like me to use the Force ? ")
        location = CoreData0Utils::marbleLocationOrNullUseTheForce(marbleId)
        if location then
            puts "found marble at: #{location}"
            system("open '#{File.dirname(location)}'")
            return nil
        end
        puts "I could not find the marble in Galaxy using the Force"

        # Ok, so now we are going to look inside aion-points
        puts "I am going to look inside aion-points"
        LibrarianObjects::getObjectsByMikuType("Atom")
            .each{|atom|
                next if atom["type"] != "aion-point"
                nhash = atom["payload"]
                if CoreData5::marbleIsInNhash(nhash, marbleId) then
                    puts "I have found the marble in atom aion-point: #{JSON.pretty_generate(atom)}"
                    puts "Accessing the atom"
                    CoreData5::accessWithOptionToEditOptionalUpdate(atom)
                    return
                end
            }

        puts "I could not find the marble inside aion-points"
        LucilleCore::pressEnterToContinue()
        return nil
    end

    # CoreData5::accessWithOptionToEditOptionalUpdate(atom): Atom or null
    # If returns an atom, it's the same atom, mutated, not a new one. 
    # In particular, the uuid is the same
    def self.accessWithOptionToEditOptionalUpdate(atom)
        if atom["type"] == "description-only" then
            puts "atom: description-only (atom payload is empty)"
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if atom["type"] == "text" then
            text1 = atom["payload"]
            text2 = CoreData0Utils::editTextSynchronously(text1)
            if text1 != text2 then
                atom["payload"] = text2
                return atom
            end
            return nil
        end
        if atom["type"] == "url" then
            CoreData0Utils::openUrlUsingSafari(atom["payload"])
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

            # -----------------------------------------------
            # Version 1

            # In the original version we export on the desktop and ask if we want to edit the aion point
            # which is essence means making a new one.

            #AionCore::exportHashAtFolder(LibrarianElizabeth.new(), atom["payload"], "/Users/pascal/Desktop")
            #if LucilleCore::askQuestionAnswerAsBoolean("> edit aion-point ? ", false) then
            #    location = CoreData0Utils::interactivelySelectDesktopLocationOrNull()
            #    return nil if location.nil?
            #    nhash = CoreData0Utils::locationToAionRootNamedHash(location)
            #    CoreData0Utils::moveFileToBinTimeline(location)
            #    atom["payload"] = nhash
            #    return atom
            #end

            exportFolderPath = lambda {|atom|
                uuid = atom["uuid"]
                f1 = Digest::SHA1.hexdigest(uuid)[0, 10]
                "/Users/pascal/Galaxy/Librarian/AionPoints-Exported/#{f1}"
            }

            # -----------------------------------------------
            # Version 2

            # In the updated version we check if there is an already exported version.
            #     If there is one we open that
            #     If there isn't one we make it and open the folder

            exportFolder = exportFolderPath.call(atom)

            if File.exists?(exportFolder) then
                system("open '#{exportFolder}'")
                return
            end

            FileUtils.mkdir(exportFolder)

            AionCore::exportHashAtFolder(LibrarianElizabeth.new(), atom["payload"], exportFolder)

            nyxExportManifest = {
                "exportUnixtime" => Time.new.to_i,
                "atom"           => atom
            }

            nyxExportManifestFilepath = "#{exportFolder}/nyx-export-manifest.json"
            File.open(nyxExportManifestFilepath, "w"){|f| f.puts(JSON.pretty_generate(nyxExportManifest)) }

            system("open '#{exportFolder}'")

            return nil
        end
        if atom["type"] == "marble" then
            marbleId = atom["payload"]
            CoreData5::findAndAccessMarble(marbleId)
            return nil
        end
        if atom["type"] == "unique-string" then
            payload = atom["payload"]
            puts "unique string: #{payload}"
            location = CoreData0Utils::atlas(payload)
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
            return AionFsck::structureCheckAionHash(LibrarianElizabeth.new(), nhash)
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
