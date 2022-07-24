
class Fx18Utils

    # Fx18Utils::computeLocalFx18Filepath(objectuuid)
    def self.computeLocalFx18Filepath(objectuuid)
        "#{Config::pathToLocalDataBankStargate()}/Fx18s/#{objectuuid}.fx18.sqlite3"
    end

    # Fx18Utils::fileExists?(objectuuid)
    def self.fileExists?(objectuuid)
        File.exists?(Fx18Utils::computeLocalFx18Filepath(objectuuid))
    end

    # Fx18Utils::makeNewFile(objectuuid) # filepath
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
        filepath
    end

    # Fx18Utils::fx18FilepathsFromFileSystem()
    def self.fx18FilepathsFromFileSystem()
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/Fx18s")
            .select{|filepath| filepath[-13, 13] == ".fx18.sqlite3" }
    end

    # Fx18Utils::fx18FilepathsFromFileSystem2(foldepath)
    def self.fx18FilepathsFromFileSystem2(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-13, 13] == ".fx18.sqlite3" }
    end

    # Fx18Utils::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)

        mikuType = Fx18Attributes::getOrNull(objectuuid, "mikuType")
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

        if mikuType == "NxIced" then
            return NxIceds::objectuuidToItemOrNull(objectuuid)
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

    # Fx18Utils::fsckRepository(repository)
    def self.fsckRepository(repository)
        Fx18Utils::fx18FilepathsFromFileSystem2(repository)
            .each{|filepath|
                FileSystemCheck::exitIfMissingCanary()
                FileSystemCheck::fsckFx18Filepath(filepath)
            }
        puts "fsck completed successfully".green
    end

    # Fx18Utils::destroyLocalFx18NoEvent(objectuuid)
    def self.destroyLocalFx18NoEvent(objectuuid)
        filepath = Fx18Utils::computeLocalFx18Filepath(objectuuid)
        return if !File.exists?(filepath)
        puts "delete Fx18 file: #{filepath}"
        FileUtils.rm(filepath)
    end

    # Fx18Utils::destroyLocalFx18EmitEvents(objectuuid)
    def self.destroyLocalFx18EmitEvents(objectuuid)
        Fx18Utils::destroyLocalFx18NoEvent(objectuuid)
        SystemEvents::issueStargateDrop({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        SystemEvents::processEventInternally({
            "mikuType"   => "(object has been deleted)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18Utils::jsonParseIfNotNull(str)
    def self.jsonParseIfNotNull(str)
        return nil if str.nil?
        JSON.parse(str)
    end

    # Fx18Utils::commitEventToObjectuuidNoDrop(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
    def self.commitEventToObjectuuidNoDrop(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
        filepath = Fx18Utils::computeLocalFx18Filepath(objectuuid)
        if !File.exists?(filepath) then
            Fx18Utils::makeNewFile(objectuuid)
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?)", [eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5]
        db.close

        # We do not emit an event here, as this is also called from system event processing
    end

    # Fx18Utils::commitEventToObjectuuidEmitDrop(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
    def self.commitEventToObjectuuidEmitDrop(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
        Fx18Utils::commitEventToObjectuuidNoDrop(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
        Fx18Utils::issueStargateDrop(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
    end

    # Fx18Utils::issueStargateDrop(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
    def self.issueStargateDrop(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
        SystemEvents::issueStargateDrop({
            "mikuType"      => "Fx18 File Event",
            "objectuuid"    => objectuuid,
            "Fx18FileEvent" => {
                "_eventuuid_"  => eventuuid,
                "_eventTime_"  => eventTime,
                "_eventData1_" => eventData1,
                "_eventData2_" => eventData2,
                "_eventData3_" => eventData3,
                "_eventData4_" => eventData4,
                "_eventData5_" => eventData5
            }
        })
    end
end

class Fx18Index1 # (filepath, mikuType, objectuuid, announce, unixtime)

    # Index Management ---------------------------------------------------------------------

    # Fx18Index1::databaseFilepath()
    def self.databaseFilepath()
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/Fx18-Indices/index1.sqlite3"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        filepath
    end

    # Fx18Index1::buildIndexDatabaseFileIfMissing()
    def self.buildIndexDatabaseFileIfMissing()
        filepath = Fx18Index1::databaseFilepath()
        return if File.exists?(filepath)
        puts "Building Index1 Database File"

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _index_ (_filepath_ text primary key, _mikuType_ text, _objectuuid_ text, _announce_ text, _unixtime_ float)"
        db.close
    end

    # Fx18Index1::updateIndexForFilepath(filepath)
    def self.updateIndexForFilepath(filepath)
        puts "Fx18Index1::rebuildIndexData: filepath: #{filepath}"
        
        mikuType = Fx18Attributes::getOrNull2(filepath, "mikuType")
        objectuuid = Fx18Attributes::getOrNull2(filepath, "uuid")
        item = Fx18Utils::objectuuidToItemOrNull(objectuuid)
        return if item.nil?
        announce = "(#{mikuType}) #{LxFunction::function("generic-description", item)}"
        unixtime = item["datetime"] ? DateTime.parse(item["datetime"]).to_time.to_i : item["unixtime"]

        CommonUtils::putsOnPreviousLine("Fx18Index1::rebuildIndexData: filepath: #{filepath} ☑️")

        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _filepath_=?", [filepath]
        db.execute "insert into _index_ (_filepath_, _mikuType_, _objectuuid_, _announce_, _unixtime_) values (?, ?, ?, ?, ?)", [filepath, mikuType, objectuuid, announce, unixtime]
        db.close
    end

    # Fx18Index1::removeEntry(objectuuid)
    def self.removeEntry(objectuuid)
        puts "Fx18Index1::removeEntry(#{objectuuid})"
        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _objectuuid_=?", [objectuuid]
        db.close
    end

    # Fx18Index1::rebuildIndex()
    def self.rebuildIndex()
        Fx18Index1::buildIndexDatabaseFileIfMissing()

        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_"
        db.close

        Fx18Utils::fx18FilepathsFromFileSystem().each{|filepath|
            Fx18Index1::updateIndexForFilepath(filepath)
        }
    end

    # Fx18Index1::buildIndexIfMissingFile()
    def self.buildIndexIfMissingFile()
        filepath = Fx18Index1::databaseFilepath()
        return if File.exists?(filepath)
        puts "Building Index1"
        Fx18Index1::rebuildIndex()
    end

    # Index Read Data ---------------------------------------------------------------------

    # Fx18Index1::filepaths()
    def self.filepaths()
        Fx18Index1::buildIndexIfMissingFile()
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
        Fx18Index1::buildIndexIfMissingFile()
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
        Fx18Index1::buildIndexIfMissingFile()
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

    # Fx18Index1::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        Fx18Index1::mikuType2objectuuids(mikuType).count
    end

    # Fx18Index1::countObjectsByMikuType(mikuType)
    def self.countObjectsByMikuType(mikuType)
        Fx18Index1::mikuType2objectuuids(mikuType).count
    end

    # Fx18Index1::nx20s()
    def self.nx20s()
        Fx18Index1::buildIndexIfMissingFile()
        db = SQLite3::Database.new(Fx18Index1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        nx20s = []
        db.execute("select * from _index_ order by _unixtime_", []) do |row|
            nx20s << {
                "announce"   => row["_announce_"],
                "unixtime"   => row["_unixtime_"],
                "objectuuid" => row["_objectuuid_"]
            }
        end
        db.close
        nx20s
    end
end

class Fx18LocalObjectsDataWithInfinityHelp

    # Fx18LocalObjectsDataWithInfinityHelp::computeStargateCentralFilepath(objectuuid)
    def self.computeStargateCentralFilepath(objectuuid)
        "#{StargateCentral::pathToCentral()}/Fx18s/#{objectuuid}.fx18.sqlite3"
    end

    # Fx18LocalObjectsDataWithInfinityHelp::ensureFileForPut(objectuuid)
    def self.ensureFileForPut(objectuuid)
        filepath = Fx18Utils::computeLocalFx18Filepath(objectuuid)
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "create table _fx18_ (_eventuuid_ text primary key, _eventTime_ float, _eventData1_ blob, _eventData2_ blob, _eventData3_ blob, _eventData4_ blob, _eventData5_ blob);"
            db.close
        end
    end

    # Fx18LocalObjectsDataWithInfinityHelp::putBlob1(objectuuid, eventuuid, eventTime, key, blob)
    def self.putBlob1(objectuuid, eventuuid, eventTime, key, blob)
        Fx18LocalObjectsDataWithInfinityHelp::ensureFileForPut(objectuuid)
        Fx18Utils::commitEventToObjectuuidEmitDrop(objectuuid, eventuuid, eventTime, "datablob", key, blob, nil, nil)
    end

    # Fx18LocalObjectsDataWithInfinityHelp::putBlob2(objectuuid, key, blob)
    def self.putBlob2(objectuuid, key, blob)
        Fx18LocalObjectsDataWithInfinityHelp::putBlob1(objectuuid, SecureRandom.uuid, Time.new.to_f, key, blob)
    end

    # Fx18LocalObjectsDataWithInfinityHelp::putBlob3(objectuuid, blob) # nhash
    def self.putBlob3(objectuuid, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        Fx18LocalObjectsDataWithInfinityHelp::putBlob2(objectuuid, nhash, blob)
        nhash
    end

    # Fx18LocalObjectsDataWithInfinityHelp::getBlobOrNull(objectuuid, nhash)
    def self.getBlobOrNull(objectuuid, nhash)
        filepath1 = Fx18Utils::computeLocalFx18Filepath(objectuuid)
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

        # At this point here is what we gonna do: try to find the file on Stargate Central and get it down on local
        StargateCentral::ensureInfinityDrive()

        filepath2 = Fx18LocalObjectsDataWithInfinityHelp::computeStargateCentralFilepath(objectuuid)
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
                end
                return blob
            end
        end

        nil
    end
end

class Fx18Attributes

    # Fx18Attributes::set1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.set1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "Fx18Attributes::set1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        Fx18Utils::commitEventToObjectuuidEmitDrop(objectuuid, eventuuid, eventTime, "attribute", attname, attvalue, nil, nil)
        SystemEvents::processEventInternally({
            "mikuType" => "(object has been updated)",
            "objectuuid" => objectuuid
        })
        SystemEvents::issueStargateDrop({
            "mikuType" => "(object has been updated)",
            "objectuuid" => objectuuid
        })
    end

    # Fx18Attributes::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        Fx18Attributes::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # Fx18Attributes::getOrNull(objectuuid, attname)
    def self.getOrNull(objectuuid, attname)
        filepath = Fx18Utils::computeLocalFx18Filepath(objectuuid)
        return nil if !File.exists?(filepath)
        Fx18Attributes::getOrNull2(filepath, attname)
    end

    # Fx18Attributes::getOrNull2(filepath, attname)
    def self.getOrNull2(filepath, attname)
        return nil if !File.exists?(filepath)
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

end

class Fx18Sets

    # Fx18Sets::add1(objectuuid, eventuuid, eventTime, setuuid, itemuuid, value)
    def self.add1(objectuuid, eventuuid, eventTime, setuuid, itemuuid, value)
        puts "Fx18Sets::add1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{setuuid}, #{itemuuid}, #{value})"
        Fx18Utils::commitEventToObjectuuidEmitDrop(objectuuid, eventuuid, eventTime, "setops", "add", setuuid, itemuuid, JSON.generate(value))
        SystemEvents::processEventInternally({
            "mikuType" => "(object has been updated)",
            "objectuuid" => objectuuid
        })
        SystemEvents::issueStargateDrop({
            "mikuType" => "(object has been updated)",
            "objectuuid" => objectuuid
        })
    end

    # Fx18Sets::add2(objectuuid, setuuid, itemuuid, value)
    def self.add2(objectuuid, setuuid, itemuuid, value)
        Fx18Sets::add1(objectuuid, SecureRandom.uuid, Time.new.to_f, setuuid, itemuuid, value)
    end

    # Fx18Sets::remove1(objectuuid, eventuuid, eventTime, setuuid, itemuuid)
    def self.remove1(objectuuid, eventuuid, eventTime, setuuid, itemuuid)
        puts "Fx18Sets::remove1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{setuuid}, #{itemuuid})"
        Fx18Utils::commitEventToObjectuuidEmitDrop(objectuuid, eventuuid, eventTime, "setops", "remove", setuuid, itemuuid, nil)
        SystemEvents::processEventInternally({
            "mikuType" => "(object has been updated)",
            "objectuuid" => objectuuid
        })
        SystemEvents::issueStargateDrop({
            "mikuType" => "(object has been updated)",
            "objectuuid" => objectuuid
        })
    end

    # Fx18Sets::remove2(objectuuid, setuuid, itemuuid)
    def self.remove2(objectuuid, setuuid, itemuuid)
        Fx18Sets::remove1(objectuuid, SecureRandom.uuid, Time.new.to_f, setuuid, itemuuid)
    end

    # Fx18Sets::items(objectuuid, setuuid)
    def self.items(objectuuid, setuuid)
        filepath = Fx18Utils::computeLocalFx18Filepath(objectuuid)
        return [] if !File.exists?(filepath)
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

class Fx18ElizabethStandard

    def initialize(objectuuid)
        @objectuuid = objectuuid
    end

    def putBlob(blob)
        Fx18LocalObjectsDataWithInfinityHelp::putBlob3(@objectuuid, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Fx18LocalObjectsDataWithInfinityHelp::getBlobOrNull(@objectuuid, nhash)
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

    # Fx18Synchronisation::syncRepositories(localrepositoryfolderpath, infinityrepositoryfolderpath)
    def self.syncRepositories(localrepositoryfolderpath, infinityrepositoryfolderpath)
        LucilleCore::locationsAtFolder(localrepositoryfolderpath).each{|filepath1|
            next if filepath1[-13, 13] != ".fx18.sqlite3"
            filename = File.basename(filepath1)
            filepath2 = "#{infinityrepositoryfolderpath}/#{filename}"
            if File.exists?(filepath2) then
                Fx18Synchronisation::propagateFileData(filepath1, filepath2)
            else
                puts "FileUtils.cp(#{filepath1}, #{filepath2})"
                FileUtils.cp(filepath1, filepath2) # Moving the local file to infinity
            end
        }

        LucilleCore::locationsAtFolder(infinityrepositoryfolderpath).each{|filepath1|
            objectuuid1 = File.basename(filepath1).gsub(".fx18.sqlite3", "")
            objectuuid2 = Fx18Attributes::getOrNull2(filepath1, "uuid")

            raise "(error: e6fe9b3e-cb37-4899-956c-3121c2597583) filepath1: #{filepath1}" if (objectuuid1 != objectuuid2)
            next if Fx18DeletedFilesMemory::isDeleted(objectuuid1)

            next if filepath1[-13, 13] != ".fx18.sqlite3"
            filename = File.basename(filepath1)
            filepath2 = "#{localrepositoryfolderpath}/#{filename}"
            if File.exists?(filepath2) then
                Fx18Synchronisation::propagateFileData(filepath1, filepath2)
            else
                if Config::get("instanceId") == "Lucille20-pascal" then
                    puts "FileUtils.cp(#{filepath1}, #{filepath2})"
                    FileUtils.cp(filepath1, filepath2) # Moving the infinity file to local
                end
            end
        }
    end

    # Fx18Synchronisation::sync()
    def self.sync()
        StargateCentral::ensureInfinityDrive()
        localrepositoryfolderpath = "#{Config::pathToLocalDataBankStargate()}/Fx18s"
        infinityrepositoryfolderpath = "#{StargateCentral::pathToCentral()}/Fx18s"
        Fx18Synchronisation::syncRepositories(localrepositoryfolderpath, infinityrepositoryfolderpath)
        Fx18Index1::rebuildIndex()
    end
end

class Fx18DeletedFilesMemory

    # Fx18DeletedFilesMemory::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::pathToLocalDataBankStargate()}/fx18-deleted.sqlite3"
    end

    # Fx18DeletedFilesMemory::ensureDatabase()
    def self.ensureDatabase()
        filepath = Fx18DeletedFilesMemory::databaseFilepath()
        return if File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _deleted_ (_objectuuid_ text primary key)"
        db.close
    end

    # Fx18DeletedFilesMemory::registerDeleted(objectuuid)
    def self.registerDeleted(objectuuid)
        Fx18DeletedFilesMemory::ensureDatabase()
        db = SQLite3::Database.new(Fx18DeletedFilesMemory::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _deleted_ where _objectuuid_=?", [objectuuid]
        db.execute "insert into _deleted_ (_objectuuid_) values (?)", [objectuuid]
        db.close
    end

    # Fx18DeletedFilesMemory::isDeleted(objectuuid)
    def self.isDeleted(objectuuid)
        Fx18DeletedFilesMemory::ensureDatabase()
        db = SQLite3::Database.new(Fx18DeletedFilesMemory::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        flag = false
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _deleted_ where _objectuuid_=?", [objectuuid]) do |row|
            flag = true
        end
        db.close
        flag
    end
end
