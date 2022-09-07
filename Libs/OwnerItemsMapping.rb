
# encoding: UTF-8

class OwnerItemsMapping

    # OwnerItemsMapping::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/owner-items-mapping.sqlite3"
    end

    # OwnerItemsMapping::issueNoEvents(eventuuid, eventTime, owneruuid, itemuuid, ordinal)
    def self.issueNoEvents(eventuuid, eventTime, owneruuid, itemuuid, ordinal)
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerItemsMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _mapping_ where _eventuuid_=?", [eventuuid]
            db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _owneruuid_, _itemuuid_, _ordinal_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, owneruuid, itemuuid, ordinal]
            db.close
        }
    end

    # OwnerItemsMapping::issue(owneruuid, itemuuid, ordinal)
    def self.issue(owneruuid, itemuuid, ordinal)
        eventuuid = SecureRandom.uuid
        eventTime = Time.new.to_f
        OwnerItemsMapping::issueNoEvents(eventuuid, eventTime, owneruuid, itemuuid, ordinal)
        SystemEvents::broadcast({
          "mikuType"  => "OwnerItemsMapping",
          "eventuuid" => eventuuid,
          "eventTime" => eventTime,
          "owneruuid" => owneruuid,
          "itemuuid"  => itemuuid,
          "ordinal"   => ordinal
        })
    end

    # OwnerItemsMapping::detach(groupuuid, itemuuid)
    def self.detach(groupuuid, itemuuid)
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerItemsMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _itemuuid_, _groupuuid_, _status_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, itemuuid, groupuuid, "false"]
            db.close
        }
    end

    # OwnerItemsMapping::owneruuidToElementsuuids(groupuuid)
    def self.owneruuidToElementsuuids(groupuuid)
        answer = []
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerItemsMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _mapping_ where _groupuuid_=?", [groupuuid]) do |row|
                answer << row['_itemuuid_']
            end
            db.close
        }
        answer.uniq
    end

    # OwnerItemsMapping::isOwned(itemuuid)
    def self.isOwned(itemuuid)
        answer = false
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerItemsMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _mapping_ where _itemuuid_=?", [itemuuid]) do |row|
                answer = true # This implementation is fundamentally incorrect because to be correct we would need to take account of the _status_, but for the time being items won't be removed from groups
                # TODO: fix it
            end
            db.close
        }
        answer
    end

    # OwnerItemsMapping::elementuuidToOwnersuuids(itemuuid)
    def self.elementuuidToOwnersuuids(itemuuid)
        answer = []
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerItemsMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _mapping_ where _itemuuid_=?", [itemuuid]) do |row|
                answer << row['_groupuuid_']
            end
            db.close
        }
        answer.uniq
    end

    # OwnerItemsMapping::elementuuidToOwnersuuidsCached(elementuuid)
    def self.elementuuidToOwnersuuidsCached(elementuuid)
        key = "0512f14d-c322-4155-ba05-ea6f53943ec8:#{elementuuid}"
        linkeduuids = XCacheValuesWithExpiry::getOrNull(key)
        return linkeduuids if linkeduuids
        linkeduuids = OwnerItemsMapping::elementuuidToOwnersuuids(elementuuid)
        XCacheValuesWithExpiry::set(key, linkeduuids, 3600)
        linkeduuids
    end

    # OwnerItemsMapping::eventuuids()
    def self.eventuuids()
        answer = []
        $owner_items_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerItemsMapping::databaseFile())
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

    # OwnerItemsMapping::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "OwnerItemsMapping" then
            eventuuid = event["eventuuid"]
            owneruuid = event["owneruuid"]
            itemuuid  = event["itemuuid"]
            OwnerItemsMapping::issueNoEvents(eventuuid, owneruuid, itemuuid)
        end
    end
end
