# encoding: UTF-8

class Nx5

    # Nx5::issueNewFileAtFilepath(filepath, uuid)
    def self.issueNewFileAtFilepath(filepath, uuid)
        raise "(error: B11E6590-A1D3-4BF4-9A6E-6FBC4CD06A4A)" if File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _events_ (_eventuuid_ text, _eventTime_ float, _eventType_ text, _event_ text)"
        db.execute "create table _datablobs_ (_nhash_ text, _datablob_ blob)"

        event = {
            "mikuType"  => "Nx3",
            "eventuuid" => SecureRandom.uuid,
            "eventTime" => Time.new.to_f,
            "eventType" => "uuid",
            "payload"   => uuid
        }
        db.execute "insert into _events_ (_eventuuid_, _eventTime_, _eventType_, _event_) values (?, ?, ?, ?)", [event["eventuuid"], event["eventTime"], event["eventType"], JSON.generate(event)]
        db.close
    end

    # EVENTS

    # Nx5::getLatestPayloadOfEventTypeOrNull(filepath, eventType)
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

    # Nx5::getOrderedEventsForEventType(filepath, eventType)
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

    # Nx5::getOrderedPayloadsForEventType(filepath, eventType)
    def self.getOrderedPayloadsForEventType(filepath, eventType)
        raise "(error: D0D65C42-3A5E-4B84-B8AF-67455C3722EA) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        Nx5::getOrderedEventsForEventType(filepath, eventType)
            .map{|event| event["payload"] }
    end

    # Nx5::getOrderedEvents(filepath)
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

    # Nx5::trueIfFileHasEvent(filepath, eventuuid)
    def self.trueIfFileHasEvent(filepath, eventuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        flag = false
        db.execute("select _eventuuid_ from _events_ where _eventuuid_=?", [eventuuid]) do |row|
            flag = true
        end
        db.close
        flag
    end

    # Nx5::emitEventToFile0(filepath, event)
    def self.emitEventToFile0(filepath, event)
        raise "(error: 613FDDA4-0F16-4122-8D64-4D3C11BF28E9) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        FileSystemCheck::fsck_Nx3(event, false)
        return if Nx5::trueIfFileHasEvent(filepath, event["eventuuid"])
        puts "event: #{event} (at: #{filepath})".green
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _events_ where _eventuuid_=?", [event["eventuuid"]]
        db.execute "insert into _events_ (_eventuuid_, _eventTime_, _eventType_, _event_) values (?, ?, ?, ?)", [event["eventuuid"], event["eventTime"], event["eventType"], JSON.generate(event)]
        db.close
    end

    # Nx5::emitEventToFile1(filepath, eventType, payload)
    def self.emitEventToFile1(filepath, eventType, payload)
        raise "(error: 5A3EFB73-E303-49D8-9C56-980C84CFF59F) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        event = {
            "mikuType"  => "Nx3",
            "eventuuid" => SecureRandom.uuid,
            "eventTime" => Time.new.to_f,
            "eventType" => eventType,
            "payload"   => payload
        }
        Nx5::emitEventToFile0(filepath, event)
    end

    # DATABLOBS

    # Nx5::getDataBlobsNhashes(filepath)
    def self.getDataBlobsNhashes(filepath)
        raise "(error: 37854fc9-28e3-4c73-a4c2-76faac4a5186) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        nhashes = []
        db.execute("select _nhash_ from _datablobs_", []) do |row|
            nhashes << row["_nhash_"]
        end
        db.close
        nhashes
    end

    # Nx5::getDatablobOrNull(filepath, nhash)
    def self.getDatablobOrNull(filepath, nhash)
        raise "(error: a27f23c4-31dd-478e-8236-a95a4fe37984) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _datablobs_ where _nhash_=?", [nhash]) do |row|
            blob = row["_datablob_"]
        end
        db.close
        blob
    end

    # Nx5::trueIfFileHasBlob(filepath, nhash)
    def self.trueIfFileHasBlob(filepath, nhash)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        flag = false
        db.execute("select _nhash_ from _datablobs_ where _nhash_=?", [nhash]) do |row|
            flag = true
        end
        db.close
        flag
    end

    # Nx5::putBlob(filepath, blob)
    def self.putBlob(filepath, blob)
        raise "(error: 4272141b-4bab-4a7b-ba0d-377291d27809) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        return nhash if Nx5::trueIfFileHasBlob(filepath, nhash)
        puts "datablob: #{nhash} (at: #{filepath})".green
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _datablobs_ where _nhash_=?", [nhash]
        db.execute "insert into _datablobs_ (_nhash_, _datablob_) values (?, ?)", [nhash, blob]
        db.close
        nhash
    end
end

class ElizabethNx5

    def initialize(filepath)
        @filepath = filepath
    end

    def putBlob(datablob)
        Nx5::putBlob(@filepath, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Nx5::getDatablobOrNull(@filepath, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 59674f1a-d746-4544-951e-f2b3fa73b121) could not find blob, nhash: #{nhash}"
        raise "(error: 133b9867-5d6d-429c-88c2-e1b87081489b, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: e3981133-9909-4765-9f6b-b76324af0ae8) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class Nx5Ext

    # Nx5Ext::setAttribute(filepath, attname, attvalue)
    def self.setAttribute(filepath, attname, attvalue)
        Nx5::emitEventToFile1(filepath, attname, attvalue)
    end

    # Nx5Ext::readFileAsAttributesOfObject(filepath)
    def self.readFileAsAttributesOfObject(filepath)
        raise "(error: 35519C87-740E-4D59-8CF2-15E7434E8024) file doesn't exist: '#{filepath}'" if !File.exists?(filepath)
        Nx5::getOrderedEvents(filepath).reduce({}){|item, event|
            item[event["eventType"]] = event["payload"]
            item
        }
    end

    # Nx5Ext::ensureSetAndIdenticalUUIDsOrError(file1, file2)
    def self.ensureSetAndIdenticalUUIDsOrError(file1, file2)
        payloads1 = Nx5::getOrderedPayloadsForEventType(file1, "uuid")
        if payloads1.empty? then
            raise "(error: 47021527-13f3-4d8a-95f7-e130760b9ed5) file: '#{file1.green}' doesn't have a uuid attribute"
        end
        uuid1 = payloads1.last

        payloads2 = Nx5::getOrderedPayloadsForEventType(file2, "uuid")
        if payloads2.empty? then
            raise "(error: 4b56c0f6-edd0-4c70-bc0b-8543f902d4b9) file: '#{file2.green}' doesn't have a uuid attribute"
        end
        uuid2 = payloads2.last

        if uuid1 != uuid2 then
            raise "attepting mirroring onto two files with distinct uuids; file1: #{file1}; uuid: #{uuid1}; file2: #{file2}; uuid: #{uuid2} "
        end
    end

    # Nx5Ext::contentsPropagation(sourcefilepath, targetfilepath)
    def self.contentsPropagation(sourcefilepath, targetfilepath)

        # We need to fail if either of the two files doesn't have a uuid or if they are not identical
        Nx5Ext::ensureSetAndIdenticalUUIDsOrError(sourcefilepath, targetfilepath)

        Nx5::getDataBlobsNhashes(sourcefilepath)
            .each{|nhash|
                blob = Nx5::getDatablobOrNull(sourcefilepath, nhash)
                if blob.nil? then
                    raise "(error: 0a10fcee-064e-46d8-ae07-a4ddc6160197) sourcefilepath: '#{sourcefilepath}', nhash: '#{nhash}'"
                end
                Nx5::putBlob(targetfilepath, blob)
            }

        Nx5::getOrderedEvents(sourcefilepath)
            .each{|event|
                Nx5::emitEventToFile0(targetfilepath, event)
            }
    end

    # Nx5Ext::contentsMirroring(file1, file2)
    def self.contentsMirroring(file1, file2)
        Nx5Ext::contentsPropagation(file1, file2)
        Nx5Ext::contentsPropagation(file2, file1)
    end
end
