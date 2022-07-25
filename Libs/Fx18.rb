class Fx18

    # Fx18::fx18Filepath()
    def self.fx18Filepath()
        "#{Config::pathToLocalDataBankStargate()}/Fx18.sqlite3"
    end

    # Fx18::commit(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
    def self.commit(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
        db = SQLite3::Database.new(Fx18::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_objectuuid_, _eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5]
        db.close
    end

    # Fx18::deleteEvent(eventuuid)
    def self.deleteEvent(eventuuid)
        db = SQLite3::Database.new(Fx18::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.close
    end

    # Fx18::destroyObjectNoEvents(objectuuid)
    def self.destroyObjectNoEvents(objectuuid)
        db = SQLite3::Database.new(Fx18::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _objectuuid_=?", [objectuuid]
        db.close
    end

    # Fx18::destroyObject(objectuuid)
    def self.destroyObject(objectuuid)
        db = SQLite3::Database.new(Fx18::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _objectuuid_=?", [objectuuid]
        db.close
        SystemEvents::issueStargateDrop({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        SystemEvents::processEventInternally({
            "mikuType"   => "(object has been deleted)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18::objectuuids()
    def self.objectuuids()
        db = SQLite3::Database.new(Fx18::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select distinct(_objectuuid_) as _objectuuid_ from _fx18_", []) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end
end

class Fx18Utils

    # Fx18Utils::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)

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

    # Fx18Utils::jsonParseIfNotNull(str)
    def self.jsonParseIfNotNull(str)
        return nil if str.nil?
        JSON.parse(str)
    end
end

class Fx18Attributes

    # Fx18Attributes::set1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.set1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "Fx18Attributes::set1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        Fx18::commit(objectuuid, eventuuid, eventTime, "attribute", attname, attvalue, nil, nil)
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
        db = SQLite3::Database.new(Fx18::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _objectuuid_=? and _eventData1_=? and _eventData2_=? order by _eventTime_", [objectuuid, "attribute", attname]) do |row|
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
        Fx18::commit(objectuuid, eventuuid, eventTime, "setops", "add", setuuid, itemuuid, JSON.generate(value))
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
        Fx18::commit(objectuuid, eventuuid, eventTime, "setops", "remove", setuuid, itemuuid, nil)
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
        db = SQLite3::Database.new(Fx18::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true

        # -----------------------------|
        # item = {"itemuuid", "value"} |
        # items = Array[item]          |
        # -----------------------------|

        items = []

        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _objectuuid_=? and _eventData1_=? and _eventData3_=? order by _eventTime_", [objectuuid, "setops", setuuid]) do |row|
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

class Fx18Data

    # Fx18Data::putBlob(objectuuid, blob) # nhash
    def self.putBlob(objectuuid, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        Fx18::commit(objectuuid, SecureRandom.uuid, Time.new.to_f, "datablob", nhash, blob, nil, nil)
        nhash
    end

    # Fx18Data::getBlobOrNull(objectuuid, nhash)
    def self.getBlobOrNull(objectuuid, nhash)
        db = SQLite3::Database.new(Fx18::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _fx18_ where _objectuuid_=? and _eventData1_=? and _eventData2_=?", [objectuuid, "datablob", nhash]) do |row|
            blob = row["_eventData3_"]
        end
        db.close
        blob
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

    # Fx18Synchronisation::getEventuuidsForDatablobsTransfert(filepath)
    def self.getEventuuidsForDatablobsTransfert(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute("select _eventuuid_ from _fx18_ where _eventData1_=?", ["datablob"]) do |row|
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

        (eventuuids1 - eventuuids2).each{|eventuuid|
            puts "Fx18Synchronisation::propagateFileData, filepath1: #{filepath1}, eventuuid: #{eventuuid}"

            record1 = Fx18Synchronisation::getRecordOrNull(filepath1, eventuuid)
            if record1.nil? then
                puts "filepath1: #{filepath1}"
                puts "filepath2: #{filepath2}"
                puts "eventuuid: #{eventuuid}"
                raise "(error: e0f0d25c-48da-44b2-8304-832c3aa14421)"
            end

            Fx18Synchronisation::putRecord(filepath2, record1)

            # Checks
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

    # Fx18Synchronisation::transferDatablobsFromFx18FileToFxData(filepath)
    def self.transferDatablobsFromFx18FileToFxData(filepath)
        Fx18Synchronisation::getEventuuidsForDatablobsTransfert(filepath).each{|eventuuid|
            record1 = Fx18Synchronisation::getRecordOrNull(filepath, eventuuid)
            next if record1["_eventData1_"] != "datablob"
            objectuuid = record1["_objectuuid_"]
            nhash = record1["_eventData2_"]
            puts "Fx18Synchronisation::transferDatablobsFromFx18FileToFxData(): objectuuid: #{objectuuid}, nhash: #{nhash}"
            blob = record1["_eventData3_"]
            FxData::putBlobOnInfinity(objectuuid, blob)
            Fx18::deleteEvent(eventuuid)
        }
    end

    # Fx18Synchronisation::sync()
    def self.sync()
        local = Fx18::fx18Filepath()
        remote = "#{StargateCentral::pathToCentral()}/Fx18.sqlite3"
        
        puts "Fx18Synchronisation::transferDatablobsFromFx18FileToFxData(local)"
        Fx18Synchronisation::transferDatablobsFromFx18FileToFxData(local)

        puts "Fx18Synchronisation::transferDatablobsFromFx18FileToFxData(remote)"
        Fx18Synchronisation::transferDatablobsFromFx18FileToFxData(remote)

        puts "Fx18Synchronisation::propagateFileData(local, remote)"
        Fx18Synchronisation::propagateFileData(local, remote)

        puts "Fx18Synchronisation::propagateFileData(remote, local)"
        Fx18Synchronisation::propagateFileData(remote, local)
    end
end

class Fx18Deleted

    # Fx18Deleted::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::pathToLocalDataBankStargate()}/Fx18-deleted.sqlite3"
    end

    # Fx18Deleted::ensureDatabase()
    def self.ensureDatabase()
        filepath = Fx18Deleted::databaseFilepath()
        return if File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _deleted_ (_objectuuid_ text primary key)"
        db.close
    end

    # Fx18Deleted::registerDeleted(objectuuid)
    def self.registerDeleted(objectuuid)
        Fx18Deleted::ensureDatabase()
        db = SQLite3::Database.new(Fx18Deleted::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _deleted_ where _objectuuid_=?", [objectuuid]
        db.execute "insert into _deleted_ (_objectuuid_) values (?)", [objectuuid]
        db.close
    end

    # Fx18Deleted::isDeleted(objectuuid)
    def self.isDeleted(objectuuid)
        Fx18Deleted::ensureDatabase()
        db = SQLite3::Database.new(Fx18Deleted::databaseFilepath())
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
