
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckNx113ErrorAtFirstFailure(nx113)
    def self.fsckNx113ErrorAtFirstFailure(nx113)
        puts "FileSystemCheck::fsckNx113ErrorAtFirstFailure(#{JSON.pretty_generate(nx113)})"

        if nx113["type"].nil? then
            raise "Nx113 doesn't have a type"
        end

        type = nx113["type"]

        if type == "text" then
            return
        end

        if type == "url" then
            return
        end

        if type == "file" then
            if nx113["dottedExtension"].nil? then
                 raise "dottedExtension is not defined on #{nx113}"
            end
            if nx113["nhash"].nil? then
                 raise "nhash is not defined on #{nx113}"
            end
            if nx113["parts"].nil? then
                 raise "parts is not defined on #{nx113}"
            end
            if nx113["database"].nil? then
                 raise "database is not defined on #{nx113}"
            end
            dottedExtension  = nx113["dottedExtension"]
            nhash            = nx113["nhash"]
            parts            = nx113["parts"]
            database         = nx113["database"]
            databasefilepath = DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(database, false)
            operator         = SQLiteDataStore2ElizabethReadOnly.new(databasefilepath)
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(operator, dottedExtension, nhash, parts)
            if !status then
                puts JSON.pretty_generate(item)
                raise "(error: 3e428541-805b-455e-b6a2-c400a6519aef) primitive file fsck failed"
            end
            return
        end

        if type == "aion-point" then
            if nx113["rootnhash"].nil? then
                 raise "rootnhash is not defined on #{nx113}"
            end
            if nx113["database"].nil? then
                 raise "database is not defined on #{nx113}"
            end
            rootnhash        = nx113["rootnhash"]
            database         = nx113["database"]
            databasefilepath = DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(database, false)
            operator         = SQLiteDataStore2ElizabethReadOnly.new(databasefilepath)
            status = AionFsck::structureCheckAionHash(operator, rootnhash)
            if !status then
                puts JSON.pretty_generate(item)
                raise "(error: 50daf867-0dab-47d9-ae79-d8e431650eab) aion structure fsck failed "
            end
            return
        end

        if type == "Dx8Unit" then
            return
        end

        if type == "unique-string" then
            return
        end

        puts "FileSystemCheck::fsckNx113(#{JSON.pretty_generate(nx113)})"
        raise "Unsupported Nx113 type: #{type}"
    end

    # FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(nhash) # We allow for null argument
    def self.fsckNx113NhashIfNotNullErrorAtFirstFailure(nhash)
        return if nhash.nil?

        puts "FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(#{JSON.pretty_generate(nhash)})"

        repeatKey = "daf95139-61ea-4872-b298-0d703825ec37:#{nhash}" # We can cache against the nhash without using a runhash, because of immutability
        return if XCache::getFlag(repeatKey)

        begin
            nx113 = Nx113Access::getNx113(nhash)
            FileSystemCheck::fsckNx113ErrorAtFirstFailure(nx113)
            XCache::setFlag(repeatKey, true)
        rescue => error
            puts "error message:"
            puts error.message
            raise "Could not extract the Nx113"
        end
    end

    # FileSystemCheck::fsckItemErrorArFirstFailure(item, runhash)
    def self.fsckItemErrorArFirstFailure(item, runhash)

        puts "FileSystemCheck::fsckItemErrorArFirstFailure(#{JSON.pretty_generate(item)}, #{runhash})"

        if item["uuid"].nil? then
            puts JSON.pretty_generate(item)
            puts "Missing attribute: uuid"
            raise "FileSystemCheck::fsckItemErrorArFirstFailure(item, #{runhash})"
        end

        if item["mikuType"].nil? then
            puts JSON.pretty_generate(item)
            puts "Missing attribute: mikuType"
            raise "FileSystemCheck::fsckItemErrorArFirstFailure(item, #{runhash})"
        end

        if item["unixtime"].nil? then
            puts JSON.pretty_generate(item)
            puts "Missing attribute: unixtime"
            raise "FileSystemCheck::fsckItemErrorArFirstFailure(item, #{runhash})"
        end

        if item["datetime"].nil? then
            puts JSON.pretty_generate(item)
            puts "Missing attribute: datetime"
            if LucilleCore::askQuestionAnswerAsBoolean("Should I add it now ? ", true) then
                ItemsEventsLog::setAttribute2(item["uuid"], "datetime", CommonUtils::now_iso8601())
                return FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(item["uuid"], SecureRandom.hex)
            end
            raise "FileSystemCheck::fsckItemErrorArFirstFailure(item, #{runhash})"
        end

        ensureAttribute = lambda {|attname|
            return if item[attname]
            puts JSON.pretty_generate(item)
            puts "Missing attribute: #{attname}"
            raise "FileSystemCheck::fsckItemErrorArFirstFailure(item, #{runhash})"
        }

        mikuType = item["mikuType"]

        if mikuType == "NxAnniversary" then
            ensureAttribute.call("description")
            ensureAttribute.call("startdate")
            ensureAttribute.call("repeatType")
            ensureAttribute.call("lastCelebrationDate")
            return
        end

        if mikuType == "NxTask" then
            ensureAttribute.call("description")
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"])
            return
        end

        if mikuType == "NxTodo" then
            ensureAttribute.call("description")
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"])
            return
        end

        if mikuType == "NyxNode" then
            ensureAttribute.call("description")
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"]) # nx113 is optional for NyxNodes, the function return if the argument in null
            return
        end

        if mikuType == "TxDated" then
            ensureAttribute.call("description")
            # ensureAttribute.call("nx112") # optional
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"])
            return
        end

        if mikuType == "TxTimeCommitment" then
            ensureAttribute.call("ax39")
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"])
            return
        end

        if mikuType == "Wave" then
            ensureAttribute.call("description")
            ensureAttribute.call("nx46")
            ensureAttribute.call("lastDoneDateTime")
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"])
            return
        end

        raise "Unsupported Miku Type: #{item}"
    end

    # FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(objectuuid, runhash)
    def self.fsckObjectuuidErrorAtFirstFailure(objectuuid, runhash)
        puts "FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(#{objectuuid}, #{runhash})"
        item = ItemsEventsLog::getProtoItemOrNull(objectuuid)
        if item.nil? then
            raise "Could not find an item for objectuuid: #{objectuuid}"
        end
        FileSystemCheck::fsckItemErrorArFirstFailure(item, runhash)
    end

    # FileSystemCheck::fsckAllErrorAtFirstFailure(runhash)
    def self.fsckAllErrorAtFirstFailure(runhash)
        ItemsEventsLog::objectuuids().each{|objectuuid|
            FileSystemCheck::exitIfMissingCanary()
            FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(objectuuid, runhash)
        }
        puts "fsck completed successfully".green
    end
end
