
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("/Users/pascal/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckNx111ExitAtFirstFailure(filepath, nx111)
    def self.fsckNx111ExitAtFirstFailure(filepath, nx111)
        return if nx111.nil?
        if !Nx111::types().include?(nx111["type"]) then
            puts "filepath has an incorrect nx111 value type".red
            puts "filepath: #{filepath}".red
            puts "nx111: type: #{nx111["type"]}".red
            exit 1
        end

        objectuuid = Fx18File::getAttributeOrNull2(filepath, "uuid")

        if nx111["type"] == "text" then
            nhash = nx111["nhash"]
            blob = Fx19Data::getBlobOrNull(objectuuid, nhash)
            if blob.nil? then
                puts "filepath: #{filepath}".red
                puts "objectuuid: #{objectuuid}".red
                puts "nx111: #{nx111}".red
                puts "nhash: #{nhash}".red
                puts "Fx19Data::getBlobOrNull: could not find the text data".red
                exit 1
            end
            return
        end
        if nx111["type"] == "url" then
            return
        end
        if nx111["type"] == "file" then
            dottedExtension = nx111["dottedExtension"]
            nhash = nx111["nhash"]
            parts = nx111["parts"]
            if dottedExtension[0, 1] != "." then
                puts "filepath: #{filepath}".red
                puts "objectuuid: #{objectuuid}".red
                puts "nx111: #{nx111}".red
                puts "primitive parts, dotted extension is malformed".red
                exit 1
            end
            operator = Fx18Elizabeth.new(objectuuid)
            parts.each{|nhash|
                blob = operator.getBlobOrNull(nhash)
                if blob.nil? then
                    puts "filepath: #{filepath}".red
                    puts "objectuuid: #{objectuuid}".red
                    puts "nx111: #{nx111}".red
                    puts "nhash: #{nhash}".red
                    puts "primitive parts, nhash not found: #{nhash}".red
                    exit 1
                end
            }
            return
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            operator = Fx18Elizabeth.new(objectuuid)
            status = AionFsck::structureCheckAionHash(operator, rootnhash)
            if !status then
                puts "filepath: #{filepath}".red
                puts "objectuuid: #{objectuuid}".red
                puts "nx111: #{nx111}".red
                puts "filepath, could not validate aion-point".red
                exit 1
            end
            return
        end
        if nx111["type"] == "unique-string" then
            return
        end
        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::acquireUnit(unitId)
            if location.nil? then
                puts "I could not acquire the Dx8Unit. Aborting operation."
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "location: #{location}"
            if !File.exists?(location) then
                puts "note: could not find location for Dx8Unit: #{unitId}".red
            end
            return
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect nx111 value: #{nx111})"
    end

    # FileSystemCheck::fsckFx18FilepathExitAtFirstFailure(filepath)
    def self.fsckFx18FilepathExitAtFirstFailure(filepath)
        puts "FileSystemCheck, Fx18, filepath: #{filepath}"
        uuid = Fx18File::getAttributeOrNull2(filepath, "uuid")
        if uuid.nil? then
            puts "filepath: #{filepath}".red
            puts "Malformed Fx18 file, I could not find a uuid".red
            exit 1
        end
        mikuType = Fx18File::getAttributeOrNull2(filepath, "mikuType")
        if mikuType.nil? then
            puts "filepath: #{filepath}".red
            puts "Malformed Fx18 file, I could not find a mikuType".red
            exit 1
        end

        ensureAttribute = lambda {|filepath, mikuType, attname|
            attvalue = Fx18File::getAttributeOrNull2(filepath, attname)
            if attvalue.nil? then
                puts "filepath: #{filepath}".red
                puts "Malformed fx18 file (mikuType: #{mikuType}), I could not find attribute: #{attname}".red
                exit 1
            end
        }

        if mikuType == "Ax1Text" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "nhash",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "NxAnniversary" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "description",
                "startdate",
                "repeatType",
                "lastCelebrationDate",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "NxEvent" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
                "nx111",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }

            nx111 = JSON.parse(Fx18File::getAttributeOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ExitAtFirstFailure(filepath, nx111)
            return
        end

        if mikuType == "NxCollection" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "NxConcept" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "NxDataNode" then
            # "description", # not present with (nx111: type: file)
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "nx111",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            nx111 = JSON.parse(Fx18File::getAttributeOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ExitAtFirstFailure(filepath, nx111)
            return
        end

        if mikuType == "NxEntity" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "NxFrame" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
                "nx111",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            nx111 = JSON.parse(Fx18File::getAttributeOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ExitAtFirstFailure(filepath, nx111)
            return
        end

        if mikuType == "NxLine" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "line",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "NxPerson" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "name",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "NxTask" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "description",
                "nx111",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            nx111 = JSON.parse(Fx18File::getAttributeOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ExitAtFirstFailure(filepath, nx111)
            return
        end

        if mikuType == "NxTimeline" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "TxDated" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
                "nx111",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            nx111 = JSON.parse(Fx18File::getAttributeOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ExitAtFirstFailure(filepath, nx111)
            return
        end

        if mikuType == "TxProject" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "description",
                "ax39",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            return
        end

        if mikuType == "Wave" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "description",
                "nx46",
                "nx111",
                "lastDoneDateTime",
            ]
                .each{|attname| ensureAttribute.call(filepath, mikuType, attname) }
            nx111 = JSON.parse(Fx18File::getAttributeOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ExitAtFirstFailure(filepath, nx111)
            return
        end
    end
end
