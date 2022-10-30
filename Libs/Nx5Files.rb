# encoding: UTF-8

class Nx5Files

    # Nx5Files::issueNewAtFilepath(filepath)
    def self.issueNewAtFilepath(filepath)
        raise "(error: B11E6590-A1D3-4BF4-9A6E-6FBC4CD06A4A)" if File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _events_ (_eventuuid_ text, _eventTime_ float, _eventType_ text, _event_ text)"
        db.execute "create table _datablobs_ (_nhash_ text, _datablob_ blob)"
        db.close
    end

    # Nx5Files::emitEventToFile0(filepath, event)
    def self.emitEventToFile0(filepath, event)
        raise "(error: 613FDDA4-0F16-4122-8D64-4D3C11BF28E9) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        FileSystemCheck::fsck_Nx3(event, SecureRandom.hex, false)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _events_ (_eventuuid_, _eventTime_, _eventType_, _event_) values (?, ?, ?, ?)", [event["eventuuid"], event["eventTime"], event["eventType"], JSON.generate(event)]
        db.close
    end

    # Nx5Files::emitEventToFile1(filepath, eventType, payload)
    def self.emitEventToFile1(filepath, eventType, payload)
        raise "(error: 5A3EFB73-E303-49D8-9C56-980C84CFF59F) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        event = {
            "mikuType"  => "Nx3",
            "eventuuid" => SecureRandom.uuid,
            "eventTime" => Time.new.to_f,
            "eventType" => eventType,
            "payload"   => payload
        }
        Nx5Files::emitEventToFile0(filepath, event)
    end

    # Nx5Files::getLatestPayloadOfEventTypeOrNull(filepath, eventType)
    def self.getLatestPayloadOfEventTypeOrNull(filepath, eventType)
        raise "(error: 7722D133-DCF9-4D5E-9BD3-066DA01090F8) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        event = nil
        db.execute("select * from _events_ where _eventType_=? order by _eventTime_", [eventType]) do |row|
            event = row["_event_"]
        end
        db.close
        event ? JSON.parse(event)["payload"] : nil
    end

    # Nx5Files::getOrderedEventsForEventType(filepath, eventType)
    def self.getOrderedEventsForEventType(filepath, eventType)
        raise "(error: 5B7BE0F3-47E3-4C61-8138-443FF6EB8851) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        events = []
        db.execute("select * from _events_ where _eventType_=? order by _eventTime_", [eventType]) do |row|
            events << JSON.parse(row["_event_"])
        end
        db.close
        events
    end

    # Nx5Files::getOrderedPayloadsForEventType(filepath, eventType)
    def self.getOrderedPayloadsForEventType(filepath, eventType)
        raise "(error: D0D65C42-3A5E-4B84-B8AF-67455C3722EA) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        Nx5Files::getOrderedEventsForEventType(filepath, eventType)
            .map{|event| event["payload"] }
    end

    # Nx5Files::getOrderedEvents(filepath)
    def self.getOrderedEvents(filepath)
        raise "(error: 5B7BE0F3-47E3-4C61-8138-443FF6EB8851) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        events = []
        db.execute("select * from _events_ order by _eventTime_", []) do |row|
            events << JSON.parse(row["_event_"])
        end
        db.close
        events
    end

    # Nx5Files::readFileAsAttributesOfObject(filepath)
    def self.readFileAsAttributesOfObject(filepath)
        raise "(error: 35519C87-740E-4D59-8CF2-15E7434E8024) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        Nx5Files::getOrderedEvents(filepath).reduce({}){|item, event|
            item[event["eventType"]] = event["payload"]
            item
        }
    end
end
