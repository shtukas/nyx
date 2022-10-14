
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::fsck_Nx11E(nx11e, verbose)
    def self.fsck_Nx11E(nx11e, verbose)
        if verbose then
            puts "FileSystemCheck::fsck_Nx11E(#{JSON.pretty_generate(nx11e)}, #{verbose})"
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

    # FileSystemCheck::fsck_Nx113(nx113, runhash, verbose)
    def self.fsck_Nx113(nx113, runhash, verbose)
        return nx113.nil?

        repeatKey = "#{runhash}:#{nx113}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_Nx113(#{JSON.pretty_generate(nx113)}, #{runhash}, #{verbose})"
        end

        if nx113["type"].nil? then
            raise "Nx113 doesn't have a type"
        end

        type = nx113["type"]

        if type == "text" then
            XCache::setFlag(repeatKey, true)
            return
        end

        if type == "url" then
            XCache::setFlag(repeatKey, true)
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
            XCache::setFlag(repeatKey, true)
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
            XCache::setFlag(repeatKey, true)
            return
        end

        if type == "Dx8Unit" then
            XCache::setFlag(repeatKey, true)
            return
        end

        if type == "unique-string" then
            XCache::setFlag(repeatKey, true)
            return
        end

        puts "FileSystemCheck::fsckNx113(#{JSON.pretty_generate(nx113)}, #{verbose})"
        raise "Unsupported Nx113 type: #{type}"
    end

    # FileSystemCheck::fsck_Cx22(cx22, verbose)
    def self.fsck_Cx22(cx22, verbose)
        return if cx22.nil?

        if verbose then
            "FileSystemCheck::fsck_Cx22(#{cx22}, #{verbose})"
        end

        ensureAttribute = lambda {|object, attname|
            return if object[attname]
            puts JSON.pretty_generate(object)
            raise "Missing attribute: #{attname} in #{object}"
        }

        ensureAttribute.call(cx22, "uuid")
        ensureAttribute.call(cx22, "uuid_variant")
        ensureAttribute.call(cx22, "mikuType")
        ensureAttribute.call(cx22, "description")
        ensureAttribute.call(cx22, "bankaccount")
        ensureAttribute.call(cx22, "ax39")
    end

    # FileSystemCheck::fsck_Cx23(cx23, verbose)
    def self.fsck_Cx23(cx23, verbose)
        return if cx23.nil?

        if verbose then
            "FileSystemCheck::fsck_Cx23(#{cx23}, #{verbose})"
        end

        ensureAttribute = lambda {|object, attname|
            return if object[attname]
            puts JSON.pretty_generate(object)
            raise "Missing attribute: #{attname} in #{object}"
        }

        ensureAttribute.call(cx23, "groupuuid")
        ensureAttribute.call(cx23, "position")
    end

    # FileSystemCheck::fsck_TxBankEvent(event, runhash, verbose)
    def self.fsck_TxBankEvent(event, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(event)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_TxBankEvent(#{JSON.pretty_generate(event)}, #{runhash}, #{verbose})"
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

    # FileSystemCheck::fsck_NxDoNotShowUntil(event, runhash, verbose)
    def self.fsck_NxDoNotShowUntil(event, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(event)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_NxDoNotShowUntil(#{JSON.pretty_generate(event)}, #{runhash}, #{verbose})"
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

    # FileSystemCheck::fsck_NxGraphEdge1(event, runhash, verbose)
    def self.fsck_NxGraphEdge1(event, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(event)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_NxGraphEdge1(#{JSON.pretty_generate(event)}, #{runhash}, #{verbose})"
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

    # FileSystemCheck::fsck_Cx22(object, runhash, verbose)
    def self.fsck_Cx22(object, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(object)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_Cx22(#{JSON.pretty_generate(object)}, #{runhash}, #{verbose})"
        end

        if object["uuid"].nil? then
            raise "object has no Miku type"
        end
        if object["mikuType"].nil? then
            raise "object has no Miku type"
        end
        if object["mikuType"] != "Cx22" then
            raise "Incorrect Miku type for function"
        end
        if object["description"].nil? then
            raise "Missing attribute description"
        end
        if object["bankaccount"].nil? then
            raise "Missing attribute bankaccount"
        end
        if object["ax39"].nil? then
            raise "Missing attribute ax39"
        end

        XCache::setFlag(repeatKey, true)
    end

    # FileSystemCheck::fsck_Item(item, runhash, verbose)
    def self.fsck_Item(item, runhash, verbose)

        repeatKey = "#{runhash}:#{JSON.generate(item)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_Item(#{JSON.pretty_generate(item)}, #{runhash}, #{verbose})"
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
            ensureAttribute.call(item, "uuid_variant")
            ensureAttribute.call(item, "description")
            ensureAttribute.call(item, "nx11e")
            FileSystemCheck::fsck_Nx11E(item["nx11e"], verbose)
            FileSystemCheck::fsck_Nx113(item["nx113"], runhash, verbose)
            FileSystemCheck::fsck_Cx23(item["cx23"], verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NyxNode" then
            ensureAttribute.call(item, "description")
            FileSystemCheck::fsck_Nx113(item["nx113"], runhash, verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "Wave" then
            ensureAttribute.call(item, "description")
            ensureAttribute.call(item, "nx46")
            ensureAttribute.call(item, "lastDoneDateTime")
            FileSystemCheck::fsck_Nx113(item["nx113"], runhash, verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        raise "Unsupported Miku Type: #{item}"
    end

    # FileSystemCheck::fsck_AttributeUpdateV2(event, runhash, verbose)
    def self.fsck_AttributeUpdateV2(event, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(event)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_AttributeUpdateV2(#{JSON.pretty_generate(event)}, #{runhash}, #{verbose})"
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

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

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
            FileSystemCheck::exitIfMissingCanary()
            FileSystemCheck::fsck_Item(item, runhash, true)
        }
        puts "fsck completed successfully".green
    end
end
