
# encoding: UTF-8

class NetworkArrows

    # NetworkArrows::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/network-arrows.sqlite3"
    end

    # NetworkArrows::insertRow(row)
    def self.insertRow(row)
        $arrows_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkArrows::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _arrows_ where _eventuuid_=?", [row["_eventuuid_"]]
            db.execute "insert into _arrows_ (_eventuuid_, _eventTime_, _sourceuuid_, _operation_, _targetuuid_) values (?, ?, ?, ?, ?)", [row["_eventuuid_"], row["_eventTime_"], row["_sourceuuid_"], row["_operation_"], row["_targetuuid_"]]
            db.close
        }
    end

    # NetworkArrows::issueNoEvents(eventuuid, eventTime, sourceuuid, operation, targetuuid)
    def self.issueNoEvents(eventuuid, eventTime, sourceuuid, operation, targetuuid)
        raise "(error: b070549f-9df3-47a5-baeb-85e5ddbceeac)" if sourceuuid.nil?
        if !["link", "unlink"].include?(operation) then
            raise "(error: 1b50e252-6e6f-4336-a445-194a40bdb8ba) operation: #{operation}"
        end
        raise "(error: c14843be-9828-4702-8649-d3e35bb1da4d)" if targetuuid.nil?
        $arrows_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkArrows::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _arrows_ where _eventuuid_=?", [eventuuid]
            db.execute "insert into _arrows_ (_eventuuid_, _eventTime_, _sourceuuid_, _operation_, _targetuuid_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, sourceuuid, operation, targetuuid]
            db.close
        }
    end

    # NetworkArrows::issue(sourceuuid, operation, targetuuid)
    def self.issue(sourceuuid, operation, targetuuid)
        if !["link", "unlink"].include?(operation) then
            raise "(error: 2324efe0-d9e1-419e-8cd9-2dfb5449f8a8) operation: #{operation}"
        end
        eventuuid = SecureRandom.uuid
        eventTime = Time.new.to_f
        NetworkArrows::issueNoEvents(eventuuid, eventTime, sourceuuid, operation, targetuuid)
        SystemEvents::broadcast({
          "mikuType"   => "NetworkArrows",
          "eventuuid"  => eventuuid,
          "eventTime"  => eventTime,
          "sourceuuid" => sourceuuid,
          "operation"  => operation,
          "targetuuid" => targetuuid
        })
    end

    # NetworkArrows::link(uuid1, uuid2)
    def self.link(uuid1, uuid2)
        NetworkArrows::issue(uuid1, "link", uuid2)
    end

    # NetworkArrows::unlink(uuid1, uuid2)
    def self.unlink(uuid1, uuid2)
        NetworkArrows::issue(uuid1, "unlink", uuid2)
    end

    # NetworkArrows::childrenuuids(itemuuid)
    def self.childrenuuids(itemuuid)
        childrenuuids = []
        $arrows_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkArrows::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _arrows_ where _sourceuuid_=? order by _eventTime_", [itemuuid]) do |row|
                if row["_operation_"] == "link" then
                    childrenuuids = (childrenuuids + [row["_targetuuid_"]]).uniq
                end
                if row["_operation_"] == "unlink" then
                    childrenuuids = childrenuuids - [row["_targetuuid_"]]
                end
            end
            db.close
        }
        childrenuuids.compact
    end

    # NetworkArrows::parentsuuids(itemuuid)
    def self.parentsuuids(itemuuid)
        parentsuuids = []
        $arrows_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkArrows::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _arrows_ where _targetuuid_=? order by _eventTime_", [itemuuid]) do |row|
                if row["_operation_"] == "link" then
                    parentsuuids = (parentsuuids + [row["_sourceuuid_"]]).uniq
                end
                if row["_operation_"] == "unlink" then
                    parentsuuids = parentsuuids - [row["_sourceuuid_"]]
                end
            end
            db.close
        }
        parentsuuids.compact
    end

    # NetworkArrows::eventuuids()
    def self.eventuuids()
        answer = []
        $arrows_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkArrows::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select _eventuuid_ from _arrows_", []) do |row|
                answer << row["_eventuuid_"]
            end
            db.close
        }
        answer
    end

    # NetworkArrows::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "NetworkArrows" then
            eventuuid  = event["eventuuid"]
            eventTime  = event["eventTime"] || Time.new.to_f # backward compatibility
            sourceuuid = event["sourceuuid"]
            operation  = event["operation"]
            targetuuid = event["targetuuid"]
            NetworkArrows::issueNoEvents(eventuuid, eventTime, sourceuuid, operation, targetuuid)
        end
    end

    # NetworkArrows::children(uuid)
    def self.children(uuid)
        NetworkArrows::childrenuuids(uuid)
            .map{|objectuuid| Items::getItemOrNull(objectuuid) }
            .compact
    end

    # NetworkArrows::parents(uuid)
    def self.parents(uuid)
        NetworkArrows::parentsuuids(uuid)
            .map{|objectuuid| Items::getItemOrNull(objectuuid) }
            .compact
    end
end
