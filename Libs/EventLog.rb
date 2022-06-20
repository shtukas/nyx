
# encoding: UTF-8

class LocalEventLogBufferOut

    # LocalEventLogBufferOut::pathToDatabaseFile()
    def self.pathToDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/events.sqlite3"
    end

    # LocalEventLogBufferOut::issueEventForObject(item)
    def self.issueEventForObject(item)
        event = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxEvent",
            "unixtime" => item["lxEventTime"],
            "payload"  => item
        }

        db = SQLite3::Database.new(LocalEventLogBufferOut::pathToDatabaseFile())
        db.execute "delete from _events_ where _uuid_=?", [event["uuid"]]
        db.execute "insert into _events_ (_uuid_, _unixtime_, _event_) values (?, ?, ?)", [event["uuid"], event["unixtime"], JSON.generate(event)]
        db.close

        AWSSQS::sendEventToTheOtherMachine(event)
    end

    # LocalEventLogBufferOut::getEvents()
    def self.getEvents()
        db = SQLite3::Database.new(LocalEventLogBufferOut::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _events_ order by _unixtime_=?") do |row|
            answer << JSON.parse(row['_event_'])
        end
        db.close
        answer
    end

    # LocalEventLogBufferOut::deleteEvent(uuid)
    def self.deleteEvent(uuid)
        db = SQLite3::Database.new(LocalEventLogBufferOut::pathToDatabaseFile())
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.close
    end

    # LocalEventLogBufferOut::sendEventsToStargateCentral()
    def self.sendEventsToStargateCentral()
        LocalEventLogBufferOut::getEvents().each{|event|
            puts JSON.pretty_generate(event)
            StargateCentral::writeEventToStream(event)
            LocalEventLogBufferOut::deleteEvent(event["uuid"])
        }
    end
end
