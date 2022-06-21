
# encoding: UTF-8

class OutGoingEventsToCentral

    # OutGoingEventsToCentral::pathToDatabaseFile()
    def self.pathToDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/events.sqlite3"
    end

    # OutGoingEventsToCentral::publish(event)
    def self.publish(event)
        #puts "OutGoingEventsToCentral::publish(#{JSON.pretty_generate(event)})"
        db = SQLite3::Database.new(OutGoingEventsToCentral::pathToDatabaseFile())
        db.execute "insert into _events_ (_uuid_, _unixtime_, _event_) values (?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, JSON.generate(event)]
        db.close
    end

    # OutGoingEventsToCentral::getRecords()
    def self.getRecords()
        db = SQLite3::Database.new(OutGoingEventsToCentral::pathToDatabaseFile())
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

    # OutGoingEventsToCentral::deleteRecord(uuid)
    def self.deleteRecord(uuid)
        #puts "OutGoingEventsToCentral::deleteRecord(#{uuid})"
        db = SQLite3::Database.new(OutGoingEventsToCentral::pathToDatabaseFile())
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.close
    end

    # OutGoingEventsToCentral::sendEventsToStargateCentral()
    def self.sendEventsToStargateCentral()
        OutGoingEventsToCentral::getRecords().each{|record|
            #puts "record (outgoing to central):"
            puts JSON.pretty_generate(record)
            StargateCentral::writeEventToStream(record["_uuid_"], record["_unixtime_"], JSON.parse(record["_event_"]))
            OutGoingEventsToCentral::deleteRecord(record["_uuid_"])
        }
    end
end

class OutGoingEventsToMachine
    # Here we store the events to send fast to the other machine

    # OutGoingEventsToMachine::publish(event)
    def self.publish(event)
        #puts "OutGoingEventsToMachine::publish(#{JSON.pretty_generate(event)})"
        Mercury::postValue("341307DD-A9C6-494F-B050-CD89745A66C6", event)
    end

    # OutGoingEventsToMachine::sendEventsToMachine()
    def self.sendEventsToMachine()
        loop {
            event = Mercury::readFirstValueOrNull("341307DD-A9C6-494F-B050-CD89745A66C6")
            break if event.nil?
            status = AWSSQS::sendToTheOtherMachine(event)
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
            OutGoingEventsToMachine::sendEventsToMachine()
            AWSSQS::pullAndProcessEvents()
        rescue StandardError => e
            puts "To Machine Event Maintenance Thread Error: #{e.message}"
        end
    end
end

class IncomingEventsFromCentral

    # IncomingEventsFromCentral::processEventsFromCentral()
    def self.processEventsFromCentral()
        StargateCentral::getRecords().each{|record|
            #puts "record (incoming from central): "
            #puts JSON.pretty_generate(record)
            event = JSON.parse(record["_event_"])
            Librarian::incomingEventFromOutside(event)
        }
    end
end
