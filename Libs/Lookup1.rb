
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
        lookup1.close

        Fx18::playLogFromScratchForLiveItems().each{|item|
            objectuuid = item["objectuuid"]
            unixtime = item["unixtime"]
            mikuType = item["mikuType"]
            description = LxFunction::function("generic-description", item)
            Lookup1::commit(objectuuid, unixtime, mikuType, item, description)
        }

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

    # Lookup1::recoverAndInject(objectuuid)
    def self.recoverAndInject(objectuuid)
        unixtime = Fx18Attributes::getOrNull(objectuuid, "unixtime")
        return if unixtime.nil?
        mikuType = Fx18Attributes::getOrNull(objectuuid, "mikuType")
        return if mikuType.nil?
        item     = Fx18::itemOrNull(objectuuid)
        return if item.nil?
        description = LxFunction::function("generic-description", item)
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
        db.execute("select * from _lookup1_ where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items.compact
    end

    # Lookup1::mikuTypeToItems2(mikuType, count)
    def self.mikuTypeToItems2(mikuType, count)
        db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        items = []
        db.execute("select _item_ from _lookup1_ where _mikuType_=? order by _unixtime_ limit ?", [mikuType, count]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
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
        db.execute("select _itemuuid_, _unixtime_, _description_ from _lookup1_ where _description_ is not null", []) do |row|
            nx20s << {
                "announce"   => row["_description_"],
                "unixtime"   => row["_unixtime_"],
                "objectuuid" => row["_itemuuid_"]
            }
        end
        db.close
        nx20s
    end

    # Lookup1::processEventInternally(event)
    def self.processEventInternally(event)
        if event["mikuType"] == "(object has been updated)" then
            objectuuid = event["objectuuid"]
            Lookup1::recoverAndInject(objectuuid)
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
end
