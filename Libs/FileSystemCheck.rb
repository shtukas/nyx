
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid, nx111)
    def self.fsckNx111ErrorAtFirstFailure(objectuuid, nx111)
        return if nx111.nil?

        objectuuid = Fx18Attributes::getOrNull(objectuuid, "uuid")
        if objectuuid.nil? then
            puts "objectuuid: #{objectuuid}".red
            puts "Malformed Fx18 file, I could not find a uuid".red
            raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
        end
        if !Nx111::types().include?(nx111["type"]) then
            puts "objectuuid has an incorrect nx111 value type".red
            puts "objectuuid: #{objectuuid}".red
            puts "nx111: type: #{nx111["type"]}".red
            raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
        end
        if nx111["type"] == "text" then
            nhash = nx111["nhash"]
            blob = ExDataElizabethForFsck.new(objectuuid).getBlobOrNull(nhash)
            if blob.nil? then
                puts "objectuuid: #{objectuuid}".red
                puts "nx111: #{nx111}".red
                puts "nhash: #{nhash}".red
                puts "Fx18FileDataForFsck::getBlobOrNull(objectuuid, nhash): could not find the text data".red
                raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
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
                puts "objectuuid: #{objectuuid}".red
                puts "nx111: #{nx111}".red
                puts "primitive parts, dotted extension is malformed".red
                raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
            end
            operator = ExDataElizabethForFsck.new(objectuuid)
            parts.each{|nhash|
                blob = operator.getBlobOrNull(nhash)
                if blob.nil? then
                    puts "objectuuid: #{objectuuid}".red
                    puts "nx111: #{nx111}".red
                    puts "nhash: #{nhash}".red
                    puts "primitive parts, nhash not found: #{nhash}".red
                    raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
                end
            }
            return
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            operator = ExDataElizabethForFsck.new(objectuuid)
            status = AionFsck::structureCheckAionHash(operator, rootnhash)
            if !status then
                puts "objectuuid: #{objectuuid}".red
                puts "nx111: #{nx111}".red
                puts "objectuuid, could not validate aion-point".red
                raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
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
            puts "Dx8Unit: location: #{location}"
            if !File.exists?(location) then
                puts "note: could not find location for Dx8Unit: #{unitId}".red
            end
            return
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect nx111 value: #{nx111})"
    end

    # FileSystemCheck::fsckObjectErrorAtFirstFailure(objectuuid)
    def self.fsckObjectErrorAtFirstFailure(objectuuid)
        puts "FileSystemCheck, Fx18 @ objectuuid: #{objectuuid}"

        mikuType = Fx18Attributes::getOrNull(objectuuid, "mikuType")
        if mikuType.nil? then
            puts "objectuuid: #{objectuuid}".red
            puts "Malformed Fx18 file, I could not find a mikuType".red
            raise "FileSystemCheck::fsckObjectErrorAtFirstFailure(objectuuid: #{objectuuid})"
        end

        ensureAttribute = lambda {|objectuuid, mikuType, attname|
            attvalue = Fx18Attributes::getOrNull(objectuuid, attname)
            if attvalue.nil? then
                puts "ensureAttribute(#{objectuuid}, #{mikuType}, #{attname})"
                puts "objectuuid: #{objectuuid}".red
                puts "Malformed fx18 file (mikuType: #{mikuType}), I could not find attribute: #{attname}".red
                raise "FileSystemCheck::fsckObjectErrorAtFirstFailure(objectuuid: #{objectuuid})"
            end
        }

        if mikuType == "Ax1Text" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "nhash",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }

            nx111 = Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid, nx111)
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid, nx111)
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid, nx111)
            return
        end

        if mikuType == "NxLine" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "line",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid, nx111)
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid, nx111)
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
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
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(objectuuid, nx111)
            return
        end
    end

    # FileSystemCheck::fsckObject(objectuuid)
    def self.fsckObject(objectuuid)

        begin
            FileSystemCheck::fsckObjectErrorAtFirstFailure(objectuuid)
        rescue => e

            puts e.message.green

            db = SQLite3::Database.new(Fx18::localBlockFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            record = nil
            db.execute("select * from _fx18_ where _objectuuid_=?", [objectuuid]) do |row|
                next if row["_eventData1_"] == "datablob"
                puts JSON.pretty_generate(row)
            end
            db.close

            if LucilleCore::askQuestionAnswerAsBoolean("destroy this object ? ", false) then
                Fx18::destroyObject(objectuuid)
            end
        end
    end

    # FileSystemCheck::fsck()
    def self.fsck()
        Fx18::objectuuids()
            .each{|objectuuid|
                FileSystemCheck::exitIfMissingCanary()
                FileSystemCheck::fsckObject(objectuuid)
            }
        puts "fsck completed successfully".green
    end
end
