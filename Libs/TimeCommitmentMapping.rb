
# encoding: UTF-8

class TimeCommitmentMapping

    # TimeCommitmentMapping::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/owner-items-mapping.sqlite3"
    end

    # TimeCommitmentMapping::linkNoEvents(eventuuid, eventTime, owneruuid, itemuuid, operationType, ordinal)
    def self.linkNoEvents(eventuuid, eventTime, owneruuid, itemuuid, operationType, ordinal)
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(TimeCommitmentMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _mapping_ where _eventuuid_=?", [eventuuid]
            db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _owneruuid_, _itemuuid_, _operationType_, _ordinal_) values (?, ?, ?, ?, ?, ?)", [eventuuid, eventTime, owneruuid, itemuuid, operationType, ordinal]
            db.close
        }
    end

    # TimeCommitmentMapping::link(owneruuid, itemuuid, ordinal)
    def self.link(owneruuid, itemuuid, ordinal)
        eventuuid = SecureRandom.uuid
        eventTime = Time.new.to_f
        TimeCommitmentMapping::linkNoEvents(eventuuid, eventTime, owneruuid, itemuuid, "set", ordinal)
        SystemEvents::broadcast({
          "mikuType"      => "TimeCommitmentMapping",
          "eventuuid"     => eventuuid,
          "eventTime"     => eventTime,
          "owneruuid"     => owneruuid,
          "itemuuid"      => itemuuid,
          "operationType" => "set",
          "ordinal"       => ordinal
        })
    end

    # TimeCommitmentMapping::unlink(owneruuid, itemuuid)
    def self.unlink(owneruuid, itemuuid)
        eventuuid = SecureRandom.uuid
        eventTime = Time.new.to_f
        TimeCommitmentMapping::linkNoEvents(eventuuid, eventTime, owneruuid, itemuuid, "unset", nil)
        SystemEvents::broadcast({
          "mikuType"      => "TimeCommitmentMapping",
          "eventuuid"     => eventuuid,
          "eventTime"     => eventTime,
          "owneruuid"     => owneruuid,
          "itemuuid"      => itemuuid,
          "operationType" => "unset",
          "ordinal"       => nil
        })
    end

    # TimeCommitmentMapping::owneruuidToNx78(owneruuid): Map[itemuuid, ordinal]
    def self.owneruuidToNx78(owneruuid)
        struct1 = {}
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(TimeCommitmentMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _mapping_ where _owneruuid_=?", [owneruuid]) do |row|
                if row["_operationType_"] == "set" then
                    itemuuid = row['_itemuuid_']
                    ordinal  = row['_ordinal_']
                    struct1[itemuuid] = ordinal
                end
                if row["_operationType_"] == "unset" then
                    itemuuid = row['_itemuuid_']
                    struct1.delete(itemuuid)
                end
            end
            db.close
        }
        struct1
    end

    # TimeCommitmentMapping::isOwned(itemuuid)
    def self.isOwned(itemuuid)
        answer = false
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(TimeCommitmentMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _mapping_ where _itemuuid_=?", [itemuuid]) do |row|
                # This implementation is fundamentally incorrect because we should take account of unset operations
                # TODO: fix it
                answer = true
            end
            db.close
        }
        answer
    end

    # TimeCommitmentMapping::elementuuidToOwnersuuids(itemuuid)
    def self.elementuuidToOwnersuuids(itemuuid)
        answer = []
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(TimeCommitmentMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _mapping_ where _itemuuid_=?", [itemuuid]) do |row|
                answer << row['_owneruuid_']
            end
            db.close
        }
        answer.uniq
    end

    # TimeCommitmentMapping::elementuuidToOwnersuuidsCached(elementuuid)
    def self.elementuuidToOwnersuuidsCached(elementuuid)
        key = "0512f14d-c322-4155-ba05-ea6f53943ec8:#{elementuuid}"
        linkeduuids = XCacheValuesWithExpiry::getOrNull(key)
        return linkeduuids if linkeduuids
        linkeduuids = TimeCommitmentMapping::elementuuidToOwnersuuids(elementuuid)
        XCacheValuesWithExpiry::set(key, linkeduuids, 3600)
        linkeduuids
    end

    # TimeCommitmentMapping::eventuuids()
    def self.eventuuids()
        answer = []
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(TimeCommitmentMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select _eventuuid_ from _mapping_", []) do |row|
                answer << row['_eventuuid_']
            end
            db.close
        }
        answer
    end

    # TimeCommitmentMapping::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "TimeCommitmentMapping" then
            eventuuid = event["eventuuid"]
            eventTime = event["eventTime"]
            owneruuid = event["owneruuid"]
            itemuuid  = event["itemuuid"]
            operationType = event["operationType"]
            ordinal   = event["ordinal"]
            TimeCommitmentMapping::linkNoEvents(eventuuid, eventTime, owneruuid, itemuuid, operationType, ordinal)
        end
    end
end
