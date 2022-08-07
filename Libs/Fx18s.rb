
class Fx18s

    # Fx18s::makeNewFx18File(filepath)
    def self.makeNewFx18File(filepath)
        puts "Initiate database #{filepath}"
        folderpath = File.dirname(filepath)
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _fx18_ (_objectuuid_ text, _eventuuid_ text primary key, _eventTime_ float, _eventData1_ blob, _eventData2_ blob, _eventData3_ blob, _eventData4_ blob, _eventData5_ blob)", [])
        db.close
    end

    # Fx18s::makeNewFx18FileForObjectuuid(uuid)
    def self.makeNewFx18FileForObjectuuid(uuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        filepath = "#{Config::pathToLocalDataBankStargate()}/Fx18s/#{sha1[0, 2]}/#{sha1}.sqlite3"
        Fx18s::makeNewFx18File(filepath)
    end

    # Fx18s::getExistingFx18FilepathForObjectuuid(objectuuid)
    def self.getExistingFx18FilepathForObjectuuid(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        filepath = "#{Config::pathToLocalDataBankStargate()}/Fx18s/#{sha1[0, 2]}/#{sha1}.sqlite3"
        if !File.exists?(filepath) then
            raise "(error: 7a6f4737-5030-4653-bf59-09f6d301b471) filepath: #{filepath}"
        end
        filepath
    end

    # Fx18s::getExistingRemoteFx18FilepathForObjectuuid(objectuuid)
    def self.getExistingRemoteFx18FilepathForObjectuuid(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        filepath = "#{StargateCentral::pathToCentral()}/Fx18s/#{sha1[0, 2]}/#{sha1}.sqlite3"
        if !File.exists?(filepath) then
            raise "(error: cc021cbe-4bc9-4e42-a5c7-e98b696cc5d4) filepath: #{filepath}"
        end
        filepath
    end

    # Fx18s::commit(objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5)
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
        db = SQLite3::Database.new(Fx18s::getExistingFx18FilepathForObjectuuid(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_objectuuid_, _eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, eventData1, eventData2, eventData3, eventData4, eventData5]
        db.close
    end

    # Fx18s::deleteObjectNoEvents(objectuuid)
    def self.deleteObjectNoEvents(objectuuid)
        # Insert the object deletion event
        Fx18s::commit(objectuuid, SecureRandom.uuid, Time.new.to_f, "object-is-alive", "false", nil, nil, nil)
    end

    # Fx18s::deleteObject(objectuuid)
    def self.deleteObject(objectuuid)
        Fx18s::deleteObjectNoEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        SystemEvents::processEventInternally({
            "mikuType"   => "(object has been deleted)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18s::objectIsAlive(objectuuid)
    def self.objectIsAlive(objectuuid)
        db = SQLite3::Database.new(Fx18s::getExistingFx18FilepathForObjectuuid(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = true
        db.execute("select * from _fx18_ where _eventData1_=? order by _eventTime_", ["object-is-alive"]) do |row|
            answer = (row["_eventData2_"] == "true")
        end
        db.close
        answer
    end

    # Fx18s::itemIncludingDeletedOrNull(objectuuid)
    def self.itemIncludingDeletedOrNull(objectuuid)
        item = {}
        db = SQLite3::Database.new(Fx18s::getExistingFx18FilepathForObjectuuid(objectuuid))
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

                # ---------------------------------------------------------
                # TODO: back to simplified version at some point
                attrvalue = 
                            begin
                                JSON.parse(row["_eventData3_"])
                            rescue 
                                puts "special circumstances, continue if _eventData3_ is non JSON encoded value"
                                puts JSON.pretty_generate(row)
                                LucilleCore::pressEnterToContinue()
                                db.execute "delete from _fx18_ where _eventuuid_=?", [row["_eventuuid_"]]
                                db.execute "insert into _fx18_ (_objectuuid_, _eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?, ?)", [row["_objectuuid_"], row["_eventuuid_"], row["_eventTime_"], "attribute", "attrname", JSON.generate(row["_eventData3_"]), nil, nil]
                                row["_eventData3_"]
                            end
                # ---------------------------------------------------------

                item[attrname] = attrvalue
            end
            if row["_eventData1_"] == "object-is-alive" then
                isAlive = (row["_eventData2_"] == "true")
                item["isAlive"] = isAlive
            end
            # ---------------------------------------------------------------------------
        end
        db.close
        item
    end

    # Fx18s::itemAliveOrNull(objectuuid)
    def self.itemAliveOrNull(objectuuid)
        item = Fx18s::itemIncludingDeletedOrNull(objectuuid)
        return nil if item.nil?
        return nil if (!item["isAlive"].nil? and !item["isAlive"]) # Object is logically deleted
        item
    end

    # Fx18s::broadcastObjectEvents(objectuuid)
    def self.broadcastObjectEvents(objectuuid)
        item = {}
        db = SQLite3::Database.new(Fx18s::getExistingFx18FilepathForObjectuuid(objectuuid))
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

    # Fx18s::localFx18sFilepathsEnumerator()
    def self.localFx18sFilepathsEnumerator()
        Enumerator.new do |filepaths|
            Find.find("#{Config::pathToLocalDataBankStargate()}/Fx18s") do |path|
                next if path[-8, 8] != ".sqlite3"
                filepaths << path
            end
        end
    end

    # Fx18s::stargateCentralFx18sFilepathsEnumerator()
    def self.stargateCentralFx18sFilepathsEnumerator()
        Enumerator.new do |filepaths|
            Find.find("#{StargateCentral::pathToCentral()}/Fx18s") do |path|
                next if path[-8, 8] != ".sqlite3"
                filepaths << path
            end
        end
    end

    # Fx18s::objectuuidsUsingLocalFx18FileEnumerationIncludeDeleted()
    def self.objectuuidsUsingLocalFx18FileEnumerationIncludeDeleted()
        Enumerator.new do |objectuuids|
            Fx18s::localFx18sFilepathsEnumerator().each{|filepath|
                objectuuid = Fx18Attributes::getJsonDecodeOrNullUsingFilepath(filepath, "uuid")
                if objectuuid.nil? then
                    puts "(error: 03a7834f-5882-4519-9a29-3a40092e6eae) I could not determine uuid for file: #{filepath}"
                    puts "Exit."
                    exit
                end
                objectuuids << objectuuid
            }
        end
    end
end

class Fx18Attributes

    # Fx18Attributes::set1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.set1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "Fx18Attributes::set1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        Fx18s::commit(objectuuid, eventuuid, eventTime, "attribute", attname, JSON.generate(attvalue), nil, nil)
    end

    # Fx18Attributes::setJsonEncodeObjectMaking(objectuuid, attname, attvalue)
    def self.setJsonEncodeObjectMaking(objectuuid, attname, attvalue)
        Fx18Attributes::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # Fx18Attributes::setJsonEncodeUpdate(objectuuid, attname, attvalue)
    def self.setJsonEncodeUpdate(objectuuid, attname, attvalue)
        Fx18Attributes::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
        SystemEvents::processEventInternally({
            "mikuType"   => "(object has been updated)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18Attributes::getJsonDecodeOrNull(objectuuid, attname)
    def self.getJsonDecodeOrNull(objectuuid, attname)
        db = SQLite3::Database.new(Fx18s::getExistingFx18FilepathForObjectuuid(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _objectuuid_=? and _eventData1_=? and _eventData2_=? order by _eventTime_", [objectuuid, "attribute", attname]) do |row|
            attvalue = JSON.parse(row["_eventData3_"])
        end
        db.close
        attvalue
    end

    # Fx18Attributes::getJsonDecodeOrNullUsingFilepath(filepath, attname)
    def self.getJsonDecodeOrNullUsingFilepath(filepath, attname)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _eventData1_=? and _eventData2_=? order by _eventTime_", ["attribute", attname]) do |row|
            attvalue = JSON.parse(row["_eventData3_"])
        end
        db.close
        attvalue
    end
end

class Fx18Sets

    # Fx18Sets::add1(objectuuid, eventuuid, eventTime, setuuid, itemuuid, value; going to be JSON serialised)
    def self.add1(objectuuid, eventuuid, eventTime, setuuid, itemuuid, value)
        puts "Fx18Sets::add1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{setuuid}, #{itemuuid}, #{value})"
        Fx18s::commit(objectuuid, eventuuid, eventTime, "setops", "add", setuuid, itemuuid, JSON.generate(value))
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
        Fx18s::commit(objectuuid, eventuuid, eventTime, "setops", "remove", setuuid, itemuuid, nil)
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
        db = SQLite3::Database.new(Fx18s::getExistingFx18FilepathForObjectuuid(objectuuid))
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

class Fx18sSynchronisation

    # Fx18sSynchronisation::getEventuuids(filepath)
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

    # Fx18sSynchronisation::getRecordOrNull(filepath, eventuuid)
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

    # Fx18sSynchronisation::putRecord(filepath, record)
    def self.putRecord(filepath, record)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [record["_eventuuid_"]]
        db.execute "insert into _fx18_ (_objectuuid_, _eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?, ?)", [record["_objectuuid_"], record["_eventuuid_"], record["_eventTime_"], record["_eventData1_"], record["_eventData2_"], record["_eventData3_"], record["_eventData4_"], record["_eventData5_"]]
        db.close
    end

    # Fx18sSynchronisation::propagateFileData(filepath1, filepath2)
    def self.propagateFileData(filepath1, filepath2)
        raise "(error: d5e6f2d3-9eab-484a-bde8-d7e6d479b04f)" if !File.exists?(filepath1)
        raise "(error: 5d24c60a-db47-4643-a618-bb2057daafd2)" if !File.exists?(filepath2)

        eventuuids1 = Fx18sSynchronisation::getEventuuids(filepath1)
        eventuuids2 = Fx18sSynchronisation::getEventuuids(filepath2)

        (eventuuids1 - eventuuids2).each{|eventuuid|

            record1 = Fx18sSynchronisation::getRecordOrNull(filepath1, eventuuid)
            if record1.nil? then
                puts "filepath1: #{filepath1}"
                puts "filepath2: #{filepath2}"
                puts "eventuuid: #{eventuuid}"
                raise "(error: e0f0d25c-48da-44b2-8304-832c3aa14421)"
            end

            puts "Fx18sSynchronisation::propagateFileData, filepath1: #{filepath1}, objectuuid: #{record1["_objectuuid_"]}, eventuuid: #{eventuuid}"

            Fx18sSynchronisation::putRecord(filepath2, record1)

            # clear that line in the Lookup, but without deleting it
            Lookup1::removeObjectuuid(record1["_objectuuid_"])

            if Fx18s::objectIsAlive(record1["_eventData1_"]) == "object-is-alive" and record1["_eventData2_"] == "false" then
                # If filepath1 is local then the item should have already been deleted from the Lookup
                # If filepath1 is remote then we are performing a true deletion.
                Lookup1::removeObjectuuid(record1["_objectuuid_"])
            end

            if Fx18s::objectIsAlive(record1["_eventData1_"]) == "object-is-alive" and record1["_eventData2_"] == "true" then
                # At the time those lines are written, we don't even have a way to resuscitate
                # an object, but if we do, it goes here
                Lookup1::reconstructEntry(record1["_objectuuid_"])
            end

            # Checks
            record2 = Fx18sSynchronisation::getRecordOrNull(filepath2, eventuuid)
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

    # Fx18sSynchronisation::sync()
    def self.sync()

        LucilleCore::locationsAtFolder("#{Config::pathToLocalDataBankStargate()}/Datablobs").each{|filepath|
            next if filepath[-5, 5] != ".data"
            puts "Fx18sSynchronisation::sync(): transferring blob: #{filepath}"
            blob = IO.read(filepath)
            ExData::putBlobOnInfinity(blob)
            FileUtils.rm(filepath)
        }

        DxPure::localFilepathsEnumerator().each{|dxLocalFilepath|
            sha1 = File.basename(dxLocalFilepath).gsub(".sqlite3", "")
            dxVaultFilepath = DxPure::sha1ToStargateInfinityFilepath(sha1)
            next if File.exists?(dxVaultFilepath)
            FileUtils.mv(dxLocalFilepath, dxVaultFilepath)
        }

        Fx18s::localFx18sFilepathsEnumerator().each{|filepath1|
            puts "filepath1: #{filepath1}"
            objectuuid = Fx18Attributes::getJsonDecodeOrNullUsingFilepath(filepath1, "uuid")
            if objectuuid.nil? then
                puts "I could not extract the uuid from Fx18 file #{filepath1}"
                raise "(error: 77a8fbbc-105f-4119-920b-3d73c66c6185)"
            end
            filepath2 = Fx18s::getExistingRemoteFx18FilepathForObjectuuid(objectuuid)
            Fx18sSynchronisation::propagateFileData(filepath1, filepath2)
            sleep 0.01
        }

        Fx18s::stargateCentralFx18sFilepathsEnumerator().each{|filepath1|
            puts "filepath1: #{filepath1}"
            objectuuid = Fx18Attributes::getJsonDecodeOrNullUsingFilepath(filepath1, "uuid")
            if objectuuid.nil? then
                puts "I could not extract the uuid from Fx18 file #{filepath1}"
                raise "(error: 85d69faf-0db7-4ee5-a463-eaa0ad90eb83)"
            end
            filepath2 = Fx18s::getExistingFx18FilepathForObjectuuid(objectuuid)
            Fx18sSynchronisation::propagateFileData(filepath1, filepath2)
            sleep 0.01
        }
    end
end
