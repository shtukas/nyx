
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::ensureAttribute(item, attname, type)
    def self.ensureAttribute(item, attname, type)
        if item[attname].nil? then
            raise "Missing attribute #{attname} in #{JSON.pretty_generate(item)}"
        end
        if type.nil? then
            return
        end
        if type == "Number" then
            types = ["Integer", "Float"]
        else
            types = [type]
        end
        if !types.include?(item[attname].class.to_s) then
            raise "Incorrect attribute type for #{attname} in #{JSON.pretty_generate(item)}, expected: #{type}, found: #{item[attname].class.to_s}"
        end
    end

    # FileSystemCheck::fsck_Nx11E(item, verbose)
    def self.fsck_Nx11E(item, verbose)
        if verbose then
            puts "FileSystemCheck::fsck_Nx11E(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Nx11E" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")

        if item["type"] == "hot" then
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            return
        end

        if item["type"] == "triage" then
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            return
        end

        if item["type"] == "ordinal" then
            FileSystemCheck::ensureAttribute(item, "ordinal", "Number")
            return
        end

        if item["type"] == "ondate" then
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            return
        end

        if item["type"] == "standard" then
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            return
        end

        raise "(error: 2a5f46bd-c5db-48e7-a20f-4dd079868948)"
    end

    # FileSystemCheck::fsck_aion_point_rootnhash(operator, rootnhash, verbose)
    def self.fsck_aion_point_rootnhash(operator, rootnhash, verbose)
        if verbose then
            puts "FileSystemCheck::fsck_aion_point_rootnhash(operator, #{rootnhash}, #{verbose})"
        end
        status = AionFsck::structureCheckAionHash(operator, rootnhash)
        if !status then
            raise "(error: 50daf867-0dab-47d9-ae79-d8e431650eab) aion structure fsck failed "
        end
    end

    # FileSystemCheck::fsck_Nx113(operator, item, verbose)
    def self.fsck_Nx113(operator, item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Nx113(operator, #{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Nx113" then
            raise "Incorrect Miku type for function"
        end

        if item["type"].nil? then
            raise "Nx113 doesn't have a type"
        end

        type = item["type"]

        if type == "text" then
            return
        end

        if type == "url" then
            return
        end

        if type == "file" then
            if item["dottedExtension"].nil? then
                 raise "dottedExtension is not defined on #{item}"
            end
            if item["nhash"].nil? then
                 raise "nhash is not defined on #{item}"
            end
            if item["parts"].nil? then
                 raise "parts is not defined on #{item}"
            end
            dottedExtension  = item["dottedExtension"]
            nhash            = item["nhash"]
            parts            = item["parts"]
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(operator, dottedExtension, nhash, parts, verbose)
            if !status then
                puts JSON.pretty_generate(item)
                raise "(error: 3e428541-805b-455e-b6a2-c400a6519aef) primitive file fsck failed"
            end
            return
        end

        if type == "aion-point" then
            if item["rootnhash"].nil? then
                 raise "rootnhash is not defined on #{item}"
            end
            rootnhash = item["rootnhash"]
            FileSystemCheck::fsck_aion_point_rootnhash(operator, rootnhash, verbose)
            return
        end

        if type == "Dx8Unit" then
            return
        end

        if type == "unique-string" then
            return
        end

        puts "FileSystemCheck::fsckNx113(#{JSON.pretty_generate(item)}, #{verbose})"
        raise "Unsupported Nx113 type: #{type}"
    end

    # FileSystemCheck::fsck_Cx22(item, verbose)
    def self.fsck_Cx22(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Cx22(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Cx22" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "mikuType", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
        FileSystemCheck::ensureAttribute(item, "description", "String")
        FileSystemCheck::ensureAttribute(item, "ax39", "Hash")
    end

    # FileSystemCheck::fsck_Cx23(item, verbose)
    def self.fsck_Cx23(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Cx23(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Cx23" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "groupuuid", "String")
        FileSystemCheck::ensureAttribute(item, "itemuuid", "String")
        FileSystemCheck::ensureAttribute(item, "position", "Number")
    end

    # FileSystemCheck::fsck_Dx33(item, verbose)
    def self.fsck_Dx33(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Dx33(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Dx33" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "mikuType", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")

        FileSystemCheck::ensureAttribute(item, "unitId", "String")
    end

    # FileSystemCheck::fsck_NxGraphEdge1(item, verbose)
    def self.fsck_NxGraphEdge1(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_NxGraphEdge1(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"].nil? then
            raise "item has no Miku type"
        end
        if item["mikuType"] != "NxGraphEdge1" then
            raise "Incorrect Miku type for function"
        end
        FileSystemCheck::ensureAttribute(item, "mikuType", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
        FileSystemCheck::ensureAttribute(item, "uuid1", "String")
        FileSystemCheck::ensureAttribute(item, "uuid2", "String")
        FileSystemCheck::ensureAttribute(item, "type", "String")
        if !["bidirectional", "arrow", "none"].include?(item["type"]) then
            raise "incorrect value for type: #{item["type"]}"
        end
    end

    # FileSystemCheck::fsck_GridState(operator, item, verbose)
    def self.fsck_GridState(operator, item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_GridState(operator, #{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"].nil? then
            raise "item has no Miku type"
        end
        if item["mikuType"] != "GridState" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "type", "String")

        if !GridState::gridStateTypes().include?(item["type"]) then
            raise "Incorrect type in #{JSON.pretty_generate(item)}"
        end

        if item["type"] == "null" then

        end

        if item["type"] == "text" then
            FileSystemCheck::ensureAttribute(item, "text", "String")
        end

        if item["type"] == "url" then
            FileSystemCheck::ensureAttribute(item, "url", "String")
        end

        if item["type"] == "file" then
            if item["dottedExtension"].nil? then
                 raise "dottedExtension is not defined on #{item}"
            end
            if item["nhash"].nil? then
                 raise "nhash is not defined on #{item}"
            end
            if item["parts"].nil? then
                 raise "parts is not defined on #{item}"
            end
            dottedExtension  = item["dottedExtension"]
            nhash            = item["nhash"]
            parts            = item["parts"]
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(operator, dottedExtension, nhash, parts, verbose)
            if !status then
                puts JSON.pretty_generate(item)
                raise "(error: 3e428541-805b-455e-b6a2-c400a6519aef) primitive file fsck failed"
            end
        end

        if item["type"] == "NxDirectoryContents" then
            item["rootnhashes"].each{|rootnhash|
                FileSystemCheck::fsck_aion_point_rootnhash(operator, rootnhash, verbose)
            }
        end

        if item["type"] == "Dx8Unit" then
            FileSystemCheck::ensureAttribute(item, "unitId", "String")
            folder = Dx8Units::acquireUnitFolderPathOrNull(item["unitId"])
            if folder.nil? then
                raise "could not find Dx8Unit for state: #{JSON.pretty_generate(item)}"
            end
        end

        if item["type"] == "unique-string" then
            FileSystemCheck::ensureAttribute(item, "uniquestring", "String")
            # TODO: Complete
        end
    end

    # FileSystemCheck::fsck_Nx7(operator, item, verbose)
    def self.fsck_Nx7(operator, item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_Nx7(operator, #{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"].nil? then
            raise "item has no Miku type"
        end
        if item["mikuType"] != "Nx7" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
        FileSystemCheck::ensureAttribute(item, "description", "String")

        FileSystemCheck::ensureAttribute(item, "nx7Payload", "Hash")

        FileSystemCheck::fsck_Nx7Payload(operator, item["nx7Payload"], verbose)

        FileSystemCheck::ensureAttribute(item, "comments", "Array")

        item["comments"].each{|op|
            # TODO:
        }

        FileSystemCheck::ensureAttribute(item, "parentsuuids", "Array")
        FileSystemCheck::ensureAttribute(item, "relatedsuuids", "Array")
    end

    # FileSystemCheck::fsck_Nx3(item, verbose)
    def self.fsck_Nx3(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_Nx3(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"].nil? then
            raise "item has no Miku type"
        end
        if item["mikuType"] != "Nx3" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "eventuuid", "String")
        FileSystemCheck::ensureAttribute(item, "eventTime", "Number")
        FileSystemCheck::ensureAttribute(item, "eventType", "String")

        #FileSystemCheck::ensureAttribute(item, "payload", nil) # We sometimes have null payload 
    end

    # FileSystemCheck::fsck_Nx7Payload(operator, item, verbose)
    def self.fsck_Nx7Payload(operator, item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_Nx7Payload(operator, #{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"].nil? then
            raise "item has no Miku type"
        end
        if item["mikuType"] != "Nx7Payload" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "type", "String")

        if !Nx7Payloads::types().include?(item["type"]) then
            raise "Incorrect type in #{JSON.pretty_generate(item)}"
        end

        if item["type"] == "Data" then
            FileSystemCheck::ensureAttribute(item, "state", "Hash")
            FileSystemCheck::fsck_GridState(operator, item["state"], verbose)
        end

        if Nx7Payloads::navigationTypes().include?(item["type"]) then
            FileSystemCheck::ensureAttribute(item, "childrenuuids", "Array")
        end

    end

    # -----------------------------------------------------

    # FileSystemCheck::fsck_MikuTypedItem(item, verbose)
    def self.fsck_MikuTypedItem(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_MikuTypedItem(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        mikuType = item["mikuType"]

        if mikuType == "Cx22" then
            FileSystemCheck::fsck_Cx22(item, verbose)
            return
        end

        if mikuType == "Dx33" then
            FileSystemCheck::fsck_Dx33(item, verbose)
            return
        end

        if mikuType == "NxAnniversary" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "startdate", "String")
            FileSystemCheck::ensureAttribute(item, "repeatType", "String")
            FileSystemCheck::ensureAttribute(item, "lastCelebrationDate", "String")
            return
        end

        if mikuType == "NxBall.v2" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "desiredBankedTimeInSeconds", "Number")
            FileSystemCheck::ensureAttribute(item, "status", "Hash")
            FileSystemCheck::ensureAttribute(item, "accounts", "Array")
            return
        end

        if mikuType == "NxDoNotShowUntil" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            return
        end

        if mikuType == "NxGraphEdge1" then
            FileSystemCheck::fsck_NxGraphEdge1(item, verbose)
            return
        end

        if mikuType == "Nx7" then
            operator = Nx7::getElizabethOperatorForItem(item)
            FileSystemCheck::fsck_Nx7(operator, item, verbose)
            return
        end

        if mikuType == "NxNetworkLocalView" then
            FileSystemCheck::ensureAttribute(item, "center", "String")
            FileSystemCheck::ensureAttribute(item, "parents", "Array")
            FileSystemCheck::ensureAttribute(item, "related", "Array")
            FileSystemCheck::ensureAttribute(item, "children", "Array")
            return
        end

        if mikuType == "NxTodo" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "nx11e", "Hash")
            FileSystemCheck::fsck_Nx11E(item["nx11e"], verbose)
            FileSystemCheck::fsck_Nx113(NxTodos::getElizabethOperatorForItem(item), item["nx113"], verbose)
            if item["nx22"] then
                raise "NxTodos should not carry a Nx22"
            end
            return
        end

        if mikuType == "TxManualCountDown" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "dailyTarget", "Number")
            FileSystemCheck::ensureAttribute(item, "date", "String")
            FileSystemCheck::ensureAttribute(item, "counter", "Number")
            return
        end

        if mikuType == "Wave" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "nx46", "Hash")
            FileSystemCheck::ensureAttribute(item, "lastDoneDateTime", "String")
            FileSystemCheck::fsck_Nx113(Waves::operatorForItem(item), item["nx113"], verbose)
            if item["nx23"] then
                raise "Waves should not carry a Nx23"
            end
            return
        end

        raise "Unsupported Miku Type '#{mikuType}' in #{JSON.pretty_generate(item)}"
    end

    # -----------------------------------------------------

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckErrorAtFirstFailure()
    def self.fsckErrorAtFirstFailure()
        (Waves::items() + NxTodos::items() + Nx7::galaxyItemsEnumerator().to_a)
            .each{|item|
                FileSystemCheck::exitIfMissingCanary()
                FileSystemCheck::fsck_MikuTypedItem(item, true)
            }
        puts "fsck completed successfully".green
    end
end
