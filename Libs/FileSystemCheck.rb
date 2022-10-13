
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckNx11EErrorAtFirstFailure(nx11e, verbose)
    def self.fsckNx11EErrorAtFirstFailure(nx11e, verbose)
        if verbose then
            puts "FileSystemCheck::fsckNx11EErrorAtFirstFailure(#{JSON.pretty_generate(nx11e)}, #{verbose})"
        end

        ensureAttribute = lambda {|object, attname|
            return if object[attname]
            puts JSON.pretty_generate(object)
            raise "Missing attribute: #{attname} in #{object}"
        }

        ensureAttribute.call(nx11e, "uuid")

        if nx11e["type"] == "hot" then
            ensureAttribute.call(nx11e, "unixtime")
            return
        end

        if nx11e["type"] == "triage" then
            ensureAttribute.call(nx11e, "unixtime")
            return
        end

        if nx11e["type"] == "ordinal" then
            ensureAttribute.call(nx11e, "ordinal")
            return
        end

        if nx11e["type"] == "ondate" then
            ensureAttribute.call(nx11e, "datetime")
            return
        end

        if nx11e["type"] == "standard" then
            ensureAttribute.call(nx11e, "unixtime")
            return
        end

        raise "(error: 2a5f46bd-c5db-48e7-a20f-4dd079868948)"
    end

    # FileSystemCheck::fsckNx113ErrorAtFirstFailure(nx113, verbose)
    def self.fsckNx113ErrorAtFirstFailure(nx113, verbose)
        if verbose then
            puts "FileSystemCheck::fsckNx113ErrorAtFirstFailure(#{JSON.pretty_generate(nx113)}, #{verbose})"
        end

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
            databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(database, false)
            operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(operator, dottedExtension, nhash, parts, verbose)
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
            databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(database, false)
            operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
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

        puts "FileSystemCheck::fsckNx113(#{JSON.pretty_generate(nx113)}, #{verbose})"
        raise "Unsupported Nx113 type: #{type}"
    end

    # FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(nhash, verbose) # We allow for null nhash
    def self.fsckNx113NhashIfNotNullErrorAtFirstFailure(nhash, verbose)
        return if nhash.nil?

        if verbose then
            puts "FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(#{JSON.pretty_generate(nhash)}, #{verbose})"
        end

        repeatKey = "daf95139-61ea-4872-b298-0d703825ec37:#{nhash}" # We can cache against the nhash without using a runhash, because of immutability
        return if XCache::getFlag(repeatKey)

        nx113 = Nx113Access::getNx113(nhash)
        FileSystemCheck::fsckNx113ErrorAtFirstFailure(nx113, verbose)
        XCache::setFlag(repeatKey, true)
    end

    # FileSystemCheck::fsckCx22StringIfNotNullErrorAtFirstFailure(cx22str, verbose)
    def self.fsckCx22StringIfNotNullErrorAtFirstFailure(cx22str, verbose)
        return if cx22str.nil?

        if verbose then
            puts "FileSystemCheck::fsckCx22StringIfNotNullErrorAtFirstFailure(#{cx22str}, #{verbose})"
        end

        if cx22str.class.to_s != "String" then
            puts "Cx22 (string) fails to be a string"
        end
    end

    # FileSystemCheck::fsckCx23IfNotNullErrorAtFirstFailure(cx23, verbose)
    def self.fsckCx23IfNotNullErrorAtFirstFailure(cx23, verbose)
        return if cx23.nil?

        ensureAttribute = lambda {|object, attname|
            return if object[attname]
            puts JSON.pretty_generate(object)
            raise "Missing attribute: #{attname} in #{object}"
        }

        if verbose then
            "FileSystemCheck::fsckCx23IfNotNullErrorAtFirstFailure(#{cx23}, #{verbose})"
        end

        ensureAttribute.call(cx23, "groupuuid")
        ensureAttribute.call(cx23, "position")
    end

    # FileSystemCheck::fsckTxBankEvent(event, runhash, verbose)
    def self.fsckTxBankEvent(event, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(event)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsckTxBankEvent(#{JSON.pretty_generate(event)}, #{runhash}, #{verbose})"
        end

        if event["mikuType"].nil? then
            raise "event has no Miku type"
        end
        if event["mikuType"] != "TxBankEvent" then
            raise "Incorrect Miku type for function"
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

        XCache::setFlag(repeatKey, true)
    end

    # FileSystemCheck::fsckNxDoNotShowUntil(event, runhash, verbose)
    def self.fsckNxDoNotShowUntil(event, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(event)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsckNxDoNotShowUntil(#{JSON.pretty_generate(event)}, #{runhash}, #{verbose})"
        end

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

        XCache::setFlag(repeatKey, true)
    end

    # FileSystemCheck::fsckNxGraphEdge1(event, runhash, verbose)
    def self.fsckNxGraphEdge1(event, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(event)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsckNxGraphEdge1(#{JSON.pretty_generate(event)}, #{runhash}, #{verbose})"
        end

        if event["mikuType"].nil? then
            raise "event has no Miku type"
        end
        if event["mikuType"] != "NxGraphEdge1" then
            raise "Incorrect Miku type for function"
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

        XCache::setFlag(repeatKey, true)
    end

    # FileSystemCheck::fsckItemErrorArFirstFailure(item, runhash, verbose)
    def self.fsckItemErrorArFirstFailure(item, runhash, verbose)

        # --------------------------------------
        # Temporary

        if item["uuid"] and item["uuid"].include?("cf7d8093-ea52-417a-b814-71594118d539") then
            Items::delete(item["uuid"])
            return
        end

        if item["mikuType"] and item["mikuType"].include?("TxTimeCommitment") then
            Items::delete(item["uuid"])
            return
        end

        if item["mikuType"] and item["mikuType"].include?("CxAionPoint") then
            Items::delete(item["uuid"])
            return
        end

        # --------------------------------------

        repeatKey = "#{runhash}:#{JSON.generate(item)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsckItemErrorArFirstFailure(#{JSON.pretty_generate(item)}, #{runhash}, #{verbose})"
        end

        ensureAttribute = lambda {|item, attname|
            return if item[attname]
            raise "Missing attribute #{attname} in #{item}"
        }

        ensureAttribute.call(item, "uuid")
        ensureAttribute.call(item, "mikuType")
        ensureAttribute.call(item, "unixtime")
        ensureAttribute.call(item, "datetime")

        mikuType = item["mikuType"]

        if mikuType == "NxAnniversary" then
            ensureAttribute.call(item, "description")
            ensureAttribute.call(item, "startdate")
            ensureAttribute.call(item, "repeatType")
            ensureAttribute.call(item, "lastCelebrationDate")
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxLine" then
            ensureAttribute.call(item, "line")
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxTodo" then
            ensureAttribute.call(item, "description")
            ensureAttribute.call(item, "nx11e")
            FileSystemCheck::fsckNx11EErrorAtFirstFailure(item["nx11e"], verbose)
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"], verbose)
            FileSystemCheck::fsckCx22StringIfNotNullErrorAtFirstFailure(item["cx22"], verbose)
            FileSystemCheck::fsckCx23IfNotNullErrorAtFirstFailure(item["cx23"], verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NyxNode" then
            ensureAttribute.call(item, "description")
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"], verbose) # nx113 is optional for NyxNodes, the function return if the argument in null
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "Wave" then
            ensureAttribute.call(item, "description")
            ensureAttribute.call(item, "nx46")
            ensureAttribute.call(item, "lastDoneDateTime")
            FileSystemCheck::fsckNx113NhashIfNotNullErrorAtFirstFailure(item["nx113"], verbose)
            FileSystemCheck::fsckCx22StringIfNotNullErrorAtFirstFailure(item["cx22"], verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        # --------------------------------------
        # Temporary

        if item["mikuType"] == "NxTask" then
            Items::setAttribute2(item["uuid"], "mikuType", "NxTodo")
            item = Items::getItemOrNull(item["uuid"])
            FileSystemCheck::fsckItemErrorArFirstFailure(item, runhash, verbose)
            return
        end

        if ["CxAionPoint", "DxAionPoint"].include?(item["mikuType"]) then
            Items::delete(item["uuid"])
            return
        end
        # --------------------------------------

        raise "Unsupported Miku Type: #{item}"
    end

    # FileSystemCheck::fsckAttributeUpdateV2(event, runhash, verbose)
    def self.fsckAttributeUpdateV2(event, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(event)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsckAttributeUpdateV2(#{JSON.pretty_generate(event)}, #{runhash}, #{verbose})"
        end

        if event["mikuType"].nil? then
            raise "event has no Miku type"
        end
        if event["mikuType"] != "AttributeUpdate.v2" then
            raise "Incorrect Miku type for function"
        end
        if event["objectuuid"].nil? then
            raise "Missing attribute objectuuid"
        end
        if event["eventuuid"].nil? then
            raise "Missing attribute eventuuid"
        end
        if event["eventTime"].nil? then
            raise "Missing attribute eventTime"
        end
        if event["attname"].nil? then
            raise "Missing attribute attname"
        end
        if event["attvalue"].nil? then
            # attvalue can be null
        end
        XCache::setFlag(repeatKey, true)
    end

    # -----------------------------------------------------

    # FileSystemCheck::getExistingRunHash()
    def self.getExistingRunHash()
        r = XCache::getOrNull("371dbc1d-8fbc-498b-ac98-d17d978cfdbf")
        if r.nil? then
            r = SecureRandom.hex
            XCache::set("371dbc1d-8fbc-498b-ac98-d17d978cfdbf", r)
        end
        r
    end

    # FileSystemCheck::fsckErrorAtFirstFailure(runhash)
    def self.fsckErrorAtFirstFailure(runhash)
        Items::items().each{|item|
            FileSystemCheck::fsckItemErrorArFirstFailure(item, runhash, true)
        }
        puts "fsck completed successfully".green
    end
end
