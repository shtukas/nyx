
# encoding: UTF-8

class InfinityFsckBlobsService

    # InfinityFsckBlobsService::infinityDatablobsRepository()
    def self.infinityDatablobsRepository()
        "#{Config::pathToInfinityDidact()}/DatablobsDepth2"
    end

    # -----------------------------------------------------------------------------

    # InfinityFsckBlobsService::blobExist?(nhash)
    def self.blobExist?(nhash)
        InfinityDrive::ensureInfinityDrive()
        filepath = "#{InfinityFsckBlobsService::infinityDatablobsRepository()}/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        File.exists?(File.dirname(filepath))
    end

    # InfinityFsckBlobsService::putBlob(blob) # nhash
    def self.putBlob(blob)

        InfinityDrive::ensureInfinityDrive()

        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = "#{InfinityFsckBlobsService::infinityDatablobsRepository()}/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }

        nhash
    end

    # InfinityFsckBlobsService::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)

        InfinityDrive::ensureInfinityDrive()

        filepath = "#{InfinityFsckBlobsService::infinityDatablobsRepository()}/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            return blob
        end

        blob = Librarian2DatablobsXCache::getBlobOrNull(nhash)
        if blob then
            puts "InfinityFsckBlobsService: uploading missing blob: #{nhash}"
            InfinityFsckBlobsService::putBlob(blob)
            return blob
        end

        nil
    end
end

class InfinityElizabethFsck

    def commitBlob(blob)
        InfinityFsckBlobsService::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = InfinityFsckBlobsService::getBlobOrNull(nhash)
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

class InfinityFileSystemCheck

    # InfinityFileSystemCheck::fsckAtomReturnBoolean(atom) : Boolean
    def self.fsckAtomReturnBoolean(atom)
        puts JSON.pretty_generate(atom)
        if atom["type"] == "description-only" then
            return true
        end
        if atom["type"] == "text" then
            return !InfinityFsckBlobsService::getBlobOrNull(atom["payload"]).nil?
        end
        if atom["type"] == "url" then
            return true
        end
        if atom["type"] == "aion-point" then
            nhash = atom["rootnhash"]
            status = AionFsck::structureCheckAionHash(InfinityElizabethFsck.new(), nhash)
            return status
        end
        if atom["type"] == "unique-string" then
            # Technically we should be checking if the target exists, but that takes too long
            return true
        end
        raise "(F446B5E4-A795-415D-9D33-3E6B5E8E0AFF: non recognised atom type: #{atom})"
    end

    # InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(object, nx111)
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
            if InfinityFsckBlobsService::getBlobOrNull(nhash).nil? then
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
            status = AionFsck::structureCheckAionHash(InfinityElizabethFsck.new(), rootnhash)
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
                blob = InfinityFsckBlobsService::getBlobOrNull(nhash)
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

            if configuration["Dx8Type"] == "unique-file-on-infinity-drive" then
                unitId = configuration["unitId"]
                location = Dx8UnitsUtils::dx8UnitFolder(unitId)
                puts "location: #{location}"
                status = File.exists?(location)
                if !status then
                    puts "could not find location".red
                    puts JSON.pretty_generate(object).red
                    exit
                end
                status = LucilleCore::locationsAtFolder(location).size == 1
                if !status then
                    puts "expecting only one file at location".red
                    puts JSON.pretty_generate(object).red
                    exit
                end
                return
            end

            raise "(error: 5a970959-ca52-40e4-b291-056c9c500575): #{object}, #{nx111}"
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect iam value: #{nx111})"
    end

    # InfinityFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(item)
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
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, iAmValue)
            return
        end
        if item["mikuType"] == "TxAttachment" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxDated" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxFloat" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxFyre" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxInbox2" then
            if item["aionrootnhash"] then
                # Librarian3ElizabethXCache is correct here
                status = AionFsck::structureCheckAionHash(Librarian3ElizabethXCache.new(), item["aionrootnhash"])
                if !status then
                    puts "aionrootnhash does not validate".red
                    puts JSON.pretty_generate(item).red
                    exit
                end
            end
            return
        end
        if item["mikuType"] == "TxTodo" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "Wave" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        puts JSON.pretty_generate(item).red
        raise "(error: a10f607b-4bc5-4ed2-ac31-dfd72c0108fc)"
    end

    # InfinityFileSystemCheck::fsckExitAtFirstFailure()
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

        Librarian7ObjectsInfinity::objects()
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
            .reverse
            .each{|item|
                next if XCache::flagIsTrue("#{runhash}:#{item["uuid"]}")

                puts JSON.pretty_generate(item)
                InfinityFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(item)

                XCache::setFlagTrue("#{runhash}:#{item["uuid"]}")

                return if !File.exists?("/Users/pascal/Desktop/Pascal.png") # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            }

        XCache::destroy("1A07231B-8535-499B-BB2C-89A4EB429F49")

        puts "Fsck completed successfully".green
        LucilleCore::pressEnterToContinue()
    end
end
