
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

class Librarian15BecauseReadWrite

    # Librarian15BecauseReadWrite::utils_getAllTheSubstrings(str)
    def self.utils_getAllTheSubstrings(str)
        indx1 = 0
        substrings = []
        loop {
            break if indx1 >= str.length
            length = 1
            loop {
                break if length > str.length
                substring = str[indx1, length]
                substrings << substring
                length = length + 1
            }
            indx1 = indx1 + 1
        }
        substrings.uniq
    end

    # Librarian15BecauseReadWrite::getLocationForThisTx46IdentiferOrNull(identifier)
    def self.getLocationForThisTx46IdentiferOrNull(identifier)
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop").each{|location|
            return location if location.include?(identifier)
        }
        nil
    end

    # Librarian15BecauseReadWrite::utils_getAllTheTx46IdsLocationPairsFromDesktop()
    def self.utils_getAllTheTx46IdsLocationPairsFromDesktop()
        answer = []
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop").each{|location|
            substrings = Librarian15BecauseReadWrite::utils_getAllTheSubstrings(File.basename(location))
            substring = substrings.select{|ss| XCache::getOrNull("fa2e7141-f1f2-4d2c-b9e9-f51cf6a0da9b:#{ss}") }.first
            if substring then
                pair = {
                    "identifier" => substring,
                    "location"   => location
                }
                answer << pair
            end
        }
        answer
    end

    # Librarian15BecauseReadWrite::extractTopName(operator, rootnhash)
    def self.extractTopName(operator, rootnhash)
        AionCore::getAionObjectByHash(operator, rootnhash)["name"]
    end

    # Librarian15BecauseReadWrite::utils_rewriteThisAionRootWithNewTopName(operator, rootnhash, name1)
    def self.utils_rewriteThisAionRootWithNewTopName(operator, rootnhash, name1)
        aionObject = AionCore::getAionObjectByHash(operator, rootnhash)
        name2 = aionObject["name"]
        # name1 : name we want
        # name2 : name we have, possibly with an .extension
        if File.extname(name2) then
            aionObject["name"] = "#{name1}#{File.extname(name2)}"
        else
            aionObject["name"] = name1
        end
        blob = JSON.generate(aionObject)
        operator.commitBlob(blob)
    end

    # The purpose of this class is to provide edition of objects that have been exported to the desktop

    # Tx46 {
    #     "identifier" : String # This is the fragment that was used as name for the export folder on the desktop
    #     "itemuuid"   : String # UUID of the main object
    # }   

    # When we export, we generate an identififer, put the Tx46 into XCache and let it be. 
    # If somebody wants to update the object, then depending on the type, they will know what to do

    # Librarian15BecauseReadWrite::issueTx46(item)
    def self.issueTx46(item)
        tx = {
            "identifier" => SecureRandom.hex[0, 8],
            "mikuType"   => "Tx46",
            "itemuuid"   => item["uuid"]
        }
        XCache::set("fa2e7141-f1f2-4d2c-b9e9-f51cf6a0da9b:#{tx["identifier"]}", JSON.generate(tx))
        tx
    end

    # Librarian15BecauseReadWrite::issueTx46ReturnIdentifier(item)
    def self.issueTx46ReturnIdentifier(item)
        Librarian15BecauseReadWrite::issueTx46(item)["identifier"]
    end

    # Librarian15BecauseReadWrite::pickupItem(tx46, item, location)
    def self.pickupItem(tx46, item, location)
        puts "> Librarian15BecauseReadWrite::pickupItem(item, location)"
        puts "item: #{JSON.pretty_generate(item)}"
        puts "location: #{location}"
        if item["mikuType"] == "Nx100" then
            if item["iam"][0] == "aion-point" then
                operator = Librarian14ElizabethLocalStandard.new()
                rootnhash1 = AionCore::commitLocationReturnHash(operator, location)
                puts "rootnhash1: #{rootnhash1}"
                rootnhash2 = Librarian15BecauseReadWrite::utils_rewriteThisAionRootWithNewTopName(operator, rootnhash1, item["description"])
                puts "rootnhash2: #{rootnhash2}"
                return if rootnhash1 == rootnhash2
                item["iam"][1] = rootnhash2
                Librarian6Objects::commit(item)
                return
            end
            if item["iam"][0] == "Dx8Unit" then
                configuration = item["iam"][1]
                unitId = configuration["unitId"]
                rootnhash = configuration["rootnhash"]
                operator = Librarian24ElizabethForDx8Units.new(unitId, "standard")
                rootnhash1 = AionCore::commitLocationReturnHash(operator, location)
                puts "rootnhash1: #{rootnhash1}"
                rootnhash2 = Librarian15BecauseReadWrite::utils_rewriteThisAionRootWithNewTopName(operator, rootnhash1, item["description"])
                puts "rootnhash2: #{rootnhash2}"
                return if rootnhash1 == rootnhash2
                configuration["rootnhash"] = rootnhash2
                item["iam"][1] = configuration
                Librarian6Objects::commit(item)
                return
            end
            if item["iam"][0] == "primitive-file" then
                puts "We are not yet picking up modifications of primitive files (#{location})"
                return
            end
            if item["iam"][0] == "carrier-of-primitive-files" then
                # We scan the location and upload any file that wasn't there before

                locations = LucilleCore::locationsAtFolder(location)
                # We make a fiirst pass to ensure everything is a file
                status = locations.all?{|loc| File.file?(loc) }
                if !status then
                    puts "The folder has elements that are not files!"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                locations.each{|filepath|

                    # So..... unlike a regular upload, some of the files in there can already be existing 
                    # primitive files tht were exported.

                    # The nice thing is that primitive files carry their own uuid as Nyx objects.
                    # We can use that to know if the location is an existing primitive file and can be ignored

                    id = File.basename(filepath)[0, "10202204-1516-1710-9579-87e475258c29".size]
                    if Librarian6Objects::getObjectByUUIDOrNull(id) then
                        puts "#{File.basename(filepath)} is already a node"
                        # Note that in this case we are not picking up possible modifications of the primitive files
                    else
                        puts "#{File.basename(filepath)} is new and needs upload"
                        primitiveFileObject = Nx100s::issuePrimitiveFileFromLocationOrNull(filepath)
                        puts "Primitive file:"
                        puts JSON.pretty_generate(primitiveFileObject)
                        puts "Link: (owner: #{item["uuid"]}, file: #{primitiveFileObject["uuid"]})"
                        Nx60s::issueClaim(item["uuid"], primitiveFileObject["uuid"])

                        puts "Writing #{primitiveFileObject["uuid"]}"
                        _, dottedExtension, nhash, parts = primitiveFileObject["iam"]
                        Librarian17PrimitiveFilesAndCarriers::exportPrimitiveFileAtLocation(primitiveFileObject["uuid"], dottedExtension, parts, location)

                        puts "Removing #{filepath}"
                        FileUtils.rm(filepath)
                    end
                }

                return
            end
            raise "(error: 68436fbf-745f-4a02-8912-a04279c122c1) I don't know how to pickup #{item["iam"]}"
        end
    end

    # Librarian15BecauseReadWrite::desktopDataPickups()
    def self.desktopDataPickups()
        Librarian15BecauseReadWrite::utils_getAllTheTx46IdsLocationPairsFromDesktop()
            .each{|pair|
                identifier = pair["identifier"]
                location   = pair["location"]
                tx46       = XCache::getOrNull("fa2e7141-f1f2-4d2c-b9e9-f51cf6a0da9b:#{identifier}")
                # We will be asuming that tx46 is not null, otherwise this is too wierd and we deserve to crash
                tx46       = JSON.parse(tx46)
                puts JSON.pretty_generate(tx46)
                itemuuid   = tx46["itemuuid"]
                item       = Librarian6Objects::getObjectByUUIDOrNull(itemuuid)
                if item then
                    Librarian15BecauseReadWrite::pickupItem(tx46, item, location)
                else
                    puts "I could not find a nyx node for itemuuid: #{itemuuid}, that is associated with location: #{location}. Is that expected ?"
                    LucilleCore::pressEnterToContinue()
                end
            }
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
        tx46Id = Librarian15BecauseReadWrite::issueTx46ReturnIdentifier(item)
        exportFolderpath = "/Users/pascal/Desktop/#{item["description"]} (#{tx46Id})"
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
        raise "(F446B5E4-A795-415D-9D33-3E6B5E8E0AFF: non recognised atom type: #{atom})"
    end

    # Librarian21Fsck::fsckExitAtFirstFailureIamValue(object, nx111)
    def self.fsckExitAtFirstFailureIamValue(object, nx111)
        if !Nx111::iamTypes().include?(nx111[0]) then
            puts "object has an incorrect iam value type".red
            puts JSON.pretty_generate(object).red
            exit
        end
        if nx111[0] == "navigation" then
            return
        end
        if nx111[0] == "log" then
            return
        end
        if nx111[0] == "description-only" then
            return
        end
        if nx111[0] == "text" then
            nhash = nx111[1]
            if Librarian12LocalBlobsService::getBlobOrNull(nhash).nil? then
                puts "object, could not find the text data".red
                puts JSON.pretty_generate(object).red
                exit
            end
            return
        end
        if nx111[0] == "url" then
            return
        end
        if nx111[0] == "aion-point" then
            rootnhash = nx111[1]
            status = AionFsck::structureCheckAionHash(Librarian14ElizabethLocalStandard.new(), rootnhash)
            if !status then
                puts "object, could not validate aion-point".red
                puts JSON.pretty_generate(object).red
                exit
            end
            return
        end
        if nx111[0] == "unique-string" then
            return
        end
        if nx111[0] == "primitive-file" then
            _, dottedExtension, nhash, parts = nx111
            if dottedExtension[0, 1] != "." then
                puts "object".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, dotted extension is malformed".red
                exit
            end
            parts.each{|nhash|
                blob = Librarian12LocalBlobsService::getBlobOrNull(nhash)
                next if blob
                puts "object".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, nhash not found: #{nhash}".red
                exit
            }
            return
        end
        if nx111[0] == "carrier-of-primitive-files" then
            return
        end
        if nx111[0] == "Dx8Unit" then
            configuration = nx111[1]

            if configuration["status"] == "standard" then
                unitId = configuration["unitId"]
                rootnhash = configuration["rootnhash"]
                status = AionFsck::structureCheckAionHash(Librarian24ElizabethForDx8Units.new(unitId, "fsck"), rootnhash)
                if !status then
                    puts "object, could not validate Dx8Unit".red
                    puts JSON.pretty_generate(object).red
                    exit
                end
                return
            end

            raise "(error: 5a970959-ca52-40e4-b291-056c9c500575): #{object}, #{nx111}"
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect iam value: #{nx111})"
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
            Librarian21Fsck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxDated" then
            Librarian21Fsck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxFloat" then
            Librarian21Fsck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxFyre" then
            Librarian21Fsck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxTodo" then
            Librarian21Fsck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "Wave" then
            Librarian21Fsck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        puts JSON.pretty_generate(item).red
        raise "(error: a10f607b-4bc5-4ed2-ac31-dfd72c0108fc)"
    end

    # Librarian21Fsck::fsckExitAtFirstFailure()
    def self.fsckExitAtFirstFailure()

        runhash = XCache::getOrNull("1A07231B-8535-499B-BB2C-89A4EB429F49")
        if runhash.nil? then
            runhash = SecureRandom.hex
            XCache::set("1A07231B-8535-499B-BB2C-89A4EB429F49", runhash)
        else
            if LucilleCore::askQuestionAnswerAsBoolean("We have a run in progress, continue ? ") then
                # Nothing to do, we run with the existing hash
            else
                # We make a register a new hash
                runhash = SecureRandom.hex
                XCache::set("1A07231B-8535-499B-BB2C-89A4EB429F49", runhash)
            end
        end

        Librarian6Objects::objects()
        .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
        .reverse
        .each{|item|
            next if XCache::flagIsTrue("#{runhash}:#{item["uuid"]}")

            puts JSON.pretty_generate(item)
            Librarian21Fsck::fsckExitAtFirstFailureLibrarianMikuObject(item)

            XCache::setFlagTrue("#{runhash}:#{item["uuid"]}")

            return if !File.exists?("/Users/pascal/Desktop/Pascal.png") # We use this file to interrupt long runs at a place where it would not corrupt any file system.
        }

        XCache::destroy("1A07231B-8535-499B-BB2C-89A4EB429F49")

        puts "Fsck completed successfully".green
        LucilleCore::pressEnterToContinue()
    end
end

# ---------------------------------------------------------------------------
# Dx8Unit blob services and Elizabeth
# ---------------------------------------------------------------------------

# Modes: "standard" | "fsck"

class Librarian23Dx8UnitsBlobsService

    # Librarian23Dx8UnitsBlobsService::infinityRepository
    def self.infinityRepository
        "/Volumes/Infinity/Data/Pascal/Nyx-Librarian-Dx8Units"
    end

    # Librarian23Dx8UnitsBlobsService::driveIsPlugged()
    def self.driveIsPlugged()
        File.exists?(Librarian23Dx8UnitsBlobsService::infinityRepository)
    end

    # Librarian23Dx8UnitsBlobsService::ensureDrive()
    def self.ensureDrive()
        if !Librarian23Dx8UnitsBlobsService::driveIsPlugged() then
            puts "I need Infinity, could you plug the drive please ?"
            LucilleCore::pressEnterToContinue()
        end
        if !Librarian23Dx8UnitsBlobsService::driveIsPlugged() then
            puts "I needed Infinity 😞. Exiting."
            exit
        end
    end

    # Librarian23Dx8UnitsBlobsService::dx8UnitFolder(dx8UnitId)
    def self.dx8UnitFolder(dx8UnitId)
        "#{Librarian23Dx8UnitsBlobsService::infinityRepository}/#{dx8UnitId}"
    end

    # -----------------------------------------------------------------------------

    # Librarian23Dx8UnitsBlobsService::putBlob(mode, dx8UnitId, blob) # nhash
    def self.putBlob(mode, dx8UnitId, blob)

        if mode == "standard" then
            if Librarian23Dx8UnitsBlobsService::driveIsPlugged() then
                nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
                filepath = "#{Librarian23Dx8UnitsBlobsService::dx8UnitFolder(dx8UnitId)}/#{nhash[7, 2]}/#{nhash}.data"
                if !File.exists?(File.dirname(filepath)) then
                    FileUtils.mkpath(File.dirname(filepath))
                end
                File.open(filepath, "w"){|f| f.write(blob) }
                return nhash
            else
                return LibrarianXSpaceCache::putBlob(blob)
            end
        end

        if mode == "fsck" then
            Librarian23Dx8UnitsBlobsService::ensureDrive()
            nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
            filepath = "#{Librarian23Dx8UnitsBlobsService::dx8UnitFolder(dx8UnitId)}/#{nhash[7, 2]}/#{nhash}.data"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            File.open(filepath, "w"){|f| f.write(blob) }
            return nhash
        end
    end

    # Librarian23Dx8UnitsBlobsService::getBlobOrNull(mode, dx8UnitId, nhash)
    def self.getBlobOrNull(mode, dx8UnitId, nhash)

        if mode == "standard" then
            # raise "(error: 43b52dd9-3f29-4a66-8abc-bea210ab9126) This should not happens"
            # Actually this happens when we rewrite top names after Tx46 pickup from the Desktop
            blob = LibrarianXSpaceCache::getBlobOrNull(nhash)
            return blob if blob

            Librarian23Dx8UnitsBlobsService::ensureDrive()
            filepath = "#{Librarian23Dx8UnitsBlobsService::dx8UnitFolder(dx8UnitId)}/#{nhash[7, 2]}/#{nhash}.data"
            if File.exists?(filepath) then
                blob = IO.read(filepath)
                LibrarianXSpaceCache::putBlob(blob)
                return blob
            end
            return nil
        end

        if mode == "fsck" then
            # When we fsck commit to repair, so we want the blobs to be on the drive and we look local cache if needed

            Librarian23Dx8UnitsBlobsService::ensureDrive()

            filepath = "#{Librarian23Dx8UnitsBlobsService::dx8UnitFolder(dx8UnitId)}/#{nhash[7, 2]}/#{nhash}.data"
            if File.exists?(filepath) then
                return IO.read(filepath)
            end

            blob = LibrarianXSpaceCache::getBlobOrNull(nhash)
            if blob then
                puts "Dx8Unit fsck, put blob, #{dx8UnitId}, #{nhash}"
                Librarian23Dx8UnitsBlobsService::putBlob(mode, dx8UnitId, blob)
                return blob
            end

            return nil
        end
    end
end

class Librarian24ElizabethForDx8Units

    # @dx8UnitId
    # @mode

    def initialize(dx8UnitId, mode)

        @dx8UnitId = dx8UnitId
        @mode = mode

        if mode == "standard" then
            # Every time we instanciate this operator, in standard mode, the Dx8Unit is scheduled for dedicted fsck, because we could have performed an operation 
            # that added blobs to the Dx8Unit but currently only sitting on local. Fsck will fix that. We are listing them because 
            # running those dedicated fsck is part of the librarian Dx8Units maintenance, instead of having to wait for the next scheduled
            # global fsck.

            Mercury::postValue("055e1acb-164c-49cd-b17a-7946ba02c583", dx8UnitId)
        end
    end

    def commitBlob(blob)
        Librarian23Dx8UnitsBlobsService::putBlob(@mode, @dx8UnitId, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = Librarian23Dx8UnitsBlobsService::getBlobOrNull(@mode, @dx8UnitId, nhash)
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

        if ARGV[0] == "fsck" then
            Librarian21Fsck::fsckExitAtFirstFailure()
            exit
        end

        if ARGV[0] == "show-object-i" then
            uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
            object = Librarian6Objects::getObjectByUUIDOrNull(uuid)
            if object then
                puts JSON.pretty_generate(object)
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not find an object with this uuid"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "edit-object-i" then
            uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
            object = Librarian6Objects::getObjectByUUIDOrNull(uuid)
            if object then
                puts JSON.pretty_generate(object)
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not find an object with this uuid"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "destroy-object-by-uuid-i" then
            uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
            Librarian6Objects::destroy(uuid)
            exit
        end

        if ARGV[0] == "prob-blob-i" then
            nhash = LucilleCore::askQuestionAnswerAsString("nhash: ")
            blob = Librarian12LocalBlobsService::getBlobOrNull(nhash)
            if blob then
                puts "Found a blob of size #{blob.size}"
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not find a blob with nhash: #{nhash}"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "echo-blob-i" then
            nhash = LucilleCore::askQuestionAnswerAsString("nhash: ")
            blob = Librarian12LocalBlobsService::getBlobOrNull(nhash)
            if blob then
                puts JSON.pretty_generate(JSON.parse(blob))
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not find a blob with nhash: #{nhash}"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "desktop-data-pickup" then
            Librarian15BecauseReadWrite::desktopDataPickups()
            exit
        end

        if ARGV[0] == "Dx8Units-Maintenance" then
            while dx8UnitId = Mercury::dequeueFirstValueOrNull("055e1acb-164c-49cd-b17a-7946ba02c583") do
                puts "Dx8Unit Maintenance for dx8UnitId: #{dx8UnitId}"
                # We now need to determine the item by a Dx8Unit Id

                getItemOrNull = lambda{|dx8UnitId|
                    Nx100s::items().each{|item|
                        next if item["iam"][0] != "Dx8Unit"
                        configuration = item["iam"][1]
                        next if configuration["unitId"] != dx8UnitId
                        return item
                    }
                    nil
                }

                item = getItemOrNull.call(dx8UnitId)

                next if item.nil?

                puts "Dx8Unit maintenance (fsck) for item: #{item["description"].green}"

                Librarian21Fsck::fsckExitAtFirstFailureLibrarianMikuObject(item)

            end
            exit
        end

        puts "usage:"
        puts "    librarian fsck"
        puts "    librarian show-object-i"
        puts "    librarian edit-object-i"
        puts "    librarian destroy-object-by-uuid-i"
        puts "    librarian prob-blob-i"
        puts "    librarian echo-blob-i"
        puts "    librarian desktop-data-pickup"
        puts "    librarian Dx8Units-Maintenance"
    end
end


