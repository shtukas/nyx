
class ItemsEventsLog

    # ItemsEventsLog::pathToDatabase()
    def self.pathToDatabase()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/items-events-log.sqlite3"
    end

    # ItemsEventsLog::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
        if objectuuid.nil? then
            raise "(error: a3202192-2d16-4f82-80e9-a86a18d407c8)"
        end
        if eventuuid.nil? then
            raise "(error: 1025633f-b0aa-42ed-9751-b5f87af23450)"
        end
        if eventTime.nil? then
            raise "(error: 9a6caf6b-fa31-4fda-b963-f0c04f4e50a2)"
        end
        if attname.nil? then
            raise "(error: 0b103332-556d-4043-9cdd-81cf70b7a289)"
        end
        db = SQLite3::Database.new(ItemsEventsLog::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _events_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _events_ (_objectuuid_, _eventuuid_, _eventTime_, _attname_, _attvalue_) values (?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, attname, JSON.generate(attvalue)]
        db.close
    end

    # ItemsEventsLog::setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
        ItemsEventsLog::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)

        SystemEvents::broadcast({
            "mikuType"   => "AttributeUpdate.v2",
            "objectuuid" => objectuuid,
            "eventuuid"  => eventuuid,
            "eventTime"  => eventTime,
            "attname"    => attname,
            "attvalue"   => attvalue
        })

        Items::updateIndexAtObjectAttempt(objectuuid)
    end

    # ItemsEventsLog::setAttribute1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "ItemsEventsLog::setAttribute1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        ItemsEventsLog::setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
    end

    # ItemsEventsLog::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        ItemsEventsLog::setAttribute1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # ItemsEventsLog::getAttributeOrNull(objectuuid, attname)
    def self.getAttributeOrNull(objectuuid, attname)
        db = SQLite3::Database.new(ItemsEventsLog::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of the upmost importance that we order by _eventTime_ to get the latest/current value
        db.execute("select * from _events_ where _objectuuid_=? and _attname_=? order by _eventTime_", [objectuuid, attname]) do |row|
            attvalue = JSON.parse(row["_attvalue_"])
        end
        db.close
        attvalue
    end

    # ItemsEventsLog::getProtoItemOrNull(objectuuid)
    def self.getProtoItemOrNull(objectuuid)
        item = {}

        db = SQLite3::Database.new(ItemsEventsLog::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _events_ where _objectuuid_=? order by _eventTime_", [objectuuid]) do |row|
            attname  = row["_attname_"]
            attvalue = JSON.parse(row["_attvalue_"])
            item[attname] = attvalue
        end
        db.close
        
        if item["uuid"].nil? then
            item = nil
        end

        item
    end

    # ItemsEventsLog::deleteObjectNoEvents(objectuuid)
    def self.deleteObjectNoEvents(objectuuid)
        db = SQLite3::Database.new(ItemsEventsLog::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from _events_ where _objectuuid_=?", [objectuuid])
        db.close
    end

    # ItemsEventsLog::eventExistsAtItemsEventsLog(eventuuid)
    def self.eventExistsAtItemsEventsLog(eventuuid)
        answer = false
        db = SQLite3::Database.new(ItemsEventsLog::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _eventuuid_ from _events_ where _eventuuid_=?", [eventuuid]) do |row|
            answer = true
        end
        db.close
        answer
    end

    # ItemsEventsLog::objectuuids()
    def self.objectuuids()
        objectuuids = []
        db = SQLite3::Database.new(ItemsEventsLog::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select distinct _objectuuid_ from _events_", []) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # ItemsEventsLog::allObjectsFromEventLog()
    def self.allObjectsFromEventLog()
        themap = {}
        db = SQLite3::Database.new(ItemsEventsLog::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _events_ order by _eventTime_", []) do |row|
            objectuuid    = row["_objectuuid_"]
            if themap[objectuuid].nil? then
                themap[objectuuid] = {}
            end
            attname  = row["_attname_"]
            attvalue = JSON.parse(row["_attvalue_"])
            themap[objectuuid][attname] = attvalue
        end
        db.close
        themap
            .values
            .select{|item| item["uuid"] }
    end
end
