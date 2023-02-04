
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

    # FileSystemCheck::fsck_NxTimeCommitment(item, verbose)
    def self.fsck_NxTimeCommitment(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_NxTimeCommitment(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "NxTimeCommitment" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "mikuType", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
        FileSystemCheck::ensureAttribute(item, "description", "String")
        FileSystemCheck::ensureAttribute(item, "resetTime", "Number")
        FileSystemCheck::ensureAttribute(item, "field3", "Number")
    end

    # FileSystemCheck::fsck_NxNode(item, verbose)
    def self.fsck_NxNode(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_NxNode(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"].nil? then
            raise "item has no Miku type"
        end
        if item["mikuType"] != "NxNode" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
        FileSystemCheck::ensureAttribute(item, "description", "String")
    end

    # FileSystemCheck::fsck_MikuTypedItem(item, verbose)
    def self.fsck_MikuTypedItem(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_MikuTypedItem(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        mikuType = item["mikuType"]

        if mikuType == "NxTimeCommitment" then
            FileSystemCheck::fsck_NxTimeCommitment(item, verbose)
            return
        end

        if mikuType == "NxAnniversary" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
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
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "accounts", "Array")
            FileSystemCheck::ensureAttribute(item, "itemuuid", "String")
            return
        end

        if mikuType == "NxTodo" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "field2", "String")
            if !["regular", "ondate", "triage"].include?(item["field2"]) then
                raise "error: #{item["field2"]} is not supported"
            end
            if item["field11"] and item["field11"].size > 0 then
                CoreData::fsck(item["field11"])
            end
            return
        end

        if mikuType == "NxDrop" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            return
        end

        if mikuType == "NxNode" then
            FileSystemCheck::fsck_NxNode(item, verbose)
            return
        end

        if mikuType == "NxTimeCapsule" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "field1", "Number")
            FileSystemCheck::ensureAttribute(item, "field10", "String")
            return
        end

        if mikuType == "NxTop" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            return
        end

        if mikuType == "TxManualCountDown" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "dailyTarget", "Number")
            FileSystemCheck::ensureAttribute(item, "date", "String")
            FileSystemCheck::ensureAttribute(item, "counter", "Number")
            return
        end

        if mikuType == "Wave" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "nx46", "Hash")
            FileSystemCheck::ensureAttribute(item, "lastDoneDateTime", "String")
            if item["field11"] and item["field11"].size > 0 then
                CoreData::fsck(item["field11"])
            end
            return
        end

        raise "Unsupported Miku Type '#{mikuType}' in #{JSON.pretty_generate(item)}"
    end

    # -----------------------------------------------------

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exist?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckErrorAtFirstFailure()
    def self.fsckErrorAtFirstFailure()
        ObjectStore1::databaseItems()
            .each{|object|
                FileSystemCheck::exitIfMissingCanary()
                FileSystemCheck::fsck_MikuTypedItem(item, true)
            }
        puts "fsck completed successfully".green
    end
end
