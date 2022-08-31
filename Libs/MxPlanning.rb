=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

class MxPlanning

    # MxPlanning::commit(item)
    def self.commit(item)
        XCacheSets::set("3df64f03-acac-460e-a39a-ed90227e6b13", item["uuid"], item)
        SystemEvents::broadcast({
            "mikuType" => "MxPlanningCommit"
            "item"     => item
        })
    end

    # MxPlanning::items()
    def self.items()
        XCacheSets::values("3df64f03-acac-460e-a39a-ed90227e6b13")
    end

    # MxPlanning::destroy(itemuuid)
    def self.destroy(itemuuid)
        XCacheSets::destroy("3df64f03-acac-460e-a39a-ed90227e6b13", itemuuid)
        SystemEvents::broadcast({
            "mikuType" => "MxPlanningDelete"
            "itemuuid" => itemuuid
        })
    end

    # MxPlanning::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "MxPlanningCommit" then
            item = event["item"]
            XCacheSets::set("3df64f03-acac-460e-a39a-ed90227e6b13", item["uuid"], item)
        end
        if event["mikuType"] == "MxPlanningDelete" then
            itemuuid = event["itemuuid"]
            XCacheSets::destroy("3df64f03-acac-460e-a39a-ed90227e6b13", itemuuid)
        end
    end
end
