
# encoding: UTF-8

class ItemsDatabase

    # ItemsDatabase::all()
    def self.all()
        items = []
        db = SQLite3::Database.new(Config::pathToItemsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items", []) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # ItemsDatabase::allNetworkItems2()
    def self.allNetworkItems2()
        items = []
        db = SQLite3::Database.new(Config::pathToItemsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items", []) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # ItemsDatabase::mikuType2(mikuType)
    def self.mikuType2(mikuType)
        items = []
        db = SQLite3::Database.new(Config::pathToItemsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # ItemsDatabase::itemOrNull2(uuid)
    def self.itemOrNull2(uuid)
        item = nil
        db = SQLite3::Database.new(Config::pathToItemsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _uuid_=?", [uuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # ItemsDatabase::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        item = {
            "uuid"     => uuid,
            "mikuType" => mikuType
        }

        db = SQLite3::Database.new(Config::pathToItemsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close
    end

    # ItemsDatabase::itemAttributeUpdate(itemuuid, attname, attvalue)
    def self.itemAttributeUpdate(itemuuid, attname, attvalue)
        item = ItemsDatabase::itemOrNull2(itemuuid)
        if item.nil? then
            raise "(error 1219) ItemsDatabase::itemAttributeUpdate(#{itemuuid}, #{attname}, #{attvalue})"
        end
        item[attname] = attvalue
        db = SQLite3::Database.new(Config::pathToItemsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from Items where _uuid_=?", [itemuuid]
        db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close
    end

    # ItemsDatabase::itemDestroy(itemuuid)
    def self.itemDestroy(itemuuid)
        db = SQLite3::Database.new(Config::pathToItemsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from Items where _uuid_=?", [itemuuid]
        db.close
    end
end
