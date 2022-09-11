# encoding: UTF-8

class Ax39

    # Ax39::types()
    def self.types()
        ["daily-singleton-run", "daily-time-commitment", "weekly-time-commitment"]
    end

    # Ax39::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Ax39::types())
    end

    # Ax39::interactivelyCreateNewAxOrNull()
    def self.interactivelyCreateNewAxOrNull()
        type = Ax39::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "daily-singleton-run" then
            return {
                "type" => "daily-singleton-run"
            }
        end
        if type == "daily-time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours : ")
            return nil if hours == ""
            return {
                "type"  => "daily-time-commitment",
                "hours" => hours.to_f
            }
        end
        if type == "weekly-time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours : ")
            return nil if hours == ""
            return {
                "type"  => "weekly-time-commitment",
                "hours" => hours.to_f
            }
        end
    end

    # Ax39::interactivelyCreateNewAx()
    def self.interactivelyCreateNewAx()
        loop {
            ax39 = Ax39::interactivelyCreateNewAxOrNull()
            if ax39 then
                return ax39
            end
        }
    end

    # Ax39::toString(item)
    def self.toString(item)
        if item["ax39"].nil? then
            return "(no Ax39)"
        end
        if item["ax39"]["type"] == "daily-singleton-run" then
            return "(daily fire and forget)"
        end

        if item["ax39"]["type"] == "daily-time-commitment" then
            return "(today: #{(Bank::valueAtDate(item["uuid"], CommonUtils::today()).to_f/3600).round(2)} of #{item["ax39"]["hours"]} hours; #{(100*Ax39::completionRatio(item)).round(2)} %)"
        end

        if item["ax39"]["type"] == "weekly-time-commitment" then
            return "(weekly: #{(Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()).to_f/3600).round(2)} of #{item["ax39"]["hours"]} hours; #{(100*Ax39::completionRatio(item)).round(2)} %)"
        end
    end

    # Ax39::itemShouldShow(item)
    def self.itemShouldShow(item)
        return false if !DoNotShowUntil::isVisible(item["uuid"])
        return false if DoneForToday::isDoneToday(item["uuid"])
        if item["ax39"].nil? then
            return true
        end
        if item["ax39"]["type"] == "daily-singleton-run" then
            return true
        end
        if item["ax39"]["type"] == "daily-time-commitment" then
            return false if Ax39::completionRatio(item) >= 1
            return true
        end
        if item["ax39"]["type"] == "weekly-time-commitment" then
            return false if [1, 2, 3, 4].include?(Time.new.wday) # We show these on Fridays, Saturdays and Sundays
            return false if Ax39::completionRatio(item) >= 1
            return true
        end
        raise "(error: f2261ec2-25e1-4b60-b548-cee05162151e) #{JSON.pretty_generate(item)}"
    end

    # Ax39::completionRatio(item)
    def self.completionRatio(item)
        if item["ax39"]["type"] == "daily-singleton-run" then
            return DoneForToday::isDoneToday(item["uuid"]) ? 1 : 0
        end
        if item["ax39"]["type"] == "daily-time-commitment" then
            return [ 
                Bank::valueAtDate(item["uuid"], CommonUtils::today()).to_f/(3600*item["ax39"]["hours"]),
                BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]).to_f/item["ax39"]["hours"]
            ].max
        end
        if item["ax39"]["type"] == "weekly-time-commitment" then
            return [
                Bank::valueAtDate(item["uuid"], CommonUtils::today()).to_f/(0.3*3600*item["ax39"]["hours"]),
                Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()).to_f/(3600*item["ax39"]["hours"])
            ].max
        end
    end

    # Ax39::orderingValue(item)
    def self.orderingValue(item)
        if item["ax39"]["type"] == "daily-singleton-run" then
            return DoneForToday::isDoneToday(item["uuid"]) ? 1 : 0
        end
        if item["ax39"]["type"] == "daily-time-commitment" then
            return [ 
                Bank::valueAtDate(item["uuid"], CommonUtils::today()).to_f/(3600*item["ax39"]["hours"]),
                BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]).to_f/item["ax39"]["hours"]
            ].max
        end
        if item["ax39"]["type"] == "weekly-time-commitment" then
            return [
                Bank::valueAtDate(item["uuid"], CommonUtils::today()).to_f/(0.3*3600*item["ax39"]["hours"]),
                Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()).to_f/(3600*item["ax39"]["hours"])
            ].max
        end
    end
end

class Ax39forSections

    # Ax39forSections::completionRatio(item)
    def self.completionRatio(item)
        cachekey = "abdc09cb-49ec-4a0e-96e1-92abba113bfd:#{item["uuid"]}"
        ratio = XCacheValuesWithExpiry::getOrNull(cachekey)
        return ratio if ratio
        ratio = Ax39::completionRatio(item)
        XCacheValuesWithExpiry::set(cachekey, ratio, 3600)
        ratio
    end

    # Ax39forSections::orderingValue(item)
    def self.orderingValue(item)
        cachekey = "0e9aba8c-9818-4c4b-9338-756508d6ea72:#{item["uuid"]}"
        ratio = XCacheValuesWithExpiry::getOrNull(cachekey)
        return ratio if ratio
        ratio = Ax39::orderingValue(item)
        XCacheValuesWithExpiry::set(cachekey, ratio, 3600)
        ratio
    end

    # Ax39forSections::itemShouldShow(item)
    def self.itemShouldShow(item)
        cachekey = "2383339b-6beb-4249-bac9-2db0924eb347:#{item["uuid"]}"
        itemShouldShow = XCacheValuesWithExpiry::getOrNull(cachekey)
        return itemShouldShow if !itemShouldShow.nil?
        itemShouldShow = Ax39::itemShouldShow(item)
        XCacheValuesWithExpiry::set(cachekey, itemShouldShow, 3600)
        itemShouldShow
    end

    # Ax39forSections::toStringElements(item)
    def self.toStringElements(item)
        if item["ax39"].nil? then
            return ["(no Ax39)", nil]
        end
        if item["ax39"]["type"] == "daily-singleton-run" then
            return ["(daily fire and forget)", nil]
        end

        if item["ax39"]["type"] == "daily-time-commitment" then
            return ["(today : #{"%5.2f" % (Bank::valueAtDate(item["uuid"], CommonUtils::today()).to_f/3600)} of #{"%5.2f" % item["ax39"]["hours"]} hours)", 100*Ax39forSections::completionRatio(item)]
        end

        if item["ax39"]["type"] == "weekly-time-commitment" then
            return ["(weekly: #{"%5.2f" % (Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()).to_f/3600)} of #{"%5.2f" % item["ax39"]["hours"]} hours)", 100*Ax39forSections::completionRatio(item)]
        end
    end

    # Ax39forSections::toString(item)
    def self.toString(item)
        Ax39forSections::toStringElements(item).compact.join(" ")
    end
end

class Ax39Extensions

    # Ax39Extensions::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "(bank account has been updated)" then
            setuuid = event["setuuid"]
            XCache::destroy("abdc09cb-49ec-4a0e-96e1-92abba113bfd:#{setuuid}") # to decache the completion ratio 
            XCache::destroy("2383339b-6beb-4249-bac9-2db0924eb347:#{setuuid}") # to decache the shouldShow flag
            XCache::destroy("0e9aba8c-9818-4c4b-9338-756508d6ea72:#{setuuid}") # to decache the orderingValue

        end
        if event["mikuType"] == "(element has been done for today)" then
            objectuuid = event["objectuuid"]
            XCache::destroy("abdc09cb-49ec-4a0e-96e1-92abba113bfd:#{objectuuid}") # to decache the completion ratio 
            XCache::destroy("2383339b-6beb-4249-bac9-2db0924eb347:#{objectuuid}") # to decache the shouldShow flag
            XCache::destroy("0e9aba8c-9818-4c4b-9338-756508d6ea72:#{objectuuid}") # to decache the orderingValue
        end
        if event["mikuType"] == "(do not show until has been updated)" then
            objectuuid = event["targetuuid"]
            XCache::destroy("2383339b-6beb-4249-bac9-2db0924eb347:#{objectuuid}") # to decache the shouldShow flag
            XCache::destroy("0e9aba8c-9818-4c4b-9338-756508d6ea72:#{objectuuid}") # to decache the orderingValue
        end
    end
end