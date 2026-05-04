
# encoding: UTF-8

class Items

    # CREATE TABLE items (uuid TEXT primary key, mikuType TEXT, item TEXT);

    # Items::database_filepath()
    def self.database_filepath()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/items/#{Config::instanceId()}/items.sqlite"
    end

    # Items::commitItemNoBroadcast(item)
    def self.commitItemNoBroadcast(item)
        db = SQLite3::Database.new(Items::database_filepath())
        db.busy_timeout = 117 # overriden by the next instruction
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("
            INSERT INTO items (uuid, mikuType, item) 
            VALUES (?, ?, ?) 
            ON CONFLICT(uuid) DO UPDATE SET 
            mikuType = excluded.mikuType, 
            item = excluded.item", [item["uuid"], item["mikuType"], JSON.generate(item)])
        db.close
    end

    # Items::commitItem(item)
    def self.commitItem(item)
        Items::commitItemNoBroadcast(item)
        Broadcasts::send({
            "type"  => "item",
            "item"  => item
        })
    end

    # Items::setAttribute(uuid, attribute_name, attribute_value) # -> updated Item
    def self.setAttribute(uuid, attribute_name, attribute_value)
        item = Index::getItemOrNull(uuid)
        return if item.nil?
        item[attribute_name] = attribute_value
        Items::commitItem(item)
        item
    end

    # Items::deleteItemNoBroadcast(uuid)
    def self.deleteItemNoBroadcast(uuid)
        db = SQLite3::Database.new(Items::database_filepath())
        db.busy_timeout = 117 # overriden by the next instruction
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from items where uuid = ?", [uuid])
        db.close
    end

    # Items::deleteItem(uuid)
    def self.deleteItem(uuid)
        Items::deleteItemNoBroadcast(uuid)
        Broadcasts::send({
            "type" => "delete",
            "uuid" => uuid
        })
    end
end
