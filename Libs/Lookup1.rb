
class Lookup1

    # Lookup1::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepath = XCache::filepath("#{Fx18::cachePrefix()}:4f8266b4-dc37-4699-a592-68eee4c3ac79")
        return filepath if File.exists?(filepath)

        puts "preparing lookup1 database: #{filepath}"
        lookup1 = SQLite3::Database.new(filepath)
        lookup1.busy_timeout = 117
        lookup1.busy_handler { |count| true }
        lookup1.results_as_hash = true
        lookup1.execute("create table _lookup1_ (_itemuuid_ text primary key, _unixtime_ float, _mikuType_ text, _item_ text, _description_ text)", [])
        
        fx18 = SQLite3::Database.new(Fx18::localBlockFilepath())
        fx18.busy_timeout = 117
        fx18.busy_handler { |count| true }
        fx18.results_as_hash = true
        fx18.execute("select * from _fx18_ order by _eventTime_", []) do |row|

            ensureLine = lambda{|lookup1, objectuuid|
                hasLine = false
                lookup1.execute("select * from _lookup1_ where _itemuuid_=?", [objectuuid]) do |row|
                    hasLine = true
                end
                if !hasLine then
                    lookup1.execute("insert into _lookup1_ (_itemuuid_) values (?)", [objectuuid])
                end
            }

            if row["_eventData1_"] == "attribute" and row["_eventData2_"] == "mikuType" then
                objectuuid = row["_objectuuid_"]
                puts "lookup1: set objectuuid: #{objectuuid}"
                ensureLine.call(lookup1, objectuuid)
                mikuType = row["_eventData3_"]
                puts "lookup1: set mikuType: #{mikuType}"
                lookup1.execute("update _lookup1_ set _mikuType_=? where _itemuuid_=?", [mikuType, objectuuid])
            end

            if row["_eventData1_"] == "attribute" and row["_eventData2_"] == "unixtime" then
                objectuuid = row["_objectuuid_"]
                puts "lookup1: set objectuuid: #{objectuuid}"
                ensureLine.call(lookup1, objectuuid)
                unixtime = row["_eventData3_"]
                puts "lookup1: set unixtime: #{unixtime}"
                lookup1.execute("update _lookup1_ set _unixtime_=? where _itemuuid_=?", [unixtime, objectuuid])
            end

            if row["_eventData1_"] == "attribute" and row["_eventData2_"] == "description" then
                objectuuid = row["_objectuuid_"]
                puts "lookup1: set objectuuid: #{objectuuid}"
                ensureLine.call(lookup1, objectuuid)
                description = row["_eventData3_"]
                puts "lookup1: set description: #{description}"
                lookup1.execute("update _lookup1_ set _description_=? where _itemuuid_=?", [description, objectuuid])
            end

        end
        fx18.close

        lookup1.close
        filepath
    end

    # Lookup1::commit(objectuuid, unixtime, mikuType, item, description)
    def self.commit(objectuuid, unixtime, mikuType, item, description)
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from _lookup1_ where _itemuuid_=?", [objectuuid])
        db.execute("insert into _lookup1_ (_itemuuid_, _unixtime_, _mikuType_, _item_, _description_) values (?, ?, ?, ?, ?)", [objectuuid, unixtime, mikuType, JSON.generate(item), description])
        db.close
    end

    # Lookup1::getElementsOrNull(objectuuid)
    def self.getElementsOrNull(objectuuid)
        unixtime = Fx18Attributes::getOrNull(objectuuid, "unixtime")
        return nil if unixtime.nil?
        mikuType = Fx18Attributes::getOrNull(objectuuid, "mikuType")
        return nil if mikuType.nil?
        item     = Fx18::itemOrNull(objectuuid)
        return nil if item.nil?
        description = LxFunction::function("generic-description", item)
        [objectuuid, unixtime, mikuType, item, description]
    end

    # Lookup1::processObjectuuid(objectuuid)
    def self.processObjectuuid(objectuuid)
        elements = Lookup1::getElementsOrNull(objectuuid)
        return if elements.nil?
        objectuuid, unixtime, mikuType, item, description = elements
        puts "update lookup1: objectuuid: #{objectuuid}"
        Lookup1::commit(objectuuid, unixtime, mikuType, item, description)
    end

    # Lookup1::removeObjectuuid(objectuuid)
    def self.removeObjectuuid(objectuuid)
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from _lookup1_ where _itemuuid_=?", [objectuuid])
        db.close
    end

    # Lookup1::addItemsAndDescriptionsToLookup(items)
    def self.addItemsAndDescriptionsToLookup(items)
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        items
            .each{|item|
                puts "updating item #{item["uuid"]} while Lookup1"
                db.execute("update _lookup1_ set _item_=? where _itemuuid_=?", [JSON.generate(item), item["uuid"]])
                description = LxFunction::function("generic-description", item)
                db.execute("update _lookup1_ set _description_=? where _itemuuid_=?", [description, item["uuid"]])
            }
        db.close
    end

    # Lookup1::itemsuuids()
    def self.itemsuuids()
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        itemuuids = []
        db.execute("select _itemuuid_ from _lookup1_", []) do |row|
            itemuuids << row["_itemuuid_"]
        end
        db.close
        itemuuids
    end

    # Lookup1::mikuTypeToItems(mikuType)
    def self.mikuTypeToItems(mikuType)
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        items = []
        updates = []
        db.execute("select * from _lookup1_ where _mikuType_=?", [mikuType]) do |row|
            if row["_item_"] then
                item = JSON.parse(row["_item_"])
            else
                item = Fx18::itemOrNull(row["_itemuuid_"])
                updates << item
            end
            items << item
        end
        db.close
        Lookup1::addItemsAndDescriptionsToLookup(updates.compact)
        items.compact
    end

    # Lookup1::mikuTypeToItems2(mikuType, count)
    def self.mikuTypeToItems2(mikuType, count)
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        items = []
        updates = []
        db.execute("select _item_ from _lookup1_ where _mikuType_=? order by _unixtime_ limit ?", [mikuType, count]) do |row|
            if row["_item_"] then
                item = JSON.parse(row["_item_"])
            else
                item = Fx18::itemOrNull(row["_itemuuid_"])
                updates << item
            end
            items << item
        end
        db.close
        Lookup1::addItemsAndDescriptionsToLookup(updates.compact)
        items.compact
    end

    # Lookup1::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        count = []
        db.execute("select count(*) as _count_ from _lookup1_ where _mikuType_=?", [mikuType]) do |row|
            count = row["_count_"]
        end
        db.close
        count
    end

    # Lookup1::nx20s()
    def self.nx20s()
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        nx20s = []
        updates = []
        db.execute("select _itemuuid_, _unixtime_, _description_ from _lookup1_ where _description_ is not null", []) do |row|
            nx20s << {
                "announce"   => row["_description_"],
                "unixtime"   => row["_unixtime_"],
                "objectuuid" => row["_itemuuid_"]
            }
        end
        db.close
        Lookup1::addItemsAndDescriptionsToLookup(updates)
        nx20s
    end

    # Lookup1::processEventInternally(event)
    def self.processEventInternally(event)
        if event["mikuType"] == "(object has been updated)" then
            objectuuid = event["objectuuid"]
            Lookup1::processObjectuuid(objectuuid)
        end

        if event["mikuType"] == "(object has been deleted)" then
            objectuuid = event["objectuuid"]
            db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("delete from _lookup1_ where _itemuuid_=?", [objectuuid])
            db.close
        end
    end

    # Lookup1::maintainLookup()
    def self.maintainLookup()
        counter = 0
        (Fx18::objectuuids() - Lookup1::itemsuuids())
            .each{|objectuuid|
                break if counter >= 500
                next if !Fx18::objectIsAlive(objectuuid)
                Lookup1::processObjectuuid(objectuuid)
                counter = counter + 1
            }
    end
end
