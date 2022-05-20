
# encoding: UTF-8

class InfinityDriveFileSystemCheck

    # InfinityDriveFileSystemCheck::fsckExitAtFirstFailureIamValue(object, nx111)
    def self.fsckExitAtFirstFailureIamValue(object, nx111)
        if !Nx111::iamTypes().include?(nx111["type"]) then
            puts "object has an incorrect iam value type".red
            puts JSON.pretty_generate(object).red
            exit
        end
        if nx111["type"] == "navigation" then
            return
        end
        if nx111["type"] == "log" then
            return
        end
        if nx111["type"] == "description-only" then
            return
        end
        if nx111["type"] == "text" then
            nhash = nx111["nhash"]
            if InfinityDatablobs_PureDrive::getBlobOrNull(nhash).nil? then
                puts "object, could not find the text data".red
                puts JSON.pretty_generate(object).red
                exit
            end
            return
        end
        if nx111["type"] == "url" then
            return
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            status = AionFsck::structureCheckAionHash(InfinityElizabethPureDrive.new(), rootnhash)
            if !status then
                puts "object, could not validate aion-point".red
                puts JSON.pretty_generate(object).red
                exit
            end
            return
        end
        if nx111["type"] == "unique-string" then
            return
        end
        if nx111["type"] == "primitive-file" then
            dottedExtension = nx111["dottedExtension"]
            nhash = nx111["nhash"]
            parts = nx111["parts"]
            if dottedExtension[0, 1] != "." then
                puts "object".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, dotted extension is malformed".red
                exit
            end
            parts.each{|nhash|
                blob = InfinityDatablobs_PureDrive::getBlobOrNull(nhash)
                next if blob
                puts "object".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, nhash not found: #{nhash}".red
                exit
            }
            return
        end
        if nx111["type"] == "carrier-of-primitive-files" then
            return
        end
        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
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
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect iam value: #{nx111})"
    end

    # InfinityDriveFileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("/Users/pascal/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # InfinityDriveFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(item, fsckrunhash)
    def self.fsckExitAtFirstFailureLibrarianMikuObject(item, fsckrunhash)

        puts JSON.pretty_generate(item)

        if item["mikuType"] == "Lx21" then
            return
        end

        if item["mikuType"] == "Nx60" then
            return
        end

        if item["mikuType"] == "Nx100" then
            if item["iam"].nil? then
                puts "Nx100 has not iam value".red
                puts JSON.pretty_generate(item).red
                exit
            end
            puts JSON.pretty_generate(item["iam"])
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        if item["mikuType"] == "TxAttachment" then
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        if item["mikuType"] == "TxDated" then
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        if item["mikuType"] == "TxFloat" then
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        if item["mikuType"] == "TxFyre" then
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        if item["mikuType"] == "TxInbox2" then
            if item["aionrootnhash"] then
                status = AionFsck::structureCheckAionHash(InfinityElizabethPureDrive.new(), item["aionrootnhash"])
                if !status then
                    puts "aionrootnhash does not validate".red
                    puts JSON.pretty_generate(item).red
                    exit
                end
            end
            return
        end

        if item["mikuType"] == "TxOS01" then
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(item["payload"], fsckrunhash)
            return
        end

        if item["mikuType"] == "TxTodo" then
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        if item["mikuType"] == "Wave" then
            InfinityDriveFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        if item["mikuType"] == "Sx01" then
            Sx01Snapshots::snapshotToLibrarianObjects(item)
                .each{|i2|
                    InfinityDriveFileSystemCheck::exitIfMissingCanary()
                    next if XCache::flagIsTrue("#{fsckrunhash}:#{JSON.generate(i2)}")
                    InfinityDriveFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(i2, fsckrunhash)
                    XCache::setFlagTrue("#{fsckrunhash}:#{JSON.generate(i2)}")
                }
            return
        end

        if item["mikuType"] == "Ax1Text" then
            nhash = item["nhash"]
            if InfinityDatablobs_PureDrive::getBlobOrNull(nhash).nil? then
                puts "nhash, blob not found".red
                puts JSON.pretty_generate(item).red
                exit
            end
            return
        end

        puts JSON.pretty_generate(item).red
        raise "(error: a10f607b-4bc5-4ed2-ac31-dfd72c0108fc)"
    end

    # InfinityDriveFileSystemCheck::fsck_SingleRunHashObjectTrace_ExitAtFirstFailure()
    def self.fsck_SingleRunHashObjectTrace_ExitAtFirstFailure()

        puts "For every fsck run hash, we check every object and then each of the object's next versions"

        fsckrunhash = XCache::getOrNull("1A07231B-8535-499B-BB2C-89A4EB429F51")

        if fsckrunhash.nil? then
            fsckrunhash = SecureRandom.hex
            XCache::set("1A07231B-8535-499B-BB2C-89A4EB429F51", fsckrunhash)
        end

        Librarian7ObjectsInfinity::objects()
            .shuffle
            .each{|item|
                InfinityDriveFileSystemCheck::exitIfMissingCanary()
                next if XCache::flagIsTrue("#{fsckrunhash}:#{JSON.generate(item)}") # We do a first check here to avoid displaying the object if it would not be fsck'ed
                InfinityDriveFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(item, fsckrunhash)
                XCache::setFlagTrue("#{fsckrunhash}:#{JSON.generate(item)}")
            }

        puts "Fsck completed successfully".green
    end

    # InfinityDriveFileSystemCheck::fsckExitAtFirstFailure()
    def self.fsckExitAtFirstFailure()
        InfinityDriveFileSystemCheck::fsck_SingleRunHashObjectTrace_ExitAtFirstFailure()
    end
end
