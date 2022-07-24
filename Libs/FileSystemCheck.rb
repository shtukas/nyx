
# encoding: UTF-8

class Fx18FileDataForFsck

    # Fx18FileDataForFsck::getBlobOrNull(filepath, nhash)
    def self.getBlobOrNull(filepath, nhash)

        if !File.exists?(filepath) then
            puts "Fx18FileDataForFsck::getBlobOrNull(#{filepath}, #{nhash})"
            raise "(error: 925a63b6-f77c-4d30-a8ce-ea8c4ad6718c) filepath: #{filepath}"
        end

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _fx18_ where _eventData1_=? and _eventData2_=?", ["datablob", nhash]) do |row|
            blob = row["_eventData3_"]
        end
        db.close
        
        blob
    end
end

class Fx18ElizabethFsck

    def initialize(filepath)
        @filepath = filepath
    end

    def putBlob(blob)
        raise "(error: d9957964-6584-43b9-b43a-56b376e17a45)"
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Fx18FileDataForFsck::getBlobOrNull(@filepath, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "EnergyGridImmutableDataIslandElizabeth: (error: 25d380b3-cb73-42b3-9505-b9e8e4f6c5fa) could not find blob, nhash: #{nhash}"
        raise "(error: 3c1fadc8-510f-4c8f-9af3-572165fb57ac, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: a1870959-8af2-4e4e-ab2a-ce4ab70520d5) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath, nx111)
    def self.fsckNx111ErrorAtFirstFailure(filepath, nx111)
        return if nx111.nil?

        objectuuid = Fx18Attributes::getOrNull2(filepath, "uuid")
        if objectuuid.nil? then
            puts "filepath: #{filepath}".red
            puts "Malformed Fx18 file, I could not find a uuid".red
            raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath: #{filepath}, nx111: #{nx111})"
        end

        if !Nx111::types().include?(nx111["type"]) then
            puts "filepath has an incorrect nx111 value type".red
            puts "filepath: #{filepath}".red
            puts "nx111: type: #{nx111["type"]}".red
            raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath: #{filepath}, nx111: #{nx111})"
        end

        if nx111["type"] == "text" then
            nhash = nx111["nhash"]
            blob = FxDataElizabethForFsck.new(objectuuid).getBlobOrNull(nhash)
            if blob.nil? then
                puts "filepath: #{filepath}".red
                puts "nx111: #{nx111}".red
                puts "nhash: #{nhash}".red
                puts "Fx18FileDataForFsck::getBlobOrNull(filepath, nhash): could not find the text data".red
                raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath: #{filepath}, nx111: #{nx111})"
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
                puts "nx111: #{nx111}".red
                puts "primitive parts, dotted extension is malformed".red
                raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath: #{filepath}, nx111: #{nx111})"
            end
            operator = FxDataElizabethForFsck.new(objectuuid)
            parts.each{|nhash|
                blob = operator.getBlobOrNull(nhash)
                if blob.nil? then
                    puts "filepath: #{filepath}".red
                    puts "nx111: #{nx111}".red
                    puts "nhash: #{nhash}".red
                    puts "primitive parts, nhash not found: #{nhash}".red
                    raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath: #{filepath}, nx111: #{nx111})"
                end
            }
            return
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            operator = FxDataElizabethForFsck.new(objectuuid)
            status = AionFsck::structureCheckAionHash(operator, rootnhash)
            if !status then
                puts "filepath: #{filepath}".red
                puts "nx111: #{nx111}".red
                puts "filepath, could not validate aion-point".red
                raise "FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath: #{filepath}, nx111: #{nx111})"
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

    # FileSystemCheck::fsckFx18FilepathErrorAtFirstFailure(filepath)
    def self.fsckFx18FilepathErrorAtFirstFailure(filepath)
        puts "FileSystemCheck, Fx18, filepath: #{filepath}"

        uuid = Fx18Attributes::getOrNull2(filepath, "uuid")
        if uuid.nil? then
            puts "filepath: #{filepath}".red
            puts "Malformed Fx18 file, I could not find a uuid".red
            raise "FileSystemCheck::fsckFx18FilepathErrorAtFirstFailure(filepath: #{filepath})"
        end

        mikuType = Fx18Attributes::getOrNull2(filepath, "mikuType")
        if mikuType.nil? then
            puts "filepath: #{filepath}".red
            puts "Malformed Fx18 file, I could not find a mikuType".red
            raise "FileSystemCheck::fsckFx18FilepathErrorAtFirstFailure(filepath: #{filepath})"
        end

        ensureAttribute = lambda {|filepath, mikuType, attname|
            attvalue = Fx18Attributes::getOrNull2(filepath, attname)
            if attvalue.nil? then
                puts "ensureAttribute(#{filepath}, #{mikuType}, #{attname})"
                puts "filepath: #{filepath}".red
                puts "Malformed fx18 file (mikuType: #{mikuType}), I could not find attribute: #{attname}".red
                raise "FileSystemCheck::fsckFx18FilepathErrorAtFirstFailure(filepath: #{filepath})"
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

            nx111 = Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath, nx111)
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
            nx111 = Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath, nx111)
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
            nx111 = Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath, nx111)
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
            nx111 = Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath, nx111)
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
            nx111 = Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath, nx111)
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
            nx111 = Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull2(filepath, "nx111"))
            FileSystemCheck::fsckNx111ErrorAtFirstFailure(filepath, nx111)
            return
        end
    end

    # FileSystemCheck::fsckFx18Filepath(filepath)
    def self.fsckFx18Filepath(filepath)
        begin
            FileSystemCheck::fsckFx18FilepathErrorAtFirstFailure(filepath)
        rescue => e

            puts e.message.green

            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            record = nil
            db.execute("select * from _fx18_", []) do |row|
                next if row["_eventData1_"] == "datablob"
                puts JSON.pretty_generate(row)
            end
            db.close

            puts "filepath: #{filepath}"
            if LucilleCore::askQuestionAnswerAsBoolean("destroy this file ? ", false) then
                FileUtils::rm(filepath)
            end
        end
    end

    # FileSystemCheck::fsckLocalObjectuuid(objectuuid)
    def self.fsckLocalObjectuuid(objectuuid)
        filepath = Fx18Utils::computeLocalFx18Filepath(objectuuid)
        if !File.exists?(filepath) then
            puts "FileSystemCheck::fsckLocalObjectuuid"
            puts "objectuuid: #{objectuuid}"
            puts "error: I could not find the file"
            LucilleCore::pressEnterToContinue()
            return
        end
        FileSystemCheck::fsckFx18Filepath(filepath)
    end
end
