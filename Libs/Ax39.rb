# encoding: UTF-8

class Ax39

    # Ax39::types()
    def self.types()
        ["weekly-starting-on-Saturday", "weekly-starting-on-Monday"]
    end

    # Ax39::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Ax39::types())
    end

    # Ax39::interactivelyCreateNewAxOrNull()
    def self.interactivelyCreateNewAxOrNull()
        type = Ax39::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "weekly-starting-on-Saturday" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours : ")
            return nil if hours == ""
            return {
                "type"  => "weekly-starting-on-Saturday",
                "hours" => hours.to_f
            }
        end
        if type == "weekly-starting-on-Monday" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours : ")
            return nil if hours == ""
            return {
                "type"  => "weekly-starting-on-Monday",
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

    # Ax39::toString(ax39)
    def self.toString(ax39)
        if ax39["type"] == "weekly-starting-on-Saturday" then
            return "weekly:saturday #{"%4.2f" % ax39["hours"]} hours"
        end
        if ax39["type"] == "weekly-starting-on-Monday" then
            return "weekly:monday #{"%4.2f" % ax39["hours"]} hours"
        end
    end

    # Ax39::operationalRatio(uuid, ax39, unrealisedTimespan = nil)
    def self.operationalRatio(uuid, ax39, unrealisedTimespan = nil)
        raise "(error: 92e23de4-61eb-4a07-a128-526e4be0e72a)" if ax39.nil?
        return 1 if !DoNotShowUntil::isVisible(uuid)
        if ax39["type"] == "weekly-starting-on-Saturday" then

            return 1 if Time.new.wday == 5 # We ignore those on Friday

            dates                       = CommonUtils::datesSinceLastSaturday()
            actualTimeDoneInSeconds     = Bank::combinedValueOnThoseDays(uuid, dates, unrealisedTimespan)
            idealTimeDoneInSeconds      = ([dates.size, 5].min.to_f/5)*ax39["hours"]*3600
            ratio1                      = actualTimeDoneInSeconds.to_f/idealTimeDoneInSeconds

            todayTimeInSeconds          = Bank::valueAtDate(uuid, CommonUtils::today(), unrealisedTimespan)
            boostedDayDueTimeInSeconds  = 1.2*(ax39["hours"]*3600).to_f/7 # We operate over 7 days
            ratio2                      = todayTimeInSeconds.to_f/boostedDayDueTimeInSeconds

            return [ratio1, ratio2].max
        end
        if ax39["type"] == "weekly-starting-on-Monday" then

            return 1 if Time.new.wday == 6 # We ignore those on Saturday

            dates                       = CommonUtils::datesSinceLastMonday()
            actualTimeDoneInSeconds     = Bank::combinedValueOnThoseDays(uuid, dates, unrealisedTimespan)
            idealTimeDoneInSeconds      = ([dates.size, 5].min.to_f/5)*ax39["hours"]*3600
            ratio1                      = actualTimeDoneInSeconds.to_f/idealTimeDoneInSeconds

            todayTimeInSeconds          = Bank::valueAtDate(uuid, CommonUtils::today(), unrealisedTimespan)
            boostedDayDueTimeInSeconds  = 1.2*(ax39["hours"]*3600).to_f/5 # We operate ideally over 5 days
            ratio2                      = todayTimeInSeconds.to_f/boostedDayDueTimeInSeconds

            return [ratio1, ratio2].max
        end
    end

    # Ax39::standardAx39CarrierOperationalRatio(item)
    def self.standardAx39CarrierOperationalRatio(item)
        uuid = item["uuid"]
        ax39 = item["ax39"]
        nxball = NxBalls::getNxBallForItemOrNull(item)
        unrealisedTimespan = nxball ? (Time.new.to_f - nxball["unixtime"]) : nil
        Ax39::operationalRatio(uuid, ax39, unrealisedTimespan)
    end
end
