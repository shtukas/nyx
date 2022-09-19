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
end

class Ax39Extensions

    # Ax39Extensions::completionRatio(ax39, itemuuid)
    def self.completionRatio(ax39, itemuuid)
        raise "(error: 92e23de4-61eb-4a07-a128-526e4be0e72a)" if ax39.nil?
        if ax39["type"] == "daily-singleton-run" then
            return DoneForToday::isDoneToday(itemuuid) ? 1 : 0
        end
        if ax39["type"] == "daily-time-commitment" then
            return [ 
                Bank::valueAtDate(itemuuid, CommonUtils::today()).to_f/(3600*ax39["hours"]),
                BankExtended::stdRecoveredDailyTimeInHours(itemuuid).to_f/ax39["hours"]
            ].max
        end
        if ax39["type"] == "weekly-time-commitment" then
            return [
                Bank::valueAtDate(itemuuid, CommonUtils::today()).to_f/(0.3*3600*ax39["hours"]),
                Bank::combinedValueOnThoseDays(itemuuid, CommonUtils::dateSinceLastSaturday()).to_f/(3600*ax39["hours"])
            ].max
        end
    end

    # Ax39Extensions::toString2OrNull(ax39 = nil, itemuuid)
    def self.toString2OrNull(ax39 = nil, itemuuid)
        return nil if ax39.nil?
        if ax39["type"] == "daily-singleton-run" then
            return "(daily fire and forget)"
        end
        if ax39["type"] == "daily-time-commitment" then
            return "(today: #{(Bank::valueAtDate(itemuuid, CommonUtils::today()).to_f/3600).round(2)} of #{ax39["hours"]} hours; #{(100*Ax39Extensions::completionRatio(ax39, itemuuid)).round(2)} %)"
        end
        if ax39["type"] == "weekly-time-commitment" then
            return "(weekly: #{(Bank::combinedValueOnThoseDays(itemuuid, CommonUtils::dateSinceLastSaturday()).to_f/3600).round(2)} of #{ax39["hours"]} hours; #{(100*Ax39Extensions::completionRatio(ax39, itemuuid)).round(2)} %)"
        end
    end

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