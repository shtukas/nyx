# encoding: UTF-8

$ItemsInMemoryCache = nil

class ItemsInMemoryCache

    # ItemsInMemoryCache::itemsFromLibrarianData()
    def self.itemsFromLibrarianData()
        object = TheLibrarian::getItems()
        object["mapping"].values.map{|nhash|
            sphere = DataStore3CAObjects::getObject(nhash)
            sphere["item"]
        }
        .compact
    end

    # ItemsInMemoryCache::itemsFromXCacheOrNull()
    def self.itemsFromXCacheOrNull()
        items = XCache::getOrNull("384aec10-0d54-4cc2-8246-73dc3b2235ae")
        return nil if items.nil?
        JSON.parse(items)
    end

    # ItemsInMemoryCache::items()
    def self.items()
        items = $ItemsInMemoryCache
        if items then
            return items
        end

        items = ItemsInMemoryCache::itemsFromXCacheOrNull()
        if items then
            $ItemsInMemoryCache = items
            return items
        end

        items = ItemsInMemoryCache::itemsFromLibrarianData()
        XCache::set("384aec10-0d54-4cc2-8246-73dc3b2235ae", JSON.generate(items))
        $ItemsInMemoryCache = items
        items
    end

    # ItemsInMemoryCache::incomingItem(item)
    def self.incomingItem(item)
        # This function is called after it has got a uuid and a mikuType, but not yet the other attributes
        begin
             FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, false)
        rescue
            return
        end
        items = ItemsInMemoryCache::items()
        items = items.reject{|i| i["uuid"] == item["uuid"] }
        items << item
        XCache::set("384aec10-0d54-4cc2-8246-73dc3b2235ae", JSON.generate(items))
        $ItemsInMemoryCache = items
    end

    # ItemsInMemoryCache::destroyed(itemuuid)
    def self.destroyed(itemuuid)
        items = items.reject{|i| i["uuid"] == itemuuid }
        items << item
        XCache::set("384aec10-0d54-4cc2-8246-73dc3b2235ae", JSON.generate(items))
        $ItemsInMemoryCache = items
    end

end

class Items

    # create table _index_ (_objectuuid_ text primary key, _unixtime_ float, _mikuType_ text, _announce_ text, _item_ text)

    # -----------------------------------------------------------------
    # READ

    # Items::objectuuids() # Array[objectuuid]
    def self.objectuuids()
        object = TheLibrarian::getItems()
        object["mapping"].keys
    end

    # Items::getItemOrNull(objectuuid)
    def self.getItemOrNull(objectuuid)
        object = TheLibrarian::getItems() 
        return nil if object["mapping"][objectuuid].nil?
        sphere = DataStore3CAObjects::getObject(object["mapping"][objectuuid])
        sphere["item"]
    end

    # Items::items() # Array[Item]
    def self.items()
        ItemsInMemoryCache::items()
    end

    # Items::mikuTypeToItems(mikuType) # Array[Item]
    def self.mikuTypeToItems(mikuType)
        Items::items().select{|item| item["mikuType"] == mikuType }
    end

    # Items::mikuTypeCount(mikuType) # Integer
    def self.mikuTypeCount(mikuType)
        Items::mikuTypeToItems(mikuType).count
    end

    # Items::nx20s() # Array[Nx20]
    def self.nx20s()
        Items::items().map{|item|
            {
                "announce" => "(#{item["mikuType"]}) #{PolyFunctions::genericDescriptionOrNull(item)}",
                "unixtime" => item["unixtime"],
                "item"     => item
            }
        }
    end

    # -----------------------------------------------------------------
    # ATTRIBUTE UPDATE and DELETE

    # Items::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
        TheLibrarian::processEvent({
            "mikuType"   => "AttributeUpdate.v2",
            "objectuuid" => objectuuid,
            "eventuuid"  => eventuuid,
            "eventTime"  => eventTime,
            "attname"    => attname,
            "attvalue"   => attvalue
        })
    end

    # Items::setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
        Items::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)

        event = {
            "mikuType"   => "AttributeUpdate.v2",
            "objectuuid" => objectuuid,
            "eventuuid"  => eventuuid,
            "eventTime"  => eventTime,
            "attname"    => attname,
            "attvalue"   => attvalue
        }

        FileSystemCheck::fsckAttributeUpdateV2(event, SecureRandom.hex, false)

        SystemEvents::broadcast(event)
    end

    # Items::setAttribute1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "Items::setAttribute1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        Items::setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
    end

    # Items::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        Items::setAttribute1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # Items::deleteObjectNoEvents(objectuuid)
    def self.deleteObjectNoEvents(objectuuid)
        object = TheLibrarian::getItems() 
        object["mapping"].delete(objectuuid)
        TheLibrarian::setItems(object)
    end
end
