# encoding: UTF-8

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
        sphere = TheLibrarian::getObject(object["mapping"][objectuuid])
        sphere["item"]
    end

    # Items::items() # Array[Item]
    def self.items()
        object = TheLibrarian::getItems()
        object["mapping"].values.map{|nhash|
            sphere = TheLibrarian::getObject(nhash)
            sphere["item"]
        }
        .compact
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

        FileSystemCheck::fsckAttributeUpdateV2(event, SecureRandom.hex)

        SystemEvents::broadcast(event)

        SystemEvents::internal({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => objectuuid
        })
        SystemEvents::broadcast({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => objectuuid
        })
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
