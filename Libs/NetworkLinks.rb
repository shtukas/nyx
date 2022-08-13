
# encoding: UTF-8

class NetworkLinks

    # NetworkLinks::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/network-links.sqlite3"
    end

    # NetworkLinks::insertRow(row)
    def self.insertRow(row)
        db = SQLite3::Database.new(NetworkLinks::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _eventuuid_=?", [row["_eventuuid_"]]
        db.execute "insert into _links_ (_eventuuid_, _eventTime_, _sourceuuid_, _operation_, _targetuuid_) values (?, ?, ?, ?, ?)", [row["_eventuuid_"], row["_eventTime_"], row["_sourceuuid_"], row["_operation_"], row["_targetuuid_"]]
        db.close
    end

    # NetworkLinks::issueNoEvents(sourceuuid, operation, targetuuid)
    def self.issueNoEvents(sourceuuid, operation, targetuuid)
        if !["link", "unlink"].include?(operation) then
            raise "(error: 535c3cf7-f93b-43b2-8530-eb892910ceda) operation: #{operation}"
        end
        db = SQLite3::Database.new(NetworkLinks::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _links_ (_eventuuid_, _eventTime_, _sourceuuid_, _operation_, _targetuuid_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, sourceuuid, operation, targetuuid]
        db.close
    end

    # NetworkLinks::issue(sourceuuid, operation, targetuuid)
    def self.issue(sourceuuid, operation, targetuuid)
        if !["link", "unlink"].include?(operation) then
            raise "(error: cf4cb260-1709-474d-a4f9-3f99f95fdb52) operation: #{operation}"
        end
        NetworkLinks::issueNoEvents(sourceuuid, operation, targetuuid)
        SystemEvents::broadcast({
          "mikuType"  => "NetworkLinks",
          "sourceuuid" => sourceuuid,
          "operation"  => operation,
          "targetuuid" => targetuuid
        })
    end

    # NetworkLinks::linkeduuids(itemuuid)
    def self.linkeduuids(itemuuid)
        db = SQLite3::Database.new(NetworkLinks::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        linkeduuids = []
        db.execute("select * from _links_ where _sourceuuid_=? order by _eventTime_", [sourceuuid]) do |row|
            if row["_operation_"] == "link" then
                linkeduuids = (linkeduuids + [row["targetuuid"]]).uniq
            end
            if row["_operation_"] == "unlink" then
                linkeduuids = linkeduuids - [row["targetuuid"]]
            end
        end
        linkeduuids
    end

    # NetworkLinks::eventuuids()
    def self.eventuuids()
        db = SQLite3::Database.new(NetworkLinks::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select _eventuuid_ from _links_", []) do |row|
            answer << row["_eventuuid_"]
        end
        answer
    end

    # NetworkLinks::records()
    def self.records()
        db = SQLite3::Database.new(NetworkLinks::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _links_", []) do |row|
            answer << row.clone
        end
        answer
    end

    # NetworkLinks::processEventInternally(event)
    def self.processEventInternally(event)
        if event["mikuType"] == "NetworkLinks-records" then
            eventuuids = NetworkLinks::eventuuids()
            event["records"].each{|row|
                next if eventuuids.include?(row["_eventuuid_"])
                NetworkLinks::insertRow(row)
            }
        end
    end
end
