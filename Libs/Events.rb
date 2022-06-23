
# encoding: UTF-8

class EventsToCentral

    # EventsToCentral::pathToDatabaseFile()
    def self.pathToDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/events-outgoing.sqlite3"
    end

    # EventsToCentral::publish(event)
    def self.publish(event)
        #puts "EventsToCentral::publish(#{JSON.pretty_generate(event)})"
        db = SQLite3::Database.new(EventsToCentral::pathToDatabaseFile())
        db.execute "insert into _events_ (_uuid_, _unixtime_, _event_) values (?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, JSON.generate(event)]
        db.close
    end

    # EventsToCentral::getRecords()
    def self.getRecords()
        db = SQLite3::Database.new(EventsToCentral::pathToDatabaseFile())
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

    # EventsToCentral::deleteRecord(uuid)
    def self.deleteRecord(uuid)
        #puts "EventsToCentral::deleteRecord(#{uuid})"
        db = SQLite3::Database.new(EventsToCentral::pathToDatabaseFile())
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.close
    end

    # EventsToCentral::sendLocalEventsToCentral()
    def self.sendLocalEventsToCentral()
        EventsToCentral::getRecords().each{|record|
            puts "EventsToCentral::sendLocalEventsToCentral(): record (from local event repo to central objects):"
            puts JSON.pretty_generate(record)
            StargateCentralObjects::commit(record["_event_"])
            EventsToCentral::deleteRecord(record["_uuid_"])
        }
    end
end

class EventsToAWSQueue
    # Here we store the events to send fast to the other machine

    # EventsToAWSQueue::publish(event)
    def self.publish(event)
        #puts "EventsToAWSQueue::publish(#{JSON.pretty_generate(event)})"
        Mercury::postValue("341307DD-A9C6-494F-B050-CD89745A66C6", event)
    end

    # EventsToAWSQueue::sendEventsToMachine()
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

class EventSync

    # EventSync::awsSync()
    def self.awsSync()
        #puts "To Machine Event Maintenance Thread"
        begin
            EventsToAWSQueue::sendEventsToMachine()
            AWSSQS::pullAndProcessEvents()
        rescue StandardError => e
            puts "To Machine Event Maintenance Thread Error: #{e.message}"
        end
    end

    # EventSync::infinitySync()
    def self.infinitySync()
        EventsToCentral::sendLocalEventsToCentral()
        StargateCentralObjects::objects().each{|object|
            if object["mikuType"] == "NxDeleted" then
                Librarian::destroyCliqueNoEvent(object["uuid"])
                next
            end
            next if Librarian::getObjectByVariantOrNull(object["variant"]) # we already have this variant
            Librarian::incomingEvent(object, "stargate central")
        }
    end
end
