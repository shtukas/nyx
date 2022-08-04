
class Fx18

    # Fx18::resetCachePrefix()
    def self.resetCachePrefix()
        XCache::destroy("spectrum:de0991c3-7148-4c61-a976-ba92b1536789")
    end

    # Fx18::cachePrefix()
    def self.cachePrefix()
        prefix = XCache::getOrNull("spectrum:de0991c3-7148-4c61-a976-ba92b1536789")
        if prefix.nil? then
            prefix = SecureRandom.hex
            XCache::set("spectrum:de0991c3-7148-4c61-a976-ba92b1536789", prefix)
        end
        prefix
    end

    # Fx18::localFx18Filepath()
    def self.localFx18Filepath()
        "#{Config::pathToLocalDataBankStargate()}/Fx18.sqlite3"
    end

    # Fx18::localBlockMTime()
    def self.localBlockMTime()
        File.mtime(Fx18::localFx18Filepath()).utc.iso8601
    end

    # Fx18::remoteFx18Filepath()
    def self.remoteFx18Filepath()
        "#{StargateCentral::pathToCentral()}/Fx18.sqlite3"
    end

    # Fx18::commit(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
    def self.commit(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
        if objectuuid.nil? then
            raise "(error: a3202192-2d16-4f82-80e9-a86a18d407c8)"
        end
        if eventuuid.nil? then
            raise "(error: 1025633f-b0aa-42ed-9751-b5f87af23450)"
        end
        if eventTime.nil? then
            raise "(error: 9a6caf6b-fa31-4fda-b963-f0c04f4e50a2)"
        end
        db = SQLite3::Database.new(Fx18::localFx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_objectuuid_, _eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5]
        db.close
    end

    # Fx18::deleteEvent(filepath, eventuuid)
    def self.deleteEvent(filepath, eventuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.close
    end

    # Fx18::deleteObjectNoEvents(objectuuid)
    def self.deleteObjectNoEvents(objectuuid)
        # Insert the object deletion event
        Fx18::commit(objectuuid, SecureRandom.uuid, Time.new.to_f, "object-is-alive", "false", nil, nil, nil)
    end

    # Fx18::deleteObject(objectuuid)
    def self.deleteObject(objectuuid)
        Fx18::deleteObjectNoEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        SystemEvents::processEventInternally({
            "mikuType"   => "(object has been deleted)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18::objectIsAlive(objectuuid)
    def self.objectIsAlive(objectuuid)
        db = SQLite3::Database.new(Fx18::localFx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = true
        db.execute("select * from _fx18_ where _objectuuid_=? and _eventData1_=? order by _eventTime_", [objectuuid, "object-is-alive"]) do |row|
            answer = (row["_eventData2_"] == "true")
        end
        db.close
        answer
    end

    # Fx18::objectuuids()
    def self.objectuuids()
        db = SQLite3::Database.new(Fx18::localFx18Filepath())
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

    # Fx18::jsonParseIfNotNull(str)
    def self.jsonParseIfNotNull(str)
        return nil if str.nil?
        JSON.parse(str)
    end

    # Fx18::playLogFromScratchForLiveItems()
    def self.playLogFromScratchForLiveItems()
        items = {}
        db = SQLite3::Database.new(Fx18::localFx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select * from _fx18_ order by _eventTime_", []) do |row|
            # ---------------------------------------------------------------------------
            # If you make a change here you might want to report it to the other one
            # (group: ff4e41a5-fa0b-459f-9ba7-5a92fb56cf1e)
            objectuuid = row["_objectuuid_"]
            if items[objectuuid].nil? then
                puts "Fx18::playLogFromScratchForLiveItems(): #{objectuuid}"
                items[objectuuid] = {}
            end
            if row["_eventData1_"] == "attribute" then
                attrname  = row["_eventData2_"]
                attrvalue = row["_eventData3_"]
                if attrname == "nx111" then
                    attrvalue = JSON.parse(attrvalue)
                end
                if attrname == "ax39" then
                    attrvalue = JSON.parse(attrvalue)
                end
                if attrname == "nx46" then
                    attrvalue = JSON.parse(attrvalue)
                end
                items[objectuuid][attrname] = attrvalue
            end
            if row["_eventData1_"] == "object-is-alive" then
                isAlive = (row["_eventData2_"] == "true")
                items[objectuuid]["isAlive"] = isAlive
            end
            # ---------------------------------------------------------------------------
        end
        db.close
        items.values.select{|item| item["isAlive"].nil? or item["isAlive"] }
    end

    # Fx18::itemOrNull(objectuuid)
    def self.itemOrNull(objectuuid)
        item = {}
        db = SQLite3::Database.new(Fx18::localFx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select * from _fx18_ where _objectuuid_=? order by _eventTime_", [objectuuid]) do |row|
            # ---------------------------------------------------------------------------
            # If you make a change here you might want to report it to the other one
            # (group: ff4e41a5-fa0b-459f-9ba7-5a92fb56cf1e)
            if row["_eventData1_"] == "attribute" then
                attrname  = row["_eventData2_"]
                attrvalue = row["_eventData3_"]
                if attrname == "nx111" then
                    attrvalue = JSON.parse(attrvalue)
                end
                if attrname == "ax39" then
                    attrvalue = JSON.parse(attrvalue)
                end
                if attrname == "nx46" then
                    attrvalue = JSON.parse(attrvalue)
                end
                item[attrname] = attrvalue
            end
            if row["_eventData1_"] == "object-is-alive" then
                isAlive = (row["_eventData2_"] == "true")
                item["isAlive"] = isAlive
            end
            # ---------------------------------------------------------------------------
        end
        db.close
        return nil if (!item["isAlive"].nil? and !item["isAlive"])
        return nil if item["uuid"].nil?
        item
    end

    # Fx18::broadcastObjectEvents(objectuuid)
    def self.broadcastObjectEvents(objectuuid)
        item = {}
        db = SQLite3::Database.new(Fx18::localFx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select * from _fx18_ where _objectuuid_=? order by _eventTime_", [objectuuid]) do |row|
            SystemEvents::broadcast({
                "mikuType"      => "Fx18 File Event",
                "Fx18FileEvent" => row
            })
        end
        db.close
    end
end

class Fx18Attributes

    # Fx18Attributes::set1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.set1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "Fx18Attributes::set1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        Fx18::commit(objectuuid, eventuuid, eventTime, "attribute", attname, attvalue, nil, nil)
    end

    # Fx18Attributes::set_objectMaking(objectuuid, attname, attvalue)
    def self.set_objectMaking(objectuuid, attname, attvalue)
        Fx18Attributes::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # Fx18Attributes::set_objectUpdate(objectuuid, attname, attvalue)
    def self.set_objectUpdate(objectuuid, attname, attvalue)
        Fx18Attributes::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
        SystemEvents::processEventInternally({
            "mikuType"   => "(object has been updated)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18Attributes::getOrNull(objectuuid, attname)
    def self.getOrNull(objectuuid, attname)
        db = SQLite3::Database.new(Fx18::localFx18Filepath())
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

    # Fx18Sets::add1(objectuuid, eventuuid, eventTime, setuuid, itemuuid, value; going to be JSON serialised)
    def self.add1(objectuuid, eventuuid, eventTime, setuuid, itemuuid, value)
        puts "Fx18Sets::add1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{setuuid}, #{itemuuid}, #{value})"
        Fx18::commit(objectuuid, eventuuid, eventTime, "setops", "add", setuuid, itemuuid, JSON.generate(value))
        SystemEvents::processEventInternally({
            "mikuType"   => "(object has been updated)",
            "objectuuid" => objectuuid,
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
            "mikuType"   => "(object has been updated)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18Sets::remove2(objectuuid, setuuid, itemuuid)
    def self.remove2(objectuuid, setuuid, itemuuid)
        Fx18Sets::remove1(objectuuid, SecureRandom.uuid, Time.new.to_f, setuuid, itemuuid)
    end

    # Fx18Sets::items(objectuuid, setuuid)
    def self.items(objectuuid, setuuid)
        db = SQLite3::Database.new(Fx18::localFx18Filepath())
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

    # Fx18Synchronisation::getDatablobEventuuids(filepath)
    def self.getDatablobEventuuids(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute("select _eventuuid_ from _fx18_ where _eventData1_=? order by _eventData2_", ["datablob"]) do |row|
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
        db.execute "delete from _fx18_ where _eventuuid_=?", [record["_eventuuid_"]]
        db.execute "insert into _fx18_ (_objectuuid_, _eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?, ?)", [record["_objectuuid_"], record["_eventuuid_"], record["_eventTime_"], record["_eventData1_"], record["_eventData2_"], record["_eventData3_"], record["_eventData4_"], record["_eventData5_"]]
        db.close
    end

    # Fx18Synchronisation::propagateFileData(filepath1, filepath2)
    def self.propagateFileData(filepath1, filepath2)
        raise "(error: d5e6f2d3-9eab-484a-bde8-d7e6d479b04f)" if !File.exists?(filepath1)
        raise "(error: 5d24c60a-db47-4643-a618-bb2057daafd2)" if !File.exists?(filepath2)

        eventuuids1 = Fx18Synchronisation::getEventuuids(filepath1)
        eventuuids2 = Fx18Synchronisation::getEventuuids(filepath2)

        (eventuuids1 - eventuuids2).each{|eventuuid|

            record1 = Fx18Synchronisation::getRecordOrNull(filepath1, eventuuid)
            if record1.nil? then
                puts "filepath1: #{filepath1}"
                puts "filepath2: #{filepath2}"
                puts "eventuuid: #{eventuuid}"
                raise "(error: e0f0d25c-48da-44b2-8304-832c3aa14421)"
            end

           puts "Fx18Synchronisation::propagateFileData, filepath1: #{filepath1}, objectuuid: #{record1["_objectuuid_"]}, eventuuid: #{eventuuid}"

            Fx18Synchronisation::putRecord(filepath2, record1)

            # clear that line in the Lookup, but without deleting it
            Lookup1::removeObjectuuid(record1["_objectuuid_"])

            if Fx18::objectIsAlive(record1["_eventData1_"]) == "object-is-alive" and record1["_eventData2_"] == "false" then
                # If filepath1 is local then the item should have already been deleted from the Lookup
                # If filepath1 is remote then we are performing a true deletion.
                Lookup1::removeObjectuuid(record1["_objectuuid_"])
            end

            if Fx18::objectIsAlive(record1["_eventData1_"]) == "object-is-alive" and record1["_eventData2_"] == "true" then
                # At the time those lines are written, we don't even have a way to resuscitate
                # an object, but if we do, it goes here
                Lookup1::reconstructEntry(record1["_objectuuid_"])
            end

            # Checks
            record2 = Fx18Synchronisation::getRecordOrNull(filepath2, eventuuid)
            if record2.nil? then
                puts "filepath1: #{filepath1}"
                puts "filepath2: #{filepath2}"
                puts "eventuuid: #{eventuuid}"
                raise "(error: 9ad32d45-bbe4-4121-ab08-ff60a644ece4)"
            end
            [
                "_objectuuid_", 
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

    # Fx18Synchronisation::sync()
    def self.sync()

        [Fx18::localFx18Filepath(), Fx18::remoteFx18Filepath()].each{|filepath|
            Fx18Synchronisation::getDatablobEventuuids(filepath).each{|eventuuid|
                record = Fx18Synchronisation::getRecordOrNull(filepath, eventuuid)
                puts "(#{filepath}) Extracting datablob: #{record["_eventData2_"]}"
                ExData::putBlobOnInfinity(record["_eventData3_"])
                Fx18::deleteEvent(filepath, eventuuid)
            }
        }

        LucilleCore::locationsAtFolder("#{Config::pathToLocalDataBankStargate()}/Datablobs").each{|filepath|
            next if filepath[-5, 5] != ".data"
            puts "Fx18Synchronisation::sync(): transferring blob: #{filepath}"
            blob = IO.read(filepath)
            ExData::putBlobOnInfinity(blob)
            FileUtils.rm(filepath)
        }

        Fx18Synchronisation::propagateFileData(Fx18::localFx18Filepath(), Fx18::remoteFx18Filepath())
        Fx18Synchronisation::propagateFileData(Fx18::remoteFx18Filepath(), Fx18::localFx18Filepath())
    end
end
