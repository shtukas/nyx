
# encoding: UTF-8

class OwnerMapping

    # OwnerMapping::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/item-to-group-mapping.sqlite3"
    end

    # OwnerMapping::insertRow(row)
    def self.insertRow(row)
        $item_to_group_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _mapping_ where _eventuuid_=?", [row["_eventuuid_"]]
            db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _itemuuid_, _groupuuid_, _status_) values (?, ?, ?, ?, ?)", [row["_eventuuid_"], row["_eventTime_"], row["_itemuuid_"], row["_groupuuid_"], row["_status_"]]
            db.close
        }
        SystemEvents::processAndBroadcast({
            "mikuType" => "(owner-elements-mapping-update)",
            "objectuuids"  => [row["_itemuuid_"], row["_groupuuid_"]],
        })
    end

    # OwnerMapping::issueNoEvents(eventuuid, groupuuid, itemuuid)
    def self.issueNoEvents(eventuuid, groupuuid, itemuuid)
        $item_to_group_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _mapping_ where _eventuuid_=?", [eventuuid]
            db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _itemuuid_, _groupuuid_, _status_) values (?, ?, ?, ?, ?)", [eventuuid, Time.new.to_f, itemuuid, groupuuid, "true"]
            db.close
        }
    end

    # OwnerMapping::issue(owneruuid, itemuuid)
    def self.issue(owneruuid, itemuuid)
        OwnerMapping::issueNoEvents(SecureRandom.uuid, owneruuid, itemuuid)
        SystemEvents::broadcast({
          "mikuType"  => "OwnerMapping",
          "owneruuid" => owneruuid,
          "itemuuid"  => itemuuid
        })
        SystemEvents::processAndBroadcast({
            "mikuType" => "(owner-elements-mapping-update)",
            "objectuuids"  => [owneruuid, itemuuid],
        })
    end

    # OwnerMapping::detach(groupuuid, itemuuid)
    def self.detach(groupuuid, itemuuid)
        $item_to_group_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _itemuuid_, _groupuuid_, _status_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, itemuuid, groupuuid, "false"]
            db.close
        }
    end

    # OwnerMapping::owneruuidToElementsuuids(groupuuid)
    def self.owneruuidToElementsuuids(groupuuid)
        answer = []
        $item_to_group_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerMapping::databaseFile())
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

    # OwnerMapping::isOwned(itemuuid)
    def self.isOwned(itemuuid)
        answer = false
        $item_to_group_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerMapping::databaseFile())
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

    # OwnerMapping::elementuuidToOwnersuuids(itemuuid)
    def self.elementuuidToOwnersuuids(itemuuid)
        answer = []
        $item_to_group_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerMapping::databaseFile())
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

    # OwnerMapping::elementuuidToOwnersuuidsCached(elementuuid)
    def self.elementuuidToOwnersuuidsCached(elementuuid)
        key = "0512f14d-c322-4155-ba05-ea6f53943ec8:#{elementuuid}"
        linkeduuids = XCacheValuesWithExpiry::getOrNull(key)
        return linkeduuids if linkeduuids
        linkeduuids = OwnerMapping::elementuuidToOwnersuuids(elementuuid)
        XCacheValuesWithExpiry::set(key, linkeduuids, 3600)
        linkeduuids
    end

    # OwnerMapping::eventuuids()
    def self.eventuuids()
        answer = []
        $item_to_group_mapping_database_semaphore.synchronize {
            db = SQLite3::Database.new(OwnerMapping::databaseFile())
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

    # OwnerMapping::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "OwnerMapping" then
            eventuuid = event["eventuuid"]
            owneruuid = event["owneruuid"]
            itemuuid  = event["itemuuid"]
            OwnerMapping::issueNoEvents(eventuuid, owneruuid, itemuuid)
        end
        if event["mikuType"] == "(owner-elements-mapping-update)" then
            event["objectuuids"].each{|objectuuid|
                XCache::destroy("0512f14d-c322-4155-ba05-ea6f53943ec8:#{objectuuid}") # Decache OwnerMapping::elementuuidToOwnersuuidsCached
            }
        end
    end
end
