# encoding: UTF-8

class Items

    # create table _items_ (_uuid_ text, _mikuType_ text, _announce_ text, _item_ text)

    # Items::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Instance-Databases/#{Config::get("instanceId")}/items.sqlite3"
    end

    # Items::putItemNoEvent(item, fsckVerbose)
    def self.putItemNoEvent(item, fsckVerbose)
        FileSystemCheck::fsck_MikuTypedItem(item, FileSystemCheck::getExistingRunHash(), fsckVerbose)
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _items_ where _uuid_=?", [item["uuid"]]
        db.execute "insert into _items_ (_uuid_, _mikuType_, _announce_, _item_) values (?, ?, ?, ?)", [item["uuid"], item["mikuType"], PolyFunctions::genericDescriptionOrNull(item), JSON.generate(item)]
        db.close
    end

    # Items::putItem(item)
    def self.putItem(item)
        FileSystemCheck::fsck_MikuTypedItem(item, FileSystemCheck::getExistingRunHash(), true)
        Items::putItemNoEvent(item, true)
        SystemEvents::broadcast({
            "mikuType" => "TxEventItem1",
            "item"     => item
        })
    end

    # -----------------------------------------------------------------
    # READ

    # Items::objectuuids() # Array[objectuuid]
    def self.objectuuids()
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select _uuid_ from _items_", []) do |row|
            objectuuids << row["_uuid_"]
        end
        db.close
        objectuuids
    end

    # Items::getItemOrNull(objectuuid)
    def self.getItemOrNull(objectuuid)
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        item = nil
        db.execute("select * from _items_ where _uuid_=?", [objectuuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # Items::items() # Array[Item]
    def self.items()
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        items = []
        db.execute("select * from _items_", []) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # Items::mikuTypeToItems(mikuType) # Array[Item]
    def self.mikuTypeToItems(mikuType)
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        items = []
        db.execute("select * from _items_ where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # Items::mikuTypeCount(mikuType) # Integer
    def self.mikuTypeCount(mikuType)
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        count = 0
        db.execute("select count(*) as _count_ from _items_ where _mikuType_=?", [mikuType]) do |row|
            count = row["_count_"]
        end
        db.close
        count
    end

    # Items::nx20s() # Array[Nx20]
    def self.nx20s()
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        nx20s = []
        db.execute("select * from _items_", []) do |row|
            item = JSON.parse(row["_item_"])
            nx20s << {
                "announce" => "(#{row["_mikuType_"]}) #{row["_announce_"]}",
                "unixtime" => item["unixtime"],
                "item"     => item
            }
        end
        db.close
        nx20s
    end

    # -----------------------------------------------------------------
    # ATTRIBUTE UPDATE and DELETE

    # Items::setAttributeNoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttributeNoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
        item = Items::getItemOrNull(objectuuid)
        return if item.nil?
        item[attname] = attvalue
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _items_ where _uuid_=?", [item["uuid"]]
        db.execute "insert into _items_ (_uuid_, _mikuType_, _announce_, _item_) values (?, ?, ?, ?)", [item["uuid"], item["mikuType"], PolyFunctions::genericDescriptionOrNull(item), JSON.generate(item)]
        db.close
    end

    # Items::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        eventuuid = SecureRandom.uuid
        eventTime = Time.new.to_f
        Items::setAttributeNoEvents(objectuuid, eventuuid, Time.new.to_f, attname, attvalue)
        SystemEvents::broadcast({
            "mikuType"   => "AttributeUpdate.v2",
            "objectuuid" => objectuuid,
            "eventuuid"  => eventuuid,
            "eventTime"  => eventTime,
            "attname"    => attname,
            "attvalue"   => attvalue
        })
    end

    # Items::deleteNoEvents(objectuuid)
    def self.deleteNoEvents(objectuuid)
        db = SQLite3::Database.new(Items::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _items_ where _uuid_=?", [objectuuid]
        db.close
    end

    # Items::delete(objectuuid)
    def self.delete(objectuuid)
        itemx = Items::getItemOrNull(objectuuid)
        Items::deleteNoEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid
        })
        if itemx then
            PolyActions::garbageCollectionAfterItemDeletion(itemx)
        end
    end

    # -----------------------------------------------------------------
    # EVENTS

    # Items::processEvent(event)
    def self.processEvent(event)

        if event["mikuType"] == "TxEventItem1" then
            item = event["item"]
            Items::putItemNoEvent(item, false)
        end

        if event["mikuType"] == "AttributeUpdate" then
            objectuuid = event["objectuuid"]
            eventuuid  = event["eventuuid"]
            eventTime  = event["eventTime"]
            attname    = event["attname"]
            attvalue   = event["attvalue"]
            Items::setAttributeNoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
        end

        if event["mikuType"] == "NxDeleted" then
            objectuuid = event["objectuuid"]
            Items::deleteNoEvents(objectuuid)
        end
    end
end
