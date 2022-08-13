class Fx18s

    # Fx18s::fx18Filepath()
    def self.fx18Filepath()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx18.sqlite3"
    end

    # Fx18s::commit(objectuuid, eventuuid, eventTime, eventData2, eventData3)
    def self.commit(objectuuid, eventuuid, eventTime, eventData2, eventData3)
        if objectuuid.nil? then
            raise "(error: a3202192-2d16-4f82-80e9-a86a18d407c8)"
        end
        if eventuuid.nil? then
            raise "(error: 1025633f-b0aa-42ed-9751-b5f87af23450)"
        end
        if eventTime.nil? then
            raise "(error: 9a6caf6b-fa31-4fda-b963-f0c04f4e50a2)"
        end
        if eventData2.nil? then
            raise "(error: 0b103332-556d-4043-9cdd-81cf70b7a289)"
        end
        if eventData3.nil? then
            raise "(error: db06a417-68d1-471d-888f-9e497b268750)"
        end
        db = SQLite3::Database.new(Fx18s::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_objectuuid_, _eventuuid_, _eventTime_, _eventData2_, _eventData3_) values (?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, eventData2, eventData3]
        db.close
    end

    # Fx18s::getItemOrNull(objectuuid)
    def self.getItemOrNull(objectuuid)
        item = {}
        db = SQLite3::Database.new(Fx18s::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select * from _fx18_ where _objectuuid_=? order by _eventTime_", [objectuuid]) do |row|
            attrname = row["_eventData2_"]
            attvalue = 
                begin
                    JSON.parse(row["_eventData3_"])
                rescue 
                    row["_eventData3_"] # We have some non json encoded legacy data at that attribute
                end
            item[attrname] = attvalue
        end
        db.close
        if item["uuid"].nil? then
            return nil
        end
        item
    end

    # Fx18s::objectIsAlive(objectuuid)
    def self.objectIsAlive(objectuuid)
        value = Fx18Attributes::getJsonDecodeOrNull(objectuuid, "isAlive")
        return true if value.nil?
        value
    end

    # Fx18s::getAliveItemOrNull(objectuuid)
    def self.getAliveItemOrNull(objectuuid)
        item = Fx18s::getItemOrNull(objectuuid)
        return nil if item.nil?
        return nil if (!item["isAlive"].nil? and !item["isAlive"]) # Object is logically deleted
        item
    end

    # Fx18s::deleteObjectLogicallyNoEvents(objectuuid)
    def self.deleteObjectLogicallyNoEvents(objectuuid)
        Fx18Attributes::setJsonEncodeUpdate(objectuuid, "isAlive", false)
    end

    # Fx18s::deleteObjectLogically(objectuuid)
    def self.deleteObjectLogically(objectuuid)
        Fx18s::deleteObjectLogicallyNoEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        SystemEvents::processEvent({
            "mikuType"   => "(object has been logically deleted)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18s::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "Fx18-records" then
            knowneventsuuids = Fx18s::eventuuids()
            event["records"].each{|row|
                next if knowneventsuuids.include?(row["_eventuuid_"])
                Fx18s::commit(row["_objectuuid_"], row["_eventuuid_"], row["_eventTime_"], row["_eventData2_"], row["_eventData3_"])
            }
            Stargate::resetCachePrefix()
        end
    end

    # Fx18s::objectrows(objectuuid)
    def self.objectrows(objectuuid)
        db = SQLite3::Database.new(Fx18s::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        rows = []
        db.execute("select * from _fx18_ where _objectuuid_=? order by _eventTime_", [objectuuid]) do |row|
            rows << row.clone
        end
        db.close
        rows
    end

    # Fx18s::broadcastObjectEvents(objectuuid)
    def self.broadcastObjectEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType" => "Fx18-records",
            "records"  => Fx18s::objectrows(objectuuid)
        })
    end

    # Fx18s::eventuuids()
    def self.eventuuids()
        db = SQLite3::Database.new(Fx18s::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        eventuuids = []
        db.execute("select _eventuuid_ from _fx18_ order by _eventTime_", []) do |row|
            eventuuids << row["_eventuuid_"]
        end
        db.close
        eventuuids
    end

    # Fx18s::objectuuids()
    def self.objectuuids()
        db = SQLite3::Database.new(Fx18s::fx18Filepath())
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

    # Fx18s::getAllRows()
    def self.getAllRows()
        db = SQLite3::Database.new(Fx18s::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        rows = []
        db.execute("select * from _fx18_ order by _eventTime_", []) do |row|
            rows << row.clone
        end
        db.close
        rows
    end
end

class Fx18Attributes

    # Fx18Attributes::set1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.set1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "Fx18Attributes::set1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        Fx18s::commit(objectuuid, eventuuid, eventTime, attname, JSON.generate(attvalue))
    end

    # Fx18Attributes::setJsonEncodeObjectMaking(objectuuid, attname, attvalue)
    def self.setJsonEncodeObjectMaking(objectuuid, attname, attvalue)
        Fx18Attributes::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # Fx18Attributes::setJsonEncodeUpdate(objectuuid, attname, attvalue)
    def self.setJsonEncodeUpdate(objectuuid, attname, attvalue)
        Fx18Attributes::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
        SystemEvents::processEvent({
            "mikuType"   => "(object has been updated)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx18Attributes::getJsonDecodeOrNull(objectuuid, attname)
    def self.getJsonDecodeOrNull(objectuuid, attname)
        db = SQLite3::Database.new(Fx18s::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _objectuuid_=? and _eventData2_=? order by _eventTime_", [objectuuid, attname]) do |row|
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
        db.execute("select * from _fx18_ where _eventData2_=? order by _eventTime_", [attname]) do |row|
            attvalue = JSON.parse(row["_eventData3_"])
        end
        db.close
        attvalue
    end
end

class Fx18sSynchronisation

    # Fx18sSynchronisation::sync()
    def self.sync()

        LucilleCore::locationsAtFolder("#{Config::pathToLocalDataBankStargate()}/Datablobs").each{|filepath|
            next if filepath[-5, 5] != ".data"
            puts "Fx18sSynchronisation::sync(): transferring blob: #{filepath}"
            blob = IO.read(filepath)
            ExData::putBlobOnEnergyGrid1(blob)
            FileUtils.rm(filepath)
        }

        DxPure::localFilepathsEnumerator().each{|dxLocalFilepath|
            sha1 = File.basename(dxLocalFilepath).gsub(".sqlite3", "")
            eGridFilepath = DxPure::sha1ToEnergyGrid1Filepath(sha1)
            next if File.exists?(eGridFilepath)
            FileUtils.cp(dxLocalFilepath, eGridFilepath)
        }
    end
end
