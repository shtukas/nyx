
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

    # Librarian0Utils::commitFileReturnPartsHashsImproved(filepath, lambdaBlobCommitReturnNhash)
    def self.commitFileReturnPartsHashsImproved(filepath, lambdaBlobCommitReturnNhash)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)
        hashes = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            hashes << lambdaBlobCommitReturnNhash.call(blob)
        end
        f.close()
        hashes
    end

    # Librarian0Utils::uniqueStringLocationUsingFileSystemSearchOrNull(uniquestring)
    def self.uniqueStringLocationUsingFileSystemSearchOrNull(uniquestring)
        roots = [
            "/Users/pascal/Desktop",
            "/Users/pascal/Galaxy/Documents",
            Librarian16AionExport::aionExportFolder()
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
        XCache::set(nhash, blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = XCache::getOrNull(nhash)
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

    # Librarian5Atoms::makeDescriptionOnlyAtom() # Atom
    def self.makeDescriptionOnlyAtom()
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "description-only",
            "payload"     => nil
        }
    end

    # Librarian5Atoms::makeTextAtomUsingText(text) # Atom
    def self.makeTextAtomUsingText(text)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Atom",
            "unixtime" => Time.new.to_f,
            "type"     => "text",
            "payload"  => Librarian12LocalBlobsService::putBlob(text)
        }
    end

    # Librarian5Atoms::makeUrlAtomUsingUrl(url) # Atom
    def self.makeUrlAtomUsingUrl(url)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "url",
            "payload"     => url
        }
    end

    # Librarian5Atoms::makeAionPointAtomUsingLocation(location) # Atom
    def self.makeAionPointAtomUsingLocation(location)
        raise "[Librarian: error: 2a6077f3-6572-4bde-a435-04604590c8d8]" if !File.exists?(location) # Caller needs to ensure file exists.
        rootnhash = AionCore::commitLocationReturnHash(Librarian14ElizabethLocalStandard.new(), location)
        Librarian0Utils::moveFileToBinTimeline(location)
        {
            "uuid"      => SecureRandom.uuid,
            "mikuType"  => "Atom",
            "unixtime"  => Time.new.to_f,
            "type"      => "aion-point",
            "rootnhash" => rootnhash
        }
    end

    # Librarian5Atoms::makeUniqueStringAtomUsingString(uniqueString) # Atom
    def self.makeUniqueStringAtomUsingString(uniqueString)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "unique-string",
            "payload"     => uniqueString
        }
    end

    # Librarian5Atoms::makeLG001Atom(lg001Code)
    def self.makeLG001Atom(lg001Code)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "local-group-001",
            "payload"     => lg001Code
        }
    end

    # Librarian5Atoms::makeLG002Atom(indx)
    def self.makeLG002Atom(indx)
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Atom",
            "unixtime"    => Time.new.to_f,
            "type"        => "local-group-002",
            "payload"     => indx
        }
    end

    # Librarian5Atoms::interactivelyIssueNewAtomOrNull()
    def self.interactivelyIssueNewAtomOrNull()

        commitMaybeAtomAndReturn = lambda{|atom|
            return nil if atom.nil?
            Librarian6Objects::commit(atom)
            Librarian21Fsck::fsckExitAtFirstFailureAtomuuid({}, atom["uuid"])
            atom
        }

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["description-only (default)", "text", "url", "aion-point", "local-group-002", "unique-string"])

        if type.nil? or type == "description-only (default)" then
            atom = Librarian5Atoms::makeDescriptionOnlyAtom()
            return commitMaybeAtomAndReturn.call(atom)
        end

        if type == "text" then
            text = Librarian0Utils::editTextSynchronously("")
            atom = Librarian5Atoms::makeTextAtomUsingText(text)
            return commitMaybeAtomAndReturn.call(atom)
        end

        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            atom = Librarian5Atoms::makeUrlAtomUsingUrl(url)
            return commitMaybeAtomAndReturn.call(atom)
        end

        if type == "aion-point" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            atom = Librarian5Atoms::makeAionPointAtomUsingLocation(location)
            return commitMaybeAtomAndReturn.call(atom)
        end

        if type == "local-group-002" then
            indx = LucilleCore::askQuestionAnswerAsString("Number between 000001 and 999999: ")
            atom = Librarian5Atoms::makeLG002Atom(indx)
            return commitMaybeAtomAndReturn.call(atom)
        end

        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (use 'Nx01-#{SecureRandom.hex(6)}' if need one): ")
            return nil if uniquestring == ""
            atom = Librarian5Atoms::makeUniqueStringAtomUsingString(uniquestring)
            return commitMaybeAtomAndReturn.call(atom)
        end

        raise "[Librarian] [D2BDF2BC-D0B8-4D76-B00F-9EBB328D4CF7, type: #{type}]"
    end

    # -- Data ------------------------------------------

    # Librarian5Atoms::toString(atom)
    def self.toString(atom)
        "(atom) #{atom["type"]}"
    end

    # Librarian5Atoms::atomPayloadToTextOrNull(atom)
    def self.atomPayloadToTextOrNull(atom)
        if atom["type"] == "description-only" then
            return nil
        end
        if atom["type"] == "text" then
            text = [
                "-- Atom (text) --",
                Librarian12LocalBlobsService::getBlobOrNull(atom["payload"]).strip,
            ].join("\n")
            return text
        end
        if atom["type"] == "url" then
            return "Atom (url): #{atom["payload"]}"
        end
        if atom["type"] == "aion-point" then
            return "Atom (aion-point): #{atom["rootnhash"]}"
        end
        if atom["type"] == "local-group-002" then
            return "Atom (local-group-002): #{atom["payload"]}"
        end
        if atom["type"] == "unique-string" then
            return "Atom (unique-string): #{atom["payload"]}"
        end
        raise "(1EDB15D2-9125-4947-924E-B24D5E67CAE3, atom: #{atom})"
    end

    # Librarian5Atoms::uniqueStringIsInAionPointObject(object, uniquestring)
    def self.uniqueStringIsInAionPointObject(object, uniquestring)
        if object["aionType"] == "indefinite" then
            return false
        end
        if object["aionType"] == "directory" then
            if object["name"].downcase.include?(uniquestring.downcase) then
                return true
            end
            return object["items"].any?{|nhash| Librarian5Atoms::uniqueStringIsInNhash(nhash, uniquestring) }
        end
        if object["aionType"] == "file" then
            return object["name"].downcase.include?(uniquestring.downcase)
        end
    end

    # Librarian5Atoms::uniqueStringIsInNhash(nhash, uniquestring)
    def self.uniqueStringIsInNhash(nhash, uniquestring)
        # This function will cause all the objects from all aion-structures to remain alive on the local cache
        # but doesn't download the data blobs

        # This function is memoised
        answer = XCache::getOrNull("4cd81dd8-822b-4ec7-8065-728e2dfe2a8a:#{nhash}:#{uniquestring}")
        if answer then
            return JSON.parse(answer)[0]
        end
        object = AionCore::getAionObjectByHash(Librarian14ElizabethLocalStandard.new(), nhash)
        answer = Librarian5Atoms::uniqueStringIsInAionPointObject(object, uniquestring)
        XCache::set("4cd81dd8-822b-4ec7-8065-728e2dfe2a8a:#{nhash}:#{uniquestring}", JSON.generate([answer]))
        answer
    end

    # -- Operations ------------------------------------------

    # Librarian5Atoms::findAndAccessUniqueString(uniquestring)
    def self.findAndAccessUniqueString(uniquestring)
        puts "unique string: #{uniquestring}"
        location = Librarian0Utils::uniqueStringLocationUsingFileSystemSearchOrNull(uniquestring)
        if location then
            puts "location: #{location}"
            if LucilleCore::askQuestionAnswerAsBoolean("open ? ", true) then
                system("open '#{location}'")
            end
            return
        end
        puts "Unique string not found in Galaxy"
        puts "Looking inside aion-points..."
        puts "" # To accomodate Utils::putsOnPreviousLine
        Librarian6Objects::operationalAtoms()
            .each{|atom|
                next if atom["type"] != "aion-point"
                nhash = atom["rootnhash"]
                Utils::putsOnPreviousLine("checking atom #{atom["uuid"]}")
                if Librarian5Atoms::uniqueStringIsInNhash(nhash, uniquestring) then
                    puts "I have found the unique string in atom aion-point: #{JSON.pretty_generate(atom)}"
                    puts "Accessing the atom"
                    Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
                    return
                end
            }

        puts "I could not find the unique string inside aion-points"
        LucilleCore::pressEnterToContinue()
    end

    # Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
    def self.accessWithOptionToEditOptionalAutoMutation(atom)
        if atom["type"] == "description-only" then
            puts "atom: description-only (atom payload is empty)"
            LucilleCore::pressEnterToContinue()
        end
        if atom["type"] == "text" then
            text1 = Librarian12LocalBlobsService::getBlobOrNull(atom["payload"])
            text2 = Librarian0Utils::editTextSynchronously(text1)
            if text1 != text2 then
                atom["payload"] = Librarian12LocalBlobsService::putBlob(text2)
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
            nhash = atom["rootnhash"]
            exportFolder = Librarian16AionExport::atomToExistingExportFolderpathOrNull(atom)
            if exportFolder.nil? then
                exportFolder = Librarian16AionExport::atomToNewExportFolderpath(atom)
                AionCore::exportHashAtFolder(Librarian14ElizabethLocalStandard.new(), nhash, exportFolder)
            end
            system("open '#{exportFolder}'")
        end
        if atom["type"] == "local-group-001" then
            puts "I do not know how to access local-group-001"
            LucilleCore::pressEnterToContinue()
        end
        if atom["type"] == "local-group-002" then
            puts "Local Group 002, code: #{atom["payload"]}"
            puts "Access file on drive"
            LucilleCore::pressEnterToContinue()
        end
        if atom["type"] == "unique-string" then
            uniquestring = atom["payload"]
            Librarian5Atoms::findAndAccessUniqueString(uniquestring)
        end
    end
end

class Librarian6Objects

    # Librarian6Objects::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Databases/objects.sqlite3"
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

    # Librarian6Objects::operationalAtoms() # Array[Atom]
    def self.operationalAtoms()
        objectToAtomOrNull = lambda{|item|
            # The logic of this extraction mirror that of fsck
            return nil if item["mikuType"] == "Atom"
            raise "(error: d3063b74-da49-4c19-ab19-ed2c2268a7ac)" if item["atomuuid"].nil?
            atomuuid = item["atomuuid"]
            Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        }

        Librarian6Objects::objects()
            .map{|item| objectToAtomOrNull.call(item) }
            .compact
    end
end

# ---------------------------------------------------------------------------
# Local blob services and Elizabeth
# ---------------------------------------------------------------------------

class Librarian12LocalBlobsService

    # Librarian12LocalBlobsService::datablobsRepository()
    def self.datablobsRepository()
        "/Users/pascal/Galaxy/DataBank/Librarian/Datablobs"
    end

    # -----------------------------------------------------------------------------

    # Librarian12LocalBlobsService::putBlob(blob) # nhash
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = "#{Librarian12LocalBlobsService::datablobsRepository()}/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # Librarian12LocalBlobsService::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath = "#{Librarian12LocalBlobsService::datablobsRepository()}/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            return blob
        end
        nil
    end
end

class Librarian14ElizabethLocalStandard

    def initialize()
    end

    def commitBlob(blob)
        Librarian12LocalBlobsService::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = Librarian12LocalBlobsService::getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 69f99c35-5560-44fb-b463-903e9850bc93) could not find blob, nhash: #{nhash}"
        raise "(error: 0573a059-5ca2-431d-a4b4-ab8f4a0a34fe, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 36d664ef-0731-4a00-ba0d-b5a7fb7cf941) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

# ---------------------------------------------------------------------------
# 
# ---------------------------------------------------------------------------

=begin 

Tx45 {
    "uuid"     : String
    "atomuuid" : String
    "exportId" : String # Used for foldername
}

=end

class Librarian16AionExport

    # Librarian16AionExport::aionExportFolder()
    def self.aionExportFolder()
        "/Users/pascal/x-space/Aion-Exports"
    end

    # Librarian16AionExport::issueTx45(uuid, atomuuid, exportId)
    def self.issueTx45(uuid, atomuuid, exportId)
        item = {
            "uuid"       => uuid,
            "atomuuid"   => atomuuid,
            "exportId" => exportId
        }
        BTreeSets::set(nil, "90B9B2B7-6E04-44C4-80D2-D7AA5F3428CC", item["uuid"], item)
    end

    # Librarian16AionExport::getTx45ForAtomOrNull(atom)
    def self.getTx45ForAtomOrNull(atom)
        BTreeSets::values(nil, "90B9B2B7-6E04-44C4-80D2-D7AA5F3428CC")
            .select{|item| item["atomuuid"] == atom["uuid"] }
            .first
    end

    # Librarian16AionExport::getTx45ByDispatchIdOrNull(exportId)
    def self.getTx45ByDispatchIdOrNull(exportId)
        BTreeSets::values(nil, "90B9B2B7-6E04-44C4-80D2-D7AA5F3428CC")
            .select{|item| item["exportId"] == exportId }
            .first
    end

    # Librarian16AionExport::exportIdToExistingExportFolderpathOrNull(exportId)
    def self.exportIdToExistingExportFolderpathOrNull(exportId)
        # First we look for a folder with that dispatch id trace, if we find one we return 
        # it otherwise we make one
        LucilleCore::locationsAtFolder(Librarian16AionExport::aionExportFolder()).each{|location|
            if File.basename(location).include?(exportId) then
                return location
            end
        }
        nil
    end

    # Librarian16AionExport::atomToExistingExportFolderpathOrNull(atom)
    def self.atomToExistingExportFolderpathOrNull(atom)
        item = Librarian16AionExport::getTx45ForAtomOrNull(atom)
        return nil if item.nil?
        puts "Found aion dispatch item"
        puts JSON.pretty_generate(item)
        folderpath = Librarian16AionExport::exportIdToExistingExportFolderpathOrNull(item["exportId"])
        return nil if folderpath.nil?
        puts "Found existing folderpath: #{folderpath}"
        folderpath 
    end

    # Librarian16AionExport::atomToNewExportFolderpath(atom)
    def self.atomToNewExportFolderpath(atom)
        # Let's try and determine a description for that atom
        description = nil
        Librarian6Objects::objects().each{|object|
            next if object["atomuuid"].nil?
            next if object["atomuuid"] != atom["uuid"]
            description = LxFunction::function("description", object)
            break
        }
        exportId = SecureRandom.hex[0, 8]
        folderpath = 
            if description then
                "#{Librarian16AionExport::aionExportFolder()}/#{Utils::sanitiseStringForFilenaming(description)} (#{exportId})"
            else
                "#{Librarian16AionExport::aionExportFolder()}/(#{exportId})"
            end
        FileUtils.mkdir(folderpath)
        Librarian16AionExport::issueTx45(SecureRandom.uuid, atom["uuid"], exportId)
        folderpath
    end

    # Librarian16AionExport::doPickups()
    def self.doPickups()
        BTreeSets::values(nil, "90B9B2B7-6E04-44C4-80D2-D7AA5F3428CC").each{|exportControlItem|
            #puts JSON.pretty_generate(exportControlItem)
            
            folderpath1 = Librarian16AionExport::exportIdToExistingExportFolderpathOrNull(exportControlItem["exportId"])
            if folderpath1.nil? then
                puts "Export folder not found"
                puts "Destroying dispatch item: #{JSON.pretty_generate(exportControlItem)}"
                BTreeSets::destroy(nil, "90B9B2B7-6E04-44C4-80D2-D7AA5F3428CC", exportControlItem["uuid"])
                next
            end
            locations2 = LucilleCore::locationsAtFolder(folderpath1)
            if locations2.size == 0 then
                puts "There is export folderpath: #{folderpath1}"
                puts " > But I cannot see anything inside."
                LucilleCore::pressEnterToContinue()
                next
            end
            if locations2.size > 1 then
                puts "There is export folderpath: #{folderpath1}"
                puts "I can find more than one location inside."
                LucilleCore::pressEnterToContinue()
                next
            end
            
            location3 = locations2.first

            next if !LucilleCore::askQuestionAnswerAsBoolean("process '#{location3}' ? ", true)

            atomuuid = exportControlItem["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            if atom.nil? then
                puts "I could not find an atom for atomuuid: #{atomuuid}"
                puts "Destroying the export control item"
                LucilleCore::pressEnterToContinue()
                BTreeSets::destroy(nil, "90B9B2B7-6E04-44C4-80D2-D7AA5F3428CC", exportControlItem["uuid"])
                next
            end

            rootnhash = AionCore::commitLocationReturnHash(Librarian14ElizabethLocalStandard.new(), location3)
            if rootnhash != atom["rootnhash"] then
                atom["rootnhash"] = rootnhash
                #puts "atom (updated): #{JSON.generate(atom)}"
                Librarian6Objects::commit(atom)
            end
            LucilleCore::removeFileSystemLocation(folderpath1)
            BTreeSets::destroy(nil, "90B9B2B7-6E04-44C4-80D2-D7AA5F3428CC", exportControlItem["uuid"])
        }
    end
end

class Libriarian16SpecialCircumstances

    # Libriarian16SpecialCircumstances::atomLandingPresentation(atomuuid)
    def self.atomLandingPresentation(atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        if atom.nil? then
            puts "warning: I could not find the atom for this item (atomuuid: #{atomuuid})"
            LucilleCore::pressEnterToContinue()
        else
            if text = Librarian5Atoms::atomPayloadToTextOrNull(atom) then
                puts text
            end
        end
    end

    # Libriarian16SpecialCircumstances::accessAtom(atomuuid)
    def self.accessAtom(atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        return if atom.nil?
        return if atom["type"] == "description-only"
        Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
    end

    # Libriarian16SpecialCircumstances::atomTypeForToStrings(prefix, atomuuid)
    def self.atomTypeForToStrings(prefix, atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        return "" if atom.nil?
        "#{prefix}(#{atom["type"]})"
    end
end

class Librarian17PrimitiveFilesAndCarriers

    # Librarian17PrimitiveFilesAndCarriers::readPrimitiveFileOrNull(filepath) # [dottedExtension, nhash, parts]
    def self.readPrimitiveFileOrNull(filepath)
        return nil if !File.exists?(filepath)
        return nil if !File.file?(filepath)
 
        dottedExtension = File.extname(filepath)
 
        nhash = Librarian0Utils::filepathToContentHash(filepath)
 
        lambdaBlobCommitReturnNhash = lambda {|blob|
            Librarian12LocalBlobsService::putBlob(blob)
        }
        parts = Librarian0Utils::commitFileReturnPartsHashsImproved(filepath, lambdaBlobCommitReturnNhash)
 
        return [dottedExtension, nhash, parts]
    end

    # Librarian17PrimitiveFilesAndCarriers::exportPrimitiveFileAtLocation(someuuid, dottedExtension, parts, location) # targetFilepath
    def self.exportPrimitiveFileAtLocation(someuuid, dottedExtension, parts, location)
        targetFilepath = "#{location}/#{someuuid}#{dottedExtension}"
        File.open(targetFilepath, "w"){|f|  
            parts.each{|nhash|
                blob = Librarian12LocalBlobsService::getBlobOrNull(nhash)
                raise "(error: c3e18110-2d9a-42e6-9199-6f8564cf96d2)" if blob.nil?
                f.write(blob)
            }
        }
        targetFilepath
    end

    # Librarian17PrimitiveFilesAndCarriers::carrierContents(owneruuid)
    def self.carrierContents(owneruuid)
        Librarian6Objects::getObjectsByMikuType("Nx60")
            .select{|claim| claim["owneruuid"] == owneruuid }
            .map{|claim| claim["targetuuid"] }
            .map{|uuid| Librarian6Objects::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # Librarian17PrimitiveFilesAndCarriers::exportCarrier(item)
    def self.exportCarrier(item)
        exportFolderpath = "/Users/pascal/Desktop/#{item["description"]} (#{item["uuid"][-8, 8]})"
        FileUtils.mkdir(exportFolderpath)
        Librarian17PrimitiveFilesAndCarriers::carrierContents(item["uuid"])
            .each{|ix|
                _, dottedExtension, nhash, parts = ix["iam"]
                Librarian17PrimitiveFilesAndCarriers::exportPrimitiveFileAtLocation(ix["uuid"], dottedExtension, parts, exportFolderpath)
            }
    end

    # Librarian17PrimitiveFilesAndCarriers::uploadCarrierOrNothing(uuid)
    def self.uploadCarrierOrNothing(uuid)
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

class Librarian21Fsck

    # Librarian21Fsck::fsckAtomReturnBoolean(atom) : Boolean
    def self.fsckAtomReturnBoolean(atom)
        puts JSON.pretty_generate(atom)
        if atom["type"] == "description-only" then
            return true
        end
        if atom["type"] == "text" then
            return !Librarian12LocalBlobsService::getBlobOrNull(atom["payload"]).nil?
        end
        if atom["type"] == "url" then
            return true
        end
        if atom["type"] == "aion-point" then
            nhash = atom["rootnhash"]
            status = AionFsck::structureCheckAionHash(Librarian14ElizabethLocalStandard.new(), nhash)
            return status
        end
        if atom["type"] == "unique-string" then
            # Technically we should be checking if the target exists, but that takes too long
            return true
        end
        if atom["type"] == "local-group-001" then
            puts "assuming correct"
            return true
        end
        if atom["type"] == "local-group-002" then
            puts "assuming correct"
            return true
        end
        raise "(F446B5E4-A795-415D-9D33-3E6B5E8E0AFF: non recognised atom type: #{atom})"
    end

    # Librarian21Fsck::fsckExitAtFirstFailureAtomuuid(item, atomuuid)
    def self.fsckExitAtFirstFailureAtomuuid(item, atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        if atom.nil? then
            puts "(error: b3fde618-5d36-4f50-b1dc-cbf29bc4d61e, atom not found)".red
            puts "item:".red
            puts JSON.pretty_generate(item).red
            exit
        end
        status = Librarian21Fsck::fsckAtomReturnBoolean(atom)
        if !status then 
            puts "(error: d4f39eb1-7a3b-4812-bb99-7adeb9d8c37c, atom fsck returned false)".red
            puts "item:".red
            puts JSON.pretty_generate(item).red
            puts "atom:".red
            puts JSON.pretty_generate(atom).red
            exit
        end
    end

    # Librarian21Fsck::fsckExitAtFirstFailureIamValue(item, iAmValue)
    def self.fsckExitAtFirstFailureIamValue(item, iAmValue)
        if !Nx111::iamTypes().include?(iAmValue[0]) then
            puts "Nx100 has an incorrect iam value type".red
            puts JSON.pretty_generate(item).red
            exit
        end
        if iAmValue[0] == "navigation" then
            return
        end
        if iAmValue[0] == "log" then
            return
        end
        if iAmValue[0] == "description-only" then
            return
        end
        if iAmValue[0] == "text" then
            nhash = iAmValue[1]
            if Librarian12LocalBlobsService::getBlobOrNull(nhash).nil? then
                puts "Nx100, could not find the text data".red
                puts JSON.pretty_generate(item).red
                exit
            end
            return
        end
        if iAmValue[0] == "url" then
            return
        end
        if iAmValue[0] == "aion-point" then
            rootnhash = iAmValue[1]
            status = AionFsck::structureCheckAionHash(Librarian14ElizabethLocalStandard.new(), rootnhash)
            if !status then
                puts "Nx100, could not validate aion-point".red
                puts JSON.pretty_generate(item).red
                exit
            end
            return
        end
        if iAmValue[0] == "unique-string" then
            return
        end
        if iAmValue[0] == "primitive-file" then
            _, dottedExtension, nhash, parts = iAmValue
            if dottedExtension[0, 1] != "." then
                puts "Nx100".red
                puts JSON.pretty_generate(item).red
                puts "primitive parts, dotted extension is malformed".red
                exit
            end
            parts.each{|nhash|
                blob = Librarian12LocalBlobsService::getBlobOrNull(nhash)
                next if blob
                puts "Nx100".red
                puts JSON.pretty_generate(item).red
                puts "primitive parts, nhash not found: #{nhash}".red
                exit
            }
            return
        end
        if iAmValue[0] == "carrier-of-primitive-files" then
            return
        end
        if iAmValue[0] == "local-group-001" then
            return
        end
        if iAmValue[0] == "local-group-002" then
            return
        end
        if iAmValue[0] == "Dx8Unit" then
            configuration = iAmValue[1]

            if configuration["status"] == "standard" then
                unitId = configuration["unitId"]
                rootnhash = configuration["rootnhash"]
                status = AionFsck::structureCheckAionHash(Librarian24ElizabethForDx8Units.new(unitId), rootnhash)
                if !status then
                    puts "Nx100, could not validate Dx8Unit".red
                    puts JSON.pretty_generate(item).red
                    exit
                end
                return
            end

            raise "(error: 5a970959-ca52-40e4-b291-056c9c500575): #{item}, #{iAmValue}"
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect iam value: #{iAmValue})"
    end

    # Librarian21Fsck::fsckExitAtFirstFailureLibrarianMikuObject(item)
    def self.fsckExitAtFirstFailureLibrarianMikuObject(item)
        if item["mikuType"] == "Nx60" then
            return
        end
        if item["mikuType"] == "Nx100" then
            if item["iam"].nil? then
                puts "Nx100 has not iam value".red
                puts JSON.pretty_generate(item).red
                exit
            end
            iAmValue = item["iam"]
            puts JSON.pretty_generate(iAmValue)
            Librarian21Fsck::fsckExitAtFirstFailureIamValue(item, iAmValue)
            return
        end
        if item["mikuType"] == "TxAttachment" then
            Librarian21Fsck::fsckExitAtFirstFailureAtomuuid(item, item["atomuuid"])
            return
        end
        if item["mikuType"] == "TxDated" then
            Librarian21Fsck::fsckExitAtFirstFailureAtomuuid(item, item["atomuuid"])
            return
        end
        if item["mikuType"] == "TxFloat" then
            Librarian21Fsck::fsckExitAtFirstFailureAtomuuid(item, item["atomuuid"])
            return
        end
        if item["mikuType"] == "TxFyre" then
            Librarian21Fsck::fsckExitAtFirstFailureAtomuuid(item, item["atomuuid"])
            return
        end
        if item["mikuType"] == "TxTodo" then
            Librarian21Fsck::fsckExitAtFirstFailureAtomuuid(item, item["atomuuid"])
            return
        end
        if item["mikuType"] == "Wave" then
            Librarian21Fsck::fsckExitAtFirstFailureAtomuuid(item, item["atomuuid"])
            return
        end
        puts JSON.pretty_generate(item).red
        raise "(error: a10f607b-4bc5-4ed2-ac31-dfd72c0108fc)"
    end

    # Librarian21Fsck::fsckExitAtFirstFailure()
    def self.fsckExitAtFirstFailure()
        Librarian6Objects::objects()
        .sort{|o1, o2| 
            o1["unixtime"] <=> o2["unixtime"] 
        }
        .reverse
        .select{|item|
            item["mikuType"] != "Atom"
        }
        .each{|item|
            puts JSON.pretty_generate(item)
            Librarian21Fsck::fsckExitAtFirstFailureLibrarianMikuObject(item)
        }
        puts "Fsck completed successfully".green
        LucilleCore::pressEnterToContinue()
    end
end

# ---------------------------------------------------------------------------
# Dx8Unit blob services and Elizabeth
# ---------------------------------------------------------------------------

class Librarian23Dx8UnitsBlobsService

    # Librarian23Dx8UnitsBlobsService::gsvRepository()
    def self.gsvRepository()
        "/Volumes/GSV-Lucille/Data/Pascal/Nyx-Librarian-Dx8Units"
    end

    # Librarian23Dx8UnitsBlobsService::gsvDriveIsPlugged()
    def self.gsvDriveIsPlugged()
        File.exists?(Librarian23Dx8UnitsBlobsService::gsvRepository())
    end

    # Librarian23Dx8UnitsBlobsService::ensureGSVRepository()
    def self.ensureGSVRepository()
        if !Librarian23Dx8UnitsBlobsService::gsvDriveIsPlugged() then
            puts "I need Lucille, could you plug the drive please ?"
            LucilleCore::pressEnterToContinue()
        end
        if !Librarian23Dx8UnitsBlobsService::gsvDriveIsPlugged() then
            puts "I needed Lucille 😞. Exiting."
            exit
        end
    end

    # Librarian23Dx8UnitsBlobsService::dx8UnitFolder(dx8UnitId)
    def self.dx8UnitFolder(dx8UnitId)
        "/Volumes/GSV-Lucille/Data/Pascal/Nyx-Librarian-Dx8Units/#{dx8UnitId}"
    end

    # -----------------------------------------------------------------------------

    # Librarian23Dx8UnitsBlobsService::putBlob(dx8UnitId, blob) # nhash
    def self.putBlob(dx8UnitId, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = "#{Librarian23Dx8UnitsBlobsService::dx8UnitFolder(dx8UnitId)}/#{nhash[7, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # Librarian23Dx8UnitsBlobsService::getBlobOrNull(dx8UnitId, nhash)
    def self.getBlobOrNull(dx8UnitId, nhash)
        filepath = "#{Librarian23Dx8UnitsBlobsService::dx8UnitFolder(dx8UnitId)}/#{nhash[7, 2]}/#{nhash}.data"
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            return blob
        end
        nil
    end
end

class Librarian24ElizabethForDx8Units

    # @dx8UnitId

    def initialize(dx8UnitId)
        Librarian23Dx8UnitsBlobsService::ensureGSVRepository()
        @dx8UnitId = dx8UnitId
    end

    def commitBlob(blob)
        Librarian23Dx8UnitsBlobsService::putBlob(@dx8UnitId, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = Librarian23Dx8UnitsBlobsService::getBlobOrNull(@dx8UnitId, nhash)
        return blob if blob
        puts "(error: 226a8374-bcc9-4b8c-97cd-ec57df17003d) could not find blob, nhash: #{nhash}"
        raise "(error: ae3735b2-87a8-4e13-b2ca-f5b93069e297, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 4b6590da-c62c-43e8-90fc-3893f0e4ac7d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

# ---------------------------------------------------------------------------
# 
# ---------------------------------------------------------------------------

class LibrarianCLI

    # LibrarianCLI::main()
    def self.main()
        loop {
            system("clear")
            actions = [
                "run fsck", 
                "show object", 
                "edit object",
                "destroy object by uuid",
                "prob blob", 
                "echo blob", 
                "do aion-points pickups",
                "exit"
            ]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action:", actions)
            break if action.nil?

            if action == "run fsck" then
                Librarian21Fsck::fsckExitAtFirstFailure()
            end
            if action == "show object" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = Librarian6Objects::getObjectByUUIDOrNull(uuid)
                if object then
                    puts JSON.pretty_generate(object)
                    LucilleCore::pressEnterToContinue()
                else
                    puts "I could not find an object with this uuid"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if action == "edit object" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = Librarian6Objects::getObjectByUUIDOrNull(uuid)
                if object then
                    object = JSON.parse(Utils::editTextSynchronously(JSON.pretty_generate(object)))
                    puts JSON.pretty_generate(object)
                    if LucilleCore::askQuestionAnswerAsBoolean("confirm ? ") then
                        Librarian6Objects::commit(object)
                    end
                else
                    puts "I could not find an object with this uuid"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if action == "destroy object by uuid" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                Librarian6Objects::destroy(uuid)
            end
            if action == "prob blob" then
                nhash = LucilleCore::askQuestionAnswerAsString("nhash: ")
                blob = Librarian12LocalBlobsService::getBlobOrNull(nhash)
                if blob then
                    puts "Found a blob of size #{blob.size}"
                    LucilleCore::pressEnterToContinue()
                else
                    puts "I could not find a blob with nhash: #{nhash}"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if action == "echo blob" then
                nhash = LucilleCore::askQuestionAnswerAsString("nhash: ")
                blob = Librarian12LocalBlobsService::getBlobOrNull(nhash)
                if blob then
                    puts JSON.pretty_generate(JSON.parse(blob))
                    LucilleCore::pressEnterToContinue()
                else
                    puts "I could not find a blob with nhash: #{nhash}"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if action == "do aion-points pickups" then
                Librarian16AionExport::doPickups()
            end
            if action == "exit" then
                break
            end
        }
    end
end


