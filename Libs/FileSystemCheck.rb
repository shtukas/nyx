
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

    # FileSystemCheck::fsck_aion_point_rootnhash(rootnhash, verbose)
    def self.fsck_aion_point_rootnhash(rootnhash, verbose)
        if verbose then
            puts "FileSystemCheck::fsck_aion_point_rootnhash(#{rootnhash}, #{verbose})"
        end
        AionFsck::structureCheckAionHashRaiseErrorIfAny(DatablobStoreElizabeth.new(), rootnhash)
    end

    # FileSystemCheck::fsck_Nx113(item, verbose)
    def self.fsck_Nx113(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Nx113(#{JSON.pretty_generate(item)}, #{verbose})"
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
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(dottedExtension, nhash, parts, verbose)
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
            FileSystemCheck::fsck_aion_point_rootnhash(rootnhash, verbose)
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

    # FileSystemCheck::fsck_NxProject(item, verbose)
    def self.fsck_NxProject(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_NxProject(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "NxProject" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "mikuType", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
        FileSystemCheck::ensureAttribute(item, "description", "String")
        FileSystemCheck::ensureAttribute(item, "ax39", "Hash")
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

    # FileSystemCheck::fsck_GridState(item, verbose)
    def self.fsck_GridState(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_GridState( #{JSON.pretty_generate(item)}, #{verbose})"
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
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(dottedExtension, nhash, parts, verbose)
            if !status then
                puts JSON.pretty_generate(item)
                raise "(error: 3e428541-805b-455e-b6a2-c400a6519aef) primitive file fsck failed"
            end
        end

        if item["type"] == "NxDirectoryContents" then
            item["rootnhashes"].each{|rootnhash|
                FileSystemCheck::fsck_aion_point_rootnhash(rootnhash, verbose)
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

    # -----------------------------------------------------

    # FileSystemCheck::fsck_MikuTypedItem(item, verbose)
    def self.fsck_MikuTypedItem(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_MikuTypedItem(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        mikuType = item["mikuType"]

        if mikuType == "NxProject" then
            FileSystemCheck::fsck_NxProject(item, verbose)
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

        if mikuType == "NxBall" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "accounts", "Array")
            FileSystemCheck::ensureAttribute(item, "itemuuid", "String")
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
            FileSystemCheck::ensureAttribute(item, "priority", "Number")
            FileSystemCheck::ensureAttribute(item, "projectId", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], verbose)
            return
        end

        if mikuType == "NxTriage" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], verbose)
            return
        end

        if mikuType == "NxOndate" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], verbose)
            return
        end

        if mikuType == "TxManualCountDown" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
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
            FileSystemCheck::ensureAttribute(item, "priority", "String")
            FileSystemCheck::ensureAttribute(item, "lastDoneDateTime", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], verbose)
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
        [
            Anniversaries::items(),
            NxProjects::items(),
            NxOndates::items(),
            NxTodos::itemsEnumerator(),
            NxTriages::items(),
            TxFloats::items(),
            TxManualCountDowns::items(),
            Waves::items()
        ]
            .flatten
            .each{|item|
                FileSystemCheck::exitIfMissingCanary()
                FileSystemCheck::fsck_MikuTypedItem(item, true)
            }
        puts "fsck completed successfully".green
    end
end
