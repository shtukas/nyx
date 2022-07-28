
class Lookup1

    # Lookup1::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepath = XCache::filepath("#{Fx18::cachePrefix()}:4f8266b4-dc36-4699-a592-68eee2c3ac69")
        return filepath if File.exists?(filepath)

        puts "preparing lookup1 database: #{filepath}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _lookup1_ (_itemuuid_ text primary key, _unixtime_ float, _mikuType_ text, _item_ text, _announce_ text)", [])
        db.close

        Fx18::objectuuids().each{|objectuuid|
            puts "building lookup1: objectuuid: #{objectuuid}"

            unixtime = Fx18Attributes::getOrNull(objectuuid, "unixtime")
            raise "(error: a9e52d99-1bd5-4b65-9ee6-a3c1b2c9d0cb)" if unixtime.nil?

            mikuType = Fx18Attributes::getOrNull(objectuuid, "mikuType")
            raise "(error: cd46d88b-ddb7-412f-bbb5-acccf968ba3e)" if mikuType.nil?

            item     = Fx18::itemOrNull(objectuuid)
            raise "(error: d644d601-288e-426c-9467-3a364a32d06b)" if item.nil?

            announce = LxFunction::function("generic-description", item)

            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("insert into _lookup1_ (_itemuuid_, _unixtime_, _mikuType_, _item_, _announce_) values (?, ?, ?, ?, ?)", [objectuuid, unixtime, mikuType, JSON.generate(item), announce])
            db.close
        }
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
        db.execute("select _item_ from _lookup1_ where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
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
        items
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
        db.execute("select _itemuuid_, _unixtime_, _announce_ from _lookup1_", []) do |row|
            nx20s << {
                "announce"   => row["_announce_"],
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

            # (comment 1) This happens naturally if this was trigerred by a stargate sync and the object is only partially recorded in the local block

            unixtime = Fx18Attributes::getOrNull(objectuuid, "unixtime")
            return if unixtime.nil? # (comment 1)

            mikuType = Fx18Attributes::getOrNull(objectuuid, "mikuType")
            return if mikuType.nil? # (comment 1)

            item     = Fx18::itemOrNull(objectuuid)
            return if item.nil? # (comment 1)

            puts "update lookup1: objectuuid: #{objectuuid}"

            announce = LxFunction::function("generic-description", item)

            db = SQLite3::Database.new(Lookup1::getDatabaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("delete from _lookup1_ where _itemuuid_=?", [objectuuid])
            db.execute("insert into _lookup1_ (_itemuuid_, _unixtime_, _mikuType_, _item_, _announce_) values (?, ?, ?, ?, ?)", [objectuuid, unixtime, mikuType, JSON.generate(item), announce])
            db.close
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
