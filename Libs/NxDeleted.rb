# encoding: UTF-8

class NxDeleted

    # NxDeleted::deleteObjectNoEvents(objectuuid)
    def self.deleteObjectNoEvents(objectuuid)
        ItemsEventsLog::deleteObjectNoEvents(objectuuid)
        Items::deleteObjectNoEvents(objectuuid)
    end

    # NxDeleted::deleteObject(objectuuid)
    def self.deleteObject(objectuuid)
        NxDeleted::deleteObjectNoEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        SystemEvents::internal({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => objectuuid
        })
    end
end
