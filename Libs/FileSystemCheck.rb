
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(objectuuid)
    def self.fsckObjectuuidErrorAtFirstFailure(objectuuid)

        filepath = DxF1::filepathOrNullNoSideEffect(objectuuid)
        return if filepath.nil?

        repeatKey = "e5efa6c6-f950-4a29-b15f-aa25ba4c0d5e:#{filepath}:#{File.mtime(filepath)}"
        return if XCache::getFlag(repeatKey)

        puts "FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(#{objectuuid})"

        if !DxF1::objectIsAlive(objectuuid) then
            XCache::setFlag(repeatKey, true)
            return
        end

        mikuType = DxF1::getJsonDecodeOrNull(objectuuid, "mikuType")
        if mikuType.nil? then
            puts "objectuuid: #{objectuuid}".red
            puts "Malformed DxF1 file, I could not find a mikuType".red
            raise "FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(objectuuid: #{objectuuid})"
        end

        ensureAttribute = lambda {|objectuuid, mikuType, attname|
            attvalue = DxF1::getJsonDecodeOrNull(objectuuid, attname)
            if attvalue.nil? then
                puts "ensureAttribute(#{objectuuid}, #{mikuType}, #{attname})"
                puts "objectuuid: #{objectuuid}".red
                puts "Malformed fx18 file (mikuType: #{mikuType}), I could not find attribute: #{attname}".red
                raise "FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(objectuuid: #{objectuuid})"
            end
        }

        if mikuType == "Ax1Text" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "text",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            XCache::setFlag(repeatKey, true)
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
            XCache::setFlag(repeatKey, true)
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

            nx111 = DxF1::getJsonDecodeOrNull(objectuuid, "nx111")
            Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
            XCache::setFlag(repeatKey, true)
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
            XCache::setFlag(repeatKey, true)
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
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxDataNode" then
            # "description", # not present with (nx111: type: file)
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = DxF1::getJsonDecodeOrNull(objectuuid, "nx111")
            Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
            XCache::setFlag(repeatKey, true)
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
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxFrame" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = DxF1::getJsonDecodeOrNull(objectuuid, "nx111")
            Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxIced" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "description",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = DxF1::getJsonDecodeOrNull(objectuuid, "nx111")
            Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxLine" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "line",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "TxIncoming" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "line",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "TxTimeCommitmentProject" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "ax39",
                "elementuuids",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            XCache::setFlag(repeatKey, true)
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
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxTask" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "description",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = DxF1::getJsonDecodeOrNull(objectuuid, "nx111")
            Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
            XCache::setFlag(repeatKey, true)
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
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "TopLevel" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "text",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "TxDated" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "datetime",
                "description",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = DxF1::getJsonDecodeOrNull(objectuuid, "nx111")
            Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "Wave" then
            [
                "uuid",
                "mikuType",
                "unixtime",
                "description",
                "nx46",
                "lastDoneDateTime",
            ]
                .each{|attname| ensureAttribute.call(objectuuid, mikuType, attname) }
            nx111 = DxF1::getJsonDecodeOrNull(objectuuid, "nx111")
            Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid, nx111)
            XCache::setFlag(repeatKey, true)
            return
        end

        puts "FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(objectuuid: #{objectuuid}) unsupported MikuType: #{mikuType}"
        if LucilleCore::askQuestionAnswerAsBoolean("delete object ? ") then
            DxF1::deleteObjectLogically(objectuuid)
            return
        end

        raise "FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(objectuuid: #{objectuuid}) unsupported MikuType: #{mikuType}"
    end

    # FileSystemCheck::fsckDxF1FilepathErrorAtFirstFailure(filepath)
    def self.fsckDxF1FilepathErrorAtFirstFailure(filepath)
        puts "FileSystemCheck::fsckDxF1FilepathErrorAtFirstFailure(#{filepath})"
        item = DxF1::getProtoItemAtFilepathOrNull(filepath)
        if item.nil? then
            puts "FileSystemCheck::fsckDxF1FilepathErrorAtFirstFailure(#{filepath}), item was nil"
            exit
        end
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(item["uuid"])
    end

    # FileSystemCheck::fsckErrorAtFirstFailure()
    def self.fsckErrorAtFirstFailure()
        Find.find("#{ENV['HOME']}/Galaxy/DataBank/Stargate/DxF1s") do |path|
            FileSystemCheck::exitIfMissingCanary()
            next if File.basename(path)[-8, 8] != ".sqlite3"
            FileSystemCheck::fsckDxF1FilepathErrorAtFirstFailure(path)
        end
        puts "fsck completed successfully".green
    end
end
