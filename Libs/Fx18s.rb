
class Fx18s

    # --------------------------------------------------------------

    # Fx18s::computeLocalFx18Filepath(objectuuid)
    def self.computeLocalFx18Filepath(objectuuid)
        "#{Config::pathToDataBankStargate()}/Fx18s/#{objectuuid}.fx18.sqlite3"
    end

    # Fx18s::constructNewFile(objectuuid) # location (That function constructs the database and creates the _fx18_ table)
    def self.constructNewFile(objectuuid)
        filepath = Fx18s::computeLocalFx18Filepath(objectuuid)
        if File.exists?(filepath) then
            puts "operation: Fx18s::constructNewFile"
            puts "objectuuid: #{objectuuid}"
            puts "filepath: #{filepath}"
            raise "(error: a906e951-c38e-4b96-a6b4-0084df2ff854) file already exists"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _fx18_ (_eventuuid_ text primary key, _eventTime_ float, _eventData1_ blob, _eventData2_ blob, _eventData3_ blob, _eventData4_ blob, _eventData5_ blob);"
        db.close
    end

    # Fx18s::ensureFile(objectuuid)
    # Only used for migrations
    def self.ensureFile(objectuuid)
        filepath = Fx18s::computeLocalFx18Filepath(objectuuid)
        return if File.exists?(filepath)
        Fx18s::constructNewFile(objectuuid)
    end

    # Fx18s::acquireFilepathOrError(objectuuid)
    def self.acquireFilepathOrError(objectuuid)
        Fx18s::computeLocalFx18Filepath(objectuuid)
    end

    # --------------------------------------------------------------

    # Fx18s::setAttribute1(eventuuid, eventTime, objectuuid, attname, attvalue)
    def self.setAttribute1(eventuuid, eventTime, objectuuid, attname, attvalue)
        puts "Fx18s::setAttribute1(#{eventuuid}, #{eventTime}, #{objectuuid}, #{attname}, #{attvalue})"
        filepath = Fx18s::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, "attribute", attname, attvalue]
        db.close

        if attname == "mikuType" then
            SystemEvents::processEvent({
                "mikuType" => "(object has a new mikuType)",
                "objectuuid" => objectuuid,
                "objectMikuType" => attvalue
            }, false)
        end
    end

    # Fx18s::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        Fx18s::setAttribute1(SecureRandom.uuid, Time.new.to_f, objectuuid, attname, attvalue)
    end

    # Fx18s::getAttributeOrNull(objectuuid, attname)
    def self.getAttributeOrNull(objectuuid, attname)
        filepath = Fx18s::acquireFilepathOrError(objectuuid)
        Fx18s::getAttributeOrNull2(filepath, attname)
    end

    # Fx18s::getAttributeOrNull2(filepath, attname)
    def self.getAttributeOrNull2(filepath, attname)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _eventData1_=? and _eventData2_=? order by _eventTime_", ["attribute", attname]) do |row|
            attvalue = row["_eventData3_"]
        end
        db.close
        attvalue
    end

    # --------------------------------------------------------------

    # Fx18s::setsAdd1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value)
    def self.setsAdd1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value)
        puts "Fx18s::setsAdd1(#{eventuuid}, #{eventTime}, #{objectuuid}, #{setuuid}, #{itemuuid}, #{value})"
        filepath = Fx18s::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?)", [eventuuid, eventTime, "setops", "add", setuuid, itemuuid, JSON.generate(value)]
        db.close
    end

    # Fx18s::setsAdd2(objectuuid, setuuid, itemuuid, value)
    def self.setsAdd2(objectuuid, setuuid, itemuuid, value)
        Fx18s::setsAdd1(SecureRandom.uuid, Time.new.to_f, objectuuid, setuuid, itemuuid, value)
    end

    # Fx18s::setsRemove1(eventuuid, eventTime, objectuuid, setuuid, itemuuid)
    def self.setsRemove1(eventuuid, eventTime, objectuuid, setuuid, itemuuid)
        puts "Fx18s::setsRemove1(#{eventuuid}, #{eventTime}, #{objectuuid}, #{setuuid}, #{itemuuid})"
        filepath = Fx18s::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_) values (?, ?, ?, ?, ?, ?)", [eventuuid, eventTime, "setops", "remove", setuuid, itemuuid]
        db.close
    end

    # Fx18s::setsRemove2(objectuuid, setuuid, itemuuid)
    def self.setsRemove2(objectuuid, setuuid, itemuuid)
        Fx18s::setsRemove1(SecureRandom.uuid, Time.new.to_f, objectuuid, setuuid, itemuuid)
    end

    # Fx18s::setsItems(objectuuid, setuuid)
    def self.setsItems(objectuuid, setuuid)
        filepath = Fx18s::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true

        # -----------------------------|
        # item = {"itemuuid", "value"} |
        # items = Array[item]          |
        # -----------------------------|

        items = []

        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _eventData1_=? and _eventData3_=? order by _eventTime_", ["setops", setuuid]) do |row|
            operation = row["_eventData2_"]
            if operation == "add" then
                itemuuid = row["_eventData4_"]
                value = JSON.parse(row["_eventData5_"])
                items = items.reject{|item| item["itemuuid"] == itemuuid } # remove any existing item with that itemuuid
                items << {"itemuuid" => itemuuid, "value" => value}        # performing the add operation
            end
            if operation == "remove" then
                itemuuid = row["_eventData4_"]
                items = items.reject{|item| item["itemuuid"] == itemuuid } # remove the item with that itemuuid
            end
        end
        db.close
        
        items.map{|item| item["value"]}
    end

    # --------------------------------------------------------------

    # Fx18s::putBlob1(eventuuid, eventTime, objectuuid, key, blob)
    def self.putBlob1(eventuuid, eventTime, objectuuid, key, blob)
        puts "Fx18s::putBlob1(#{eventuuid}, #{eventTime}, #{objectuuid}, #{key}, blob)"
        Fx18s::ensureFile(objectuuid)
        filepath = Fx18s::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, "datablob", key, blob]
        db.close
    end

    # Fx18s::putBlob2(objectuuid, key, blob)
    def self.putBlob2(objectuuid, key, blob)
        Fx18s::putBlob1(SecureRandom.uuid, Time.new.to_f, objectuuid, key, blob)
    end

    # Fx18s::putBlob3(objectuuid, blob) # nhash
    def self.putBlob3(objectuuid, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        Fx18s::putBlob2(objectuuid, nhash, blob)
        nhash
    end

    # Fx18s::getBlobOrNull(objectuuid, nhash)
    def self.getBlobOrNull(objectuuid, nhash)
        Fx18s::ensureFile(objectuuid)

        filepath = Fx18s::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _fx18_ where _eventData1_=? and _eventData2_=?", ["datablob", nhash]) do |row|
            blob = row["_eventData3_"]
        end
        db.close
        return blob if blob

        nil
    end

    # Fx18s::destroy(objectuuid)
    def self.destroy(objectuuid)
        # TODO:
    end
end

class Fx18Elizabeth

    def initialize(objectuuid)
        @objectuuid = objectuuid
    end

    def putBlob(blob)
        Fx18s::putBlob3(@objectuuid, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Fx18s::getBlobOrNull(@objectuuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "EnergyGridImmutableDataIslandElizabeth: (error: 18e9ac55-934b-4153-8cde-a93a6504d237) could not find blob, nhash: #{nhash}"
        raise "(error: 744f2b80-2c30-497f-ae5e-b6fc26799cbd, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 466a0cab-a836-4643-a66a-b9e38aae1c1f) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class Fx18Xp

    # Fx18Xp::fx18Filepaths()
    def self.fx18Filepaths()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Stargate/Fx18s")
    end

    # Fx18Xp::fsck(shouldReset)
    def self.fsck(shouldReset)
        runHash = XCache::getOrNull("76001cea-f0c6-4e68-862b-5060d3c8bcd5")

        if runHash.nil? then
            runHash = SecureRandom.hex
            XCache::set("76001cea-f0c6-4e68-862b-5060d3c8bcd5", runHash)
        end

        if shouldReset then
            puts "resetting fsck runhash"
            sleep 1
            runHash = SecureRandom.hex
            XCache::set("76001cea-f0c6-4e68-862b-5060d3c8bcd5", runHash)
        end

        Fx18Xp::fx18Filepaths()
            .each{|filepath|
                FileSystemCheck::exitIfMissingCanary()
                trace = "#{runHash}:#{Digest::SHA1.file(filepath).hexdigest}"
                next if XCache::getFlag(trace)
                FileSystemCheck::fsckFx18FilepathExitAtFirstFailure(filepath)
                XCache::setFlag(trace, true)
            }
        puts "fsck completed successfully".green
    end

    # Fx18Xp::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        mikuType = Fx18s::getAttributeOrNull(objectuuid, "mikuType")
        return nil if mikuType.nil?

        if mikuType == "Ax1Text" then
            return Ax1Text::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxAnniversary" then
            return Anniversaries::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxCollection" then
            return NxCollections::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxConcept" then
            return NxConcepts::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxDataNode" then
            return NxDataNodes::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxEntity" then
            return NxEntities::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxEvent" then
            return NxEvents::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxFrame" then
            return NxFrames::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxLine" then
            return NxLines::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxPerson" then
            return NxPersons::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxTask" then
            return NxTasks::objectuuidToItem(objectuuid)
        end

        if mikuType == "NxTimeline" then
            return NxTimelines::objectuuidToItem(objectuuid)
        end

        if mikuType == "TxDated" then
            return TxDateds::objectuuidToItem(objectuuid)
        end

        if mikuType == "TxProject" then
            return TxProjects::objectuuidToItem(objectuuid)
        end

        if mikuType == "Wave" then
            return Waves::objectuuidToItem(objectuuid)
        end

        raise "(error: 6e7b52de-cdc5-4a57-b215-aee766d11467) mikuType: #{mikuType}"
    end
end

