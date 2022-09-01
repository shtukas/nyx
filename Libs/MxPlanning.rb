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

    # MxPlanning::interactivelyMakeNewPayloadOrNull()
    def self.interactivelyMakeNewPayloadOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "pointer"])
        return nil if type == ""
        if type == "line" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            return {
                "type"        => "simple",
                "description" => description
            }
        end
        if type == "pointer" then
            item = nil # Interactively choose a catalyst item
            raise "(error: 30f01d52-c70b-43f3-a208-6eefef0af2b4) no implemented yet"
            return {
                "type" => "item",
                "item" => item
            }
        end
    end

    # MxPlanning::nextOrdinal()
    def self.nextOrdinal()
        (MxPlanning::items().map{|item| item["ordinal"] } + [0]).max + 1
    end

    # MxPlanning::interactivelyDecideOrdinal()
    def self.interactivelyDecideOrdinal()
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (`next` or empty for next): ")
        if ordinal == "next" or ordinal == "" then
            ordinal = MxPlanning::nextOrdinal()
        else
            ordinal = ordinal.to_f
        end
    end

    # MxPlanning::interactivelyDecideTimespanInHours()
    def self.interactivelyDecideTimespanInHours()
        input = LucilleCore::askQuestionAnswerAsString("timespan (`n mins` or `n hours`): ")
        number = input.to_f
        if input.include?("min") then
            return number*(60.to_f/3600)
        end
        if input.include?("hour") then
            return number
        end
        MxPlanning::interactivelyDecideTimespanInHours()
    end

    # MxPlanning::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        payload = MxPlanning::interactivelyMakeNewPayloadOrNull()
        return nil if payload.nil?
        ordinal = MxPlanning::interactivelyDecideOrdinal()
        timespanInHour = MxPlanning::interactivelyDecideTimespanInHours()
        item = {
            "uuid"           => SecureRandom.uuid,
            "mikuType"       => "MxPlanning",
            "payload"        => payload,
            "ordinal"        => ordinal,
            "timespanInHour" => timespanInHour
        }
        MxPlanning::commit(item)
        item
    end

    # MxPlanning::interactivelyIssueNewLineOrNull()
    def self.interactivelyIssueNewLineOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = {
            "type"        => "simple",
            "description" => description
        }
        ordinal = MxPlanning::interactivelyDecideOrdinal()
        timespanInHour = MxPlanning::interactivelyDecideTimespanInHours()
        item = {
            "uuid"           => SecureRandom.uuid,
            "mikuType"       => "MxPlanning",
            "payload"        => payload,
            "ordinal"        => ordinal,
            "timespanInHour" => timespanInHour
        }
        MxPlanning::commit(item)
        item
    end

    # MxPlanning::interactivelyIssueNewWithCatalystItem(catalystitem)
    def self.interactivelyIssueNewWithCatalystItem(catalystitem)
        payload = {
            "type" => "pointer",
            "item" => catalystitem
        }
        ordinal = MxPlanning::interactivelyDecideOrdinal()
        timespanInHour = MxPlanning::interactivelyDecideTimespanInHours()
        planningItem = {
            "uuid"           => SecureRandom.uuid,
            "mikuType"       => "MxPlanning",
            "payload"        => payload,
            "ordinal"        => ordinal,
            "timespanInHour" => timespanInHour
        }
        MxPlanning::commit(planningItem)
        planningItem
    end

    # MxPlanning::toString(item)
    def self.toString(item)
        payload = item["payload"]
        if payload["type"] == "simple" then
            return "(MxPlanning, line) #{payload["description"]}"
        end
        if payload["type"] == "pointer" then
            return "(MxPlanning, pointer) #{LxFunction::function("toString", payload["item"])}"
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
        items
            .select{|item| DoNotShowUntil::isVisible("MxPlanningDisplayItem:#{item["uuid"]}") }
            .map{|item|
                XCacheValuesWithExpiry::set("recently-listed-uuid-ad5b7c29c1c6:#{item["uuid"]}", "true", 60) # A special purpose way to not display a NxBall.
                uuid = Digest::SHA1.hexdigest("b89d1572-4dd9-480f-8746-5ed433776b41:#{item["uuid"]}")
                unixtime1 = NxBallsService::startUnixtimeOrNull(uuid) || unixtime1
                unixtime2 = unixtime1 + item["timespanInHour"]*3600
                displayItem = {
                    "uuid"          => uuid,
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
        "(MxPlanningDisplay) (ord: #{"%5.2f" % displayItem["item"]["ordinal"]}) (start: #{MxPlanning::unixtimeToTime(displayItem["startUnixtime"]).green}, timespan: #{("%5.2f" % displayItem["item"]["timespanInHour"]).green} hours, end: #{MxPlanning::unixtimeToTime(displayItem["endUnixtime"]).green}) #{MxPlanning::toString(displayItem["item"])}"
    end

    # MxPlanning::catalystItemsUUIDs()
    def self.catalystItemsUUIDs()
        MxPlanning::items()
        .select{|item| item["payload"]["type"] == "pointer" }
        .map{|item| item["payload"]["item"]["uuid"]}
    end

    # MxPlanning::listingItems()
    def self.listingItems()
        MxPlanning::displayItems()
    end
end
