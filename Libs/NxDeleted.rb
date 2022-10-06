# encoding: UTF-8

class NxDeleted

    # NxDeleted::deleteObjectNoEvents(objectuuid)
    def self.deleteObjectNoEvents(objectuuid)
        Items::deleteObjectNoEvents(objectuuid)
    end

    # NxDeleted::deleteObject(objectuuid)
    def self.deleteObject(objectuuid)
        NxDeleted::deleteObjectNoEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        ItemsInMemoryCache::destroyed(itemuuid)
    end
end
