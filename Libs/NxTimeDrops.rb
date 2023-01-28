
class NxTimeDrops

    # NxTimeDrops::start(item)
    def self.start(item)
        if item["mikuType"] != "NxTimeDrop" then
            puts "> the start command is only available for NxTimeDrops"
            LucilleCore::pressEnterToContinue()
            return
        end
        return if item["field2"] # We are already running
        TodoDatabase2::set(item["uuid"], "field2", Time.new.to_i)
    end

    # NxTimeDrops::stopAndPossiblyDestroy(item)
    def self.stopAndPossiblyDestroy(item)
        if item["mikuType"] != "NxTimeDrop" then
            puts "> the start command is only available for NxTimeDrops"
            LucilleCore::pressEnterToContinue()
        end
        return if item["field2"].nil? # We are not running
        unrealisedTime = Time.new.to_i - item["field2"]
        totalTimeInSeconds = item["field3"] + unrealisdTime
        if totalTimeInSeconds > item["field1"]*3600 then
            TodoDatabase2::destroy(item["uuid"])
        else
            item["field3"] = item["field3"] + unrealisedTime
            item["field2"] = nil
            TodoDatabase2::commitItem(item)
        end
    end

end