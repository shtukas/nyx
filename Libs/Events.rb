
# encoding: UTF-8

class EventsLocalToCentralInbox

    # EventsLocalToCentralInbox::pathToDatabaseFile()
    def self.pathToDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/events-outgoing.sqlite3"
    end

    # EventsLocalToCentralInbox::publish(event)
    def self.publish(event)
        #puts "EventsLocalToCentralInbox::publish(#{JSON.pretty_generate(event)})"
        db = SQLite3::Database.new(EventsLocalToCentralInbox::pathToDatabaseFile())
        db.execute "insert into _events_ (_uuid_, _unixtime_, _event_) values (?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, JSON.generate(event)]
        db.close
    end

    # EventsLocalToCentralInbox::getRecords()
    def self.getRecords()
        db = SQLite3::Database.new(EventsLocalToCentralInbox::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _events_ order by _unixtime_=?") do |row|
            answer << row
        end
        db.close
        answer
    end

    # EventsLocalToCentralInbox::deleteRecord(uuid)
    def self.deleteRecord(uuid)
        #puts "EventsLocalToCentralInbox::deleteRecord(#{uuid})"
        db = SQLite3::Database.new(EventsLocalToCentralInbox::pathToDatabaseFile())
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.close
    end

    # EventsLocalToCentralInbox::localEventsToCentralInbox()
    def self.localEventsToCentralInbox()
        EventsLocalToCentralInbox::getRecords().each{|record|
            puts "EventsLocalToCentralInbox::localEventsToCentralInbox(): record (from local event repo to central inbox):"
            puts JSON.pretty_generate(record)
            StargateCentralInbox::writeEvent(record["_uuid_"], record["_unixtime_"], JSON.parse(record["_event_"]))
            EventsLocalToCentralInbox::deleteRecord(record["_uuid_"])
        }
    end
end

class EventsLocalToMachine
    # Here we store the events to send fast to the other machine

    # EventsLocalToMachine::publish(event)
    def self.publish(event)
        #puts "EventsLocalToMachine::publish(#{JSON.pretty_generate(event)})"
        Mercury::postValue("341307DD-A9C6-494F-B050-CD89745A66C6", event)
    end

    # EventsLocalToMachine::sendEventsToMachine()
    def self.sendEventsToMachine()
        loop {
            event = Mercury::readFirstValueOrNull("341307DD-A9C6-494F-B050-CD89745A66C6")
            break if event.nil?
            #puts "AWSSQS::sendToTheOtherMachine(#{JSON.pretty_generate(event)})"
            status = AWSSQS::sendToTheOtherMachine(event)
            #puts "status: #{status}"
            if status then
                Mercury::dequeueFirstValueOrNull("341307DD-A9C6-494F-B050-CD89745A66C6")
            else
                break # will try again later
            end
        }
    end
end

class EventMachineSync

    # EventMachineSync::machineSync()
    def self.machineSync()
        #puts "To Machine Event Maintenance Thread"
        begin
            EventsLocalToMachine::sendEventsToMachine()
            AWSSQS::pullAndProcessEvents()
        rescue StandardError => e
            puts "To Machine Event Maintenance Thread Error: #{e.message}"
        end
    end
end
