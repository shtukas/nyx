
# encoding: UTF-8

class ItemToGroupMapping

    # ItemToGroupMapping::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/item-to-group-mapping.sqlite3"
    end

    # ItemToGroupMapping::issue(groupuuid, itemuuid)
    def self.issue(groupuuid, itemuuid)
        db = SQLite3::Database.new(ItemToGroupMapping::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _itemuuid_, _groupuuid_, _status_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, itemuuid, groupuuid, "true"]
        db.close
    end

    # ItemToGroupMapping::detach(groupuuid, itemuuid)
    def self.detach(groupuuid, itemuuid)
        db = SQLite3::Database.new(ItemToGroupMapping::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _itemuuid_, _groupuuid_, _status_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, itemuuid, groupuuid, "false"]
        db.close
    end

    # ItemToGroupMapping::groupuuidToItemuuids(groupuuid)
    def self.groupuuidToItemuuids(groupuuid)
        db = SQLite3::Database.new(ItemToGroupMapping::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _mapping_ where _groupuuid_=?", [groupuuid]) do |row|
            answer << row['_itemuuid_']
        end
        answer
    end

    # ItemToGroupMapping::trueIfItemIsInAGroup(itemuuid)
    def self.trueIfItemIsInAGroup(itemuuid)
        db = SQLite3::Database.new(ItemToGroupMapping::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = false
        db.execute("select * from _mapping_ where _itemuuid_=?", [itemuuid]) do |row|
            answer = true # This implementation is fundamentally incorrect because to be correct we would need to take account of the _status_, but for the time being items won't be removed from groups
            # TODO: fix it
        end
        answer
    end

    # ItemToGroupMapping::itemuuidToGroupuuids(itemuuid)
    def self.itemuuidToGroupuuids(itemuuid)
        db = SQLite3::Database.new(ItemToGroupMapping::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _mapping_ where _itemuuid_=?", [itemuuid]) do |row|
            answer << row['_groupuuid_']
        end
        answer
    end
end
