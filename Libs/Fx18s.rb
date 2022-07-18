
class Fx18Utils

    # Fx18Utils::computeLocalFx18Filepath(objectuuid)
    def self.computeLocalFx18Filepath(objectuuid)
        "#{Config::pathToDataBankStargate()}/Fx18s/#{objectuuid}.fx18.sqlite3"
    end

    # Fx18Utils::fileExists?(objectuuid)
    def self.fileExists?(objectuuid)
        File.exists?(Fx18Utils::computeLocalFx18Filepath(objectuuid))
    end

    # Fx18Utils::makeNewFile(objectuuid)
    def self.makeNewFile(objectuuid)
        filepath = Fx18Utils::computeLocalFx18Filepath(objectuuid)
        if File.exists?(filepath) then
            puts "operation: Fx18Utils::makeNewFile"
            puts "objectuuid: #{objectuuid}"
            puts "filepath: #{filepath}"
            raise "(error: 501f3d32-118f-4844-94e2-f93f96d50fcc) attempting to create a Fx18 file that already exists"
            exit 1
        end

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _fx18_ (_eventuuid_ text primary key, _eventTime_ float, _eventData1_ blob, _eventData2_ blob, _eventData3_ blob, _eventData4_ blob, _eventData5_ blob);"
        db.close
    end

    # Fx18Utils::acquireFilepathOrError(objectuuid)
    def self.acquireFilepathOrError(objectuuid)
        filepath = Fx18Utils::computeLocalFx18Filepath(objectuuid)
        if !File.exists?(filepath) then
            puts "operation: Fx18Utils::acquireFilepathOrError"
            puts "objectuuid: #{objectuuid}"
            puts "filepath: #{filepath}"
            raise "(error: a76f302d-f376-4d4f-ac2b-dea3f19696e7)"
            exit 1
        end
        filepath
    end

    # Fx18Utils::fx18FilepathsFromFileSystem()
    def self.fx18FilepathsFromFileSystem()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Stargate/Fx18s")
            .select{|filepath| filepath[-13, 13] == ".fx18.sqlite3" }
    end

    # Fx18Utils::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)

        mikuType = Fx18File::getAttributeOrNull(objectuuid, "mikuType")
        return nil if mikuType.nil?

        if mikuType == "Ax1Text" then
            return Ax1Text::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxAnniversary" then
            return Anniversaries::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxCollection" then
            return NxCollections::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxConcept" then
            return NxConcepts::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxDataNode" then
            return NxDataNodes::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxEntity" then
            return NxEntities::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxEvent" then
            return NxEvents::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxFrame" then
            return NxFrames::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxLine" then
            return NxLines::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxPerson" then
            return NxPersons::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxTask" then
            return NxTasks::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "NxTimeline" then
            return NxTimelines::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "TxDated" then
            return TxDateds::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "TxProject" then
            return TxProjects::objectuuidToItemOrNull(objectuuid)
        end

        if mikuType == "Wave" then
            return Waves::objectuuidToItemOrNull(objectuuid)
        end

        raise "(error: 6e7b52de-cdc5-4a57-b215-aee766d11467) mikuType: #{mikuType}"
    end

    # Fx18Utils::fsck(shouldReset)
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

        Fx18Utils::fx18FilepathsFromFileSystem()
            .each{|filepath|
                FileSystemCheck::exitIfMissingCanary()
                trace = "#{runHash}:#{Digest::SHA1.file(filepath).hexdigest}"
                next if XCache::getFlag(trace)
                FileSystemCheck::fsckFx18FilepathExitAtFirstFailure(filepath)

                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("vacuum", [])
                db.close

                XCache::setFlag(trace, true)
            }
        puts "fsck completed successfully".green
    end

    # Fx18Utils::destroyFx18Logically(objectuuid)
    def self.destroy(objectuuid)
        # TODO:
    end

    # Fx18Utils::destroyFx18Logically(uuid)
    def self.destroyFx18Logically(uuid)
        # TODO:
        SystemEvents::sendEventToSQSStage1({
            "uuid"     => uuid,
            "variant"  => SecureRandom.uuid,
            "mikuType" => "NxDeleted",
        })
        SystemEvents::processEvent({
            "mikuType"   => "(object has been deleted)",
            "objectuuid" => uuid,
        }, true)
    end
end

class Fx18Index1 # (filepath, mikuType, objectuuid)

    # Fx18Index1::databaseFilepath()
    def self.databaseFilepath()
        filepath = "/Users/pascal/Galaxy/DataBank/Stargate/Fx18-Indices/index1.sqlite3"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        filepath
    end

    # Fx18Index1::rebuildIndexData()
    def self.rebuildIndexData()

        databaseFilepath = Fx18Index1::databaseFilepath()

        # Step 1
        db = SQLite3::Database.new(databaseFilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_"
        db.close

        Fx18Utils::fx18FilepathsFromFileSystem().each{|filepath|
            mikuType = Fx18File::getAttributeOrNull2(filepath, "mikuType")
            objectuuid = Fx18File::getAttributeOrNull2(filepath, "uuid")
            db = SQLite3::Database.new(databaseFilepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from _index_ where _filepath_=?", [filepath]
            db.execute "insert into _index_ (_filepath_, _mikuType_, _objectuuid_) values (?, ?, ?)", [filepath, mikuType, objectuuid]
            db.close
        }
    end

    # Fx18Index1::buildIndexIfMissing()
    def self.buildIndexIfMissing()
        filepath = Fx18Index1::databaseFilepath()
        return if File.exists?(filepath)
        puts "Building Index1"



        # Step 1
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _index_ (_filepath_ text primary key, _mikuType_ text, _objectuuid_ text)"
        db.close

        # Step 2
        Fx18Index1::rebuildIndexData()
    end

    # Fx18Index1::filepaths()
    def self.filepaths()
        Fx18Index1::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        filepaths = []
        db.execute("select * from _index_ order by _filepath_", []) do |row|
            filepaths << row["_filepath_"]
        end
        db.close
        filepaths
    end

    # Fx18Index1::mikuTypes()
    def self.mikuTypes()
        Fx18Index1::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        mikuTypes = []
        db.execute("select * from _index_ order by _mikuType_", []) do |row|
            mikuTypes << row["_mikuType_"]
        end
        db.close
        mikuTypes.uniq
    end

    # Fx18Index1::mikuType2objectuuids(mikuType)
    def self.mikuType2objectuuids(mikuType)
        Fx18Index1::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select * from _index_ where _mikuType_=?", [mikuType]) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # Fx18Index1::countObjectsByMikuType(mikuType)
    def self.countObjectsByMikuType(mikuType)
        Fx18Index1::mikuType2objectuuids(mikuType).count
    end

    # Fx18Index1::updateIndexForFilepath(filepath)
    def self.updateIndexForFilepath(filepath)
        Fx18Index1::buildIndexIfMissing()
        mikuType = Fx18File::getAttributeOrNull2(filepath, "mikuType")
        objectuuid = Fx18File::getAttributeOrNull2(filepath, "uuid")
        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _filepath_=?", [filepath]
        db.execute "insert into _index_ (_filepath_, _mikuType_, _objectuuid_) values (?, ?, ?)", [filepath, mikuType, objectuuid]
        db.close
    end

    # Fx18Index1::removeRecordForObjectUUID(objectuuid)
    def self.removeRecordForObjectUUID(objectuuid)
        Fx18Index1::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _objectuuid_=?", [objectuuid]
        db.close
    end
end

class Fx19Data

    # Fx19Data::computeLocalFilepath(objectuuid)
    def self.computeLocalFilepath(objectuuid)
        "#{Config::pathToDataBankStargate()}/Fx18s/#{objectuuid}.fx19.sqlite3"
    end

    # Fx19Data::computeStargateCentralFilepath(objectuuid)
    def self.computeStargateCentralFilepath(objectuuid)
        "#{StargateCentral::pathToCentral()}/Fx18s/#{objectuuid}.fx19.sqlite3"
    end

    # Fx19Data::ensureFileForPut(objectuuid)
    def self.ensureFileForPut(objectuuid)
        filepath = Fx19Data::computeLocalFilepath(objectuuid)
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "create table _fx18_ (_eventuuid_ text primary key, _eventTime_ float, _eventData1_ blob, _eventData2_ blob, _eventData3_ blob, _eventData4_ blob, _eventData5_ blob);"
            db.close
        end
        filepath
    end

    # Fx19Data::putBlob1(eventuuid, eventTime, objectuuid, key, blob)
    def self.putBlob1(eventuuid, eventTime, objectuuid, key, blob)
        filepath = Fx19Data::ensureFileForPut(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, "datablob", key, blob]
        db.close
    end

    # Fx19Data::putBlob2(objectuuid, key, blob)
    def self.putBlob2(objectuuid, key, blob)
        Fx19Data::putBlob1(SecureRandom.uuid, Time.new.to_f, objectuuid, key, blob)
    end

    # Fx19Data::putBlob3(objectuuid, blob) # nhash
    def self.putBlob3(objectuuid, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        Fx19Data::putBlob2(objectuuid, nhash, blob)
        nhash
    end

    # Fx19Data::getBlobOrNull(objectuuid, nhash)
    def self.getBlobOrNull(objectuuid, nhash)
        filepath1 = Fx19Data::computeLocalFilepath(objectuuid)
        if File.exists?(filepath1) then
            db = SQLite3::Database.new(filepath1)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            blob = nil
            db.execute("select * from _fx18_ where _eventData1_=? and _eventData2_=?", ["datablob", nhash]) do |row|
                blob = row["_eventData3_"]
            end
            db.close
            return blob if blob
        end

        # At this point here is what we gonnae do: try to find the file on Stargate Central and get it down on local
        StargateCentral::ensureInfinityDrive()

        filepath2 = Fx19Data::computeStargateCentralFilepath(objectuuid)
        if File.exists?(filepath2) then
            db = SQLite3::Database.new(filepath2)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            blob = nil
            db.execute("select * from _fx18_ where _eventData1_=? and _eventData2_=?", ["datablob", nhash]) do |row|
                blob = row["_eventData3_"]
            end
            db.close
            if blob then
                if File.exists?(filepath1) then
                    puts "Fx18Synchronisation::propagateFileData, filepath1: #{filepath1}"
                    Fx18Synchronisation::propagateFileData(filepath2, filepath1)
                else
                    puts "FileUtils.cp(#{filepath2}, #{filepath1})"
                    FileUtils.cp(filepath2, filepath1)
                end
                return blob
            end
        end

        nil
    end
end

class Fx18File

    # --------------------------------------------------------------

    # Fx18File::setAttribute1(eventuuid, eventTime, objectuuid, attname, attvalue)
    def self.setAttribute1(eventuuid, eventTime, objectuuid, attname, attvalue)
        puts "Fx18File::setAttribute1(#{eventuuid}, #{eventTime}, #{objectuuid}, #{attname}, #{attvalue})"
        filepath = Fx18Utils::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, "attribute", attname, attvalue]
        db.close

        if attname == "mikuType" then
            SystemEvents::processEvent({
                "mikuType" => "(object has a new mikuType)",
                "objectuuid" => objectuuid
            }, false)
            SystemEvents::sendEventToSQSStage1({
                "mikuType" => "(object has a new mikuType)",
                "objectuuid" => objectuuid
            })
        end
    end

    # Fx18File::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        Fx18File::setAttribute1(SecureRandom.uuid, Time.new.to_f, objectuuid, attname, attvalue)
    end

    # Fx18File::getAttributeOrNull(objectuuid, attname)
    def self.getAttributeOrNull(objectuuid, attname)
        filepath = Fx18Utils::acquireFilepathOrError(objectuuid)
        Fx18File::getAttributeOrNull2(filepath, attname)
    end

    # Fx18File::getAttributeOrNull2(filepath, attname)
    def self.getAttributeOrNull2(filepath, attname)
        raise "(error: 90beb330-8a09-4909-b8e0-d4522fe66daf) filepath: #{filepath}" if !File.exists?(filepath)
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

    # Fx18File::setsAdd1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value)
    def self.setsAdd1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value)
        puts "Fx18File::setsAdd1(#{eventuuid}, #{eventTime}, #{objectuuid}, #{setuuid}, #{itemuuid}, #{value})"
        filepath = Fx18Utils::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?)", [eventuuid, eventTime, "setops", "add", setuuid, itemuuid, JSON.generate(value)]
        db.close
    end

    # Fx18File::setsAdd2(objectuuid, setuuid, itemuuid, value)
    def self.setsAdd2(objectuuid, setuuid, itemuuid, value)
        Fx18File::setsAdd1(SecureRandom.uuid, Time.new.to_f, objectuuid, setuuid, itemuuid, value)
    end

    # Fx18File::setsRemove1(eventuuid, eventTime, objectuuid, setuuid, itemuuid)
    def self.setsRemove1(eventuuid, eventTime, objectuuid, setuuid, itemuuid)
        puts "Fx18File::setsRemove1(#{eventuuid}, #{eventTime}, #{objectuuid}, #{setuuid}, #{itemuuid})"
        filepath = Fx18Utils::acquireFilepathOrError(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_) values (?, ?, ?, ?, ?, ?)", [eventuuid, eventTime, "setops", "remove", setuuid, itemuuid]
        db.close
    end

    # Fx18File::setsRemove2(objectuuid, setuuid, itemuuid)
    def self.setsRemove2(objectuuid, setuuid, itemuuid)
        Fx18File::setsRemove1(SecureRandom.uuid, Time.new.to_f, objectuuid, setuuid, itemuuid)
    end

    # Fx18File::setsItems(objectuuid, setuuid)
    def self.setsItems(objectuuid, setuuid)
        filepath = Fx18Utils::acquireFilepathOrError(objectuuid)
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
end

class Fx18Elizabeth

    def initialize(objectuuid)
        @objectuuid = objectuuid
    end

    def putBlob(blob)
        Fx19Data::putBlob3(@objectuuid, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Fx19Data::getBlobOrNull(@objectuuid, nhash)
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

class Fx18Synchronisation

    # Fx18Synchronisation::getEventuuids(filepath)
    def self.getEventuuids(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute("select _eventuuid_ from _fx18_", []) do |row|
            uuids << row["_eventuuid_"]
        end
        db.close
        uuids
    end

    # Fx18Synchronisation::getRecordOrNull(filepath, eventuuid)
    def self.getRecordOrNull(filepath, eventuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        record = nil
        db.execute("select * from _fx18_ where _eventuuid_=?", [eventuuid]) do |row|
            record = row
        end
        db.close
        record
    end

    # Fx18Synchronisation::putRecord(filepath, record)
    def self.putRecord(filepath, record)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?)", [record["_eventuuid_"], record["_eventTime_"], record["_eventData1_"], record["_eventData2_"], record["_eventData3_"], record["_eventData4_"], record["_eventData5_"]]
        db.close
    end

    # Fx18Synchronisation::propagateFileData(filepath1, filepath2)
    def self.propagateFileData(filepath1, filepath2)
        raise "(error: d5e6f2d3-9eab-484a-bde8-d7e6d479b04f)" if !File.exists?(filepath1)

        raise "(error: 5d24c60a-db47-4643-a618-bb2057daafd2)" if !File.exists?(filepath2)

        # Get the events ids from file1
        eventuuids1 = Fx18Synchronisation::getEventuuids(filepath1)

        # Get the events ids from file2
        eventuuids2 = Fx18Synchronisation::getEventuuids(filepath2)

        # For each event in eventuuids1 if the event is in file1 but not in file2, then add the entire record in file2
        eventuuids1.each{|eventuuid|
            next if eventuuids2.include?(eventuuid) # already in the target file
            record1 = Fx18Synchronisation::getRecordOrNull(filepath1, eventuuid)
            if record1.nil? then
                puts "filepath1: #{filepath1}"
                puts "filepath2: #{filepath2}"
                puts "eventuuid: #{eventuuid}"
                raise "(error: e0f0d25c-48da-44b2-8304-832c3aa14421)"
            end
            puts "Fx18Synchronisation::propagateFileData, filepath1: #{filepath1}, eventuuid: #{eventuuid}"
            Fx18Synchronisation::putRecord(filepath2, record1)
            record2 = Fx18Synchronisation::getRecordOrNull(filepath2, eventuuid)
            if record2.nil? then
                puts "filepath1: #{filepath1}"
                puts "filepath2: #{filepath2}"
                puts "eventuuid: #{eventuuid}"
                raise "(error: 9ad32d45-bbe4-4121-ab08-ff60a644ece4)"
            end
            [
                "_eventuuid_", 
                "_eventTime_", 
                "_eventData1_",
                "_eventData2_",
                "_eventData3_",
                "_eventData4_",
                "_eventData5_"
            ].each{|key|
                if record1[key] != record2[key] then
                    puts "filepath1: #{filepath1}"
                    puts "filepath2: #{filepath2}"
                    puts "eventuuid: #{eventuuid}"
                    puts "key: #{key}"
                    raise "(error: 5c04dc70-9024-414c-bab6-a9f9dee871ce)"
                end
            }
        }
    end

    # Fx18Synchronisation::propagateRepository(folderpath1, folderpath2, shouldMoveFx19s)
    def self.propagateRepository(folderpath1, folderpath2, shouldMoveFx19s)

        LucilleCore::locationsAtFolder(folderpath1).each{|filepath1|
            next if filepath1[-13, 13] != ".fx18.sqlite3"
            filename = File.basename(filepath1)
            filepath2 = "#{folderpath2}/#{filename}"
            if File.exists?(filepath2) then
                puts "[repo sync] propagate file data; file: #{filepath1}"
                Fx18Synchronisation::propagateFileData(filepath1, filepath2)
            else
                puts "[repo sync] copy file: #{filepath1}"
                FileUtils.cp(filepath1, filepath2)
            end
        }

        LucilleCore::locationsAtFolder(folderpath1).each{|filepath1|
            next if filepath1[-13, 13] != ".fx19.sqlite3"
            filename = File.basename(filepath1)
            filepath2 = "#{folderpath2}/#{filename}"
            if File.exists?(filepath2) then
                puts "[repo sync] propagate file data; file: #{filepath1}"
                Fx18Synchronisation::propagateFileData(filepath1, filepath2)
            else
                if shouldMoveFx19s then
                    puts "[repo sync] copy file: #{filepath1}"
                    FileUtils.cp(filepath1, filepath2)
                end
            end
        }
    end

    # Fx18Synchronisation::sync()
    def self.sync()
        StargateCentral::ensureInfinityDrive()
        folderpath1 = "#{Config::pathToDataBankStargate()}/Fx18s"
        folderpath2 = "#{StargateCentral::pathToCentral()}/Fx18s"
        Fx18Synchronisation::propagateRepository(folderpath1, folderpath2, true)
        Fx18Synchronisation::propagateRepository(folderpath2, folderpath1, false)
    end
end
