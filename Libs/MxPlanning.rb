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
            "mikuType" => "MxPlanningCommit",
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
            "mikuType" => "MxPlanningDelete",
            "itemuuid" => itemuuid
        })
    end

    # MxPlanning::toString(item)
    def self.toString(item)
        payload = item["payload"]
        if payload["type"] == "simple" then
            return payload["description"]
        end
        if payload["type"] == "pointer" then
            return LxFunction::function("toString", payload["item"])
        end
        raise "(error: 9fbcd583-6757-4b90-bd9d-b56c6aabe73f): #{item}"
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

    # MxPlanning::displayItems()
    def self.displayItems()
        items = MxPlanning::items().sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"]}
        unixtime1 = Time.new.to_f
        unixtime2 = nil
        items.map{|item|
            unixtime2 = unixtime1 + item["timespanInHour"]*3600
            displayItem = {
                "mikuType"      => "MxPlanningDisplay",
                "item"          => item,
                "startUnixtime" => unixtime1,
                "endUnixtime"   => unixtime2
            }
            unixtime1 = unixtime2
            displayItem
        }
    end

    # MxPlanning::unixtimeToTime(unixtime)
    def self.unixtimeToTime(unixtime)
        Time.at(unixtime).to_s[11, 5]
    end

    # MxPlanning::displayItemToString(displayItem)
    def self.displayItemToString(displayItem)
        "(id: #{displayItem["item"]["uuid"]}) (ord: #{"%5.2f" % displayItem["item"]["ordinal"]}) (start: #{MxPlanning::unixtimeToTime(displayItem["startUnixtime"])}, end: #{MxPlanning::unixtimeToTime(displayItem["endUnixtime"])}) #{MxPlanning::toString(displayItem["item"])}"
    end
end
