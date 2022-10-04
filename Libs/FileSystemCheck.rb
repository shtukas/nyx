
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckNx11EErrorAtFirstFailure(nx11e)
    def self.fsckNx11EErrorAtFirstFailure(nx11e)
        puts "FileSystemCheck::fsckNx11EErrorAtFirstFailure(#{nx11e})"

        ensureAttribute = lambda {|nx11e, attname|
            return if nx11e[attname]
            puts JSON.pretty_generate(nx11e)
            raise "Missing attribute: #{attname} in #{nx11e}"
        }

        ensureAttribute.call(nx11e, "uuid")
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

    # FileSystemCheck::fsckTxBankEvent(event)
    def self.fsckTxBankEvent(event)
        puts "FileSystemCheck::fsckTxBankEvent(#{JSON.pretty_generate(event)})"
        if event["mikuType"].nil? then
            raise "event has no Miku type"
        end
        if event["mikuType"] != "TxBankEvent" then
            raise "Incorrect Miku type for function"
        end
        if event["eventuuid"].nil? then
            raise "Missing attribute eventuuid"
        end
        if event["eventTime"].nil? then
            raise "Missing attribute eventTime"
        end
        if event["setuuid"].nil? then
            raise "Missing attribute setuuid"
        end
        if event["unixtime"].nil? then
            raise "Missing attribute unixtime"
        end
        if event["date"].nil? then
            raise "Missing attribute date"
        end
        if event["weight"].nil? then
            raise "Missing attribute weight"
        end
    end

    # FileSystemCheck::fsckSetUUIDTxBankEvent(setuuid, event)
    def self.fsckSetUUIDTxBankEvent(setuuid, event)
        puts "FileSystemCheck::fsckSetUUIDTxBankEvent(#{setuuid}, #{JSON.pretty_generate(event)})"
        FileSystemCheck::fsckTxBankEvent(event)
        if event["setuuid"] != setuuid then
            raise "the event does not carry the setuuid that we expect "
        end
    end

    # FileSystemCheck::fsckSetUUID_ArrayOfTxBankEvents(setuuid, events)
    def self.fsckSetUUID_ArrayOfTxBankEvents(setuuid, events)
        puts "FileSystemCheck::fsckSetUUID_ArrayOfTxBankEvents(#{setuuid}, events)"
        events.each{|event|
            FileSystemCheck::fsckSetUUIDTxBankEvent(setuuid, event)
        }
    end

    # FileSystemCheck::fsckNxDoNotShowUntil(event)
    def self.fsckNxDoNotShowUntil(event)
        puts "FileSystemCheck::fsckNxDoNotShowUntil(#{JSON.pretty_generate(event)})"
        if event["mikuType"].nil? then
            raise "event has no Miku type"
        end
        if event["mikuType"] != "NxDoNotShowUntil" then
            raise "Incorrect Miku type for function"
        end
        if event["targetuuid"].nil? then
            raise "Missing attribute targetuuid"
        end
        if event["targetunixtime"].nil? then
            raise "Missing attribute targetunixtime"
        end
    end

    # FileSystemCheck::fsckNxGraphEdge1(event)
    def self.fsckNxGraphEdge1(event)
        puts "FileSystemCheck::fsckNxGraphEdge1(#{JSON.pretty_generate(event)})"
        if event["mikuType"].nil? then
            raise "event has no Miku type"
        end
        if event["mikuType"] != "NxGraphEdge1" then
            raise "Incorrect Miku type for function"
        end
        if event["unixtime"].nil? then
            raise "Missing attribute unixtime"
        end
        if event["uuid1"].nil? then
            raise "Missing attribute uuid1"
        end
        if event["uuid2"].nil? then
            raise "Missing attribute uuid2"
        end
        if event["type"].nil? then
            raise "Missing attribute type"
        end
        if !["bidirectional", "arrow", "none"].include?(event["type"]) then
            raise "incorrect value for type: #{event["type"]}"
        end
    end

    # -----------------------------------------------------

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

        ensureAttribute = lambda {|item, attname|
            return if item[attname]
            puts JSON.pretty_generate(item)
            raise "Missing attribute #{attname} in #{attname}"
        }

        mikuType = item["mikuType"]

        if mikuType == "NxAnniversary" then
            ensureAttribute.call(item, "description")
            ensureAttribute.call(item, "startdate")
            ensureAttribute.call(item, "repeatType")
            ensureAttribute.call(item, "lastCelebrationDate")
            return
        end

        if mikuType == "NxLine" then
            ensureAttribute.call(item, "line")
            return
        end

        if mikuType == "NxTodo" then
            ensureAttribute.call(item, "description")
            FileSystemCheck::fsckNx11EErrorAtFirstFailure(item["nx11e"])
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"])
            return
        end

        if mikuType == "NyxNode" then
            ensureAttribute.call(item, "description")
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"]) # nx113 is optional for NyxNodes, the function return if the argument in null
            return
        end

        if mikuType == "Wave" then
            ensureAttribute.call(item, "description")
            ensureAttribute.call(item, "nx46")
            ensureAttribute.call(item, "lastDoneDateTime")
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

    # FileSystemCheck::fsckPrimaryStructureV1Banking(object)
    def self.fsckPrimaryStructureV1Banking(object)

        puts "FileSystemCheck::fsckPrimaryStructureV1Banking(#{JSON.pretty_generate(object)})"

        if object["mikuType"] != "PrimaryStructure.v1:Banking" then
            raise "Incorrect Miku type for this function"
        end

        object["mapping"].each{|pair|
            setuuid, nhash = pair
            array = TheLibrarian::getObject(nhash)
            FileSystemCheck::fsckSetUUID_ArrayOfTxBankEvents(setuuid, array)
        }
    end

    # FileSystemCheck::fsckPrimaryStructureV1DoNotShowUntil(object)
    def self.fsckPrimaryStructureV1DoNotShowUntil(object)
        puts "FileSystemCheck::fsckPrimaryStructureV1DoNotShowUntil(#{JSON.pretty_generate(object)})"

        if object["mikuType"] != "PrimaryStructure.v1:DoNotShowUntil" then
            raise "Incorrect Miku type for this function"
        end

        object["mapping"].each{|item|
            FileSystemCheck::fsckNxDoNotShowUntil(item)
        }
    end

    # FileSystemCheck::fsckPrimaryStructureV1NetworkEdges(object)
    def self.fsckPrimaryStructureV1NetworkEdges(object)
        puts "FileSystemCheck::fsckPrimaryStructureV1NetworkEdges(#{JSON.pretty_generate(object)})"

        if object["mikuType"] != "PrimaryStructure.v1:NetworkEdges" then
            raise "Incorrect Miku type for this function"
        end

        object["edges"].each{|item|
            FileSystemCheck::fsckNxGraphEdge1(item)
        }
    end

    # FileSystemCheck::fsckPrimaryStructureV1()
    def self.fsckPrimaryStructureV1()
        puts "FileSystemCheck::fsckPrimaryStructureV1()"
        primary = TheLibrarian::getPrimaryStructure()

        puts "primary: #{JSON.pretty_generate(primary)}"

        if primary["mikuType"] != "PrimaryStructure.v1" then
            raise "Incorrect Miku type for a primary structure"
        end

        if primary["banking"].nil? then
            raise "could not find attribute 'banking' for primary structure"
        end
        FileSystemCheck::fsckPrimaryStructureV1Banking(TheLibrarian::getObject(primary["banking"]))

        if primary["doNotShowUntil"].nil? then
            raise "could not find attribute 'doNotShowUntil' for primary structure"
        end
        FileSystemCheck::fsckPrimaryStructureV1DoNotShowUntil(TheLibrarian::getObject(primary["doNotShowUntil"]))

        if primary["networkEdges"].nil? then
            raise "could not find attribute 'networkEdges' for primary structure"
        end
        FileSystemCheck::fsckPrimaryStructureV1NetworkEdges(TheLibrarian::getObject(primary["networkEdges"]))
    end

    # -----------------------------------------------------

    # FileSystemCheck::fsckErrorAtFirstFailure(runhash)
    def self.fsckErrorAtFirstFailure(runhash)
        FileSystemCheck::fsckPrimaryStructureV1()
        ItemsEventsLog::objectuuids().each{|objectuuid|
            FileSystemCheck::exitIfMissingCanary()
            FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(objectuuid, runhash)
        }
        puts "fsck completed successfully".green
    end
end
