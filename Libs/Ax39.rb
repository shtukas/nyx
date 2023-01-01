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
            return "weekly:saturday #{ax39["hours"]} hours"
        end
        if ax39["type"] == "weekly-starting-on-Monday" then
            return "weekly:monday #{ax39["hours"]} hours"
        end
    end

    # Ax39::toStringFormatted(ax39)
    def self.toStringFormatted(ax39)
        if ax39["type"] == "weekly-starting-on-Saturday" then
            return "weekly:saturday #{"%5.2f" % ax39["hours"]} hours"
        end
        if ax39["type"] == "weekly-starting-on-Monday" then
            return "weekly:monday   #{"%5.2f" % ax39["hours"]} hours"
        end
    end

    # Ax39::operationalRatioOrNull(uuid, ax39, hasNxBall, unrealisedTimespan = nil)
    def self.operationalRatioOrNull(uuid, ax39, hasNxBall, unrealisedTimespan = nil)
        return nil if (!hasNxBall and !DoNotShowUntil::isVisible(uuid))
        if ax39["type"] == "weekly-starting-on-Saturday" then

            return nil if (!hasNxBall and Time.new.wday == 5) # We ignore those on Friday

            dates                                 = CommonUtils::datesSinceLastSaturday()
            actualTimeDoneInSecondsSinceInception = Bank::combinedValueOnThoseDays(uuid, dates, unrealisedTimespan)
            idealTimeDoneInSecondsSinceInception  = (dates.size.to_f/5)*ax39["hours"]*3600
            isUpToDate                            = (actualTimeDoneInSecondsSinceInception > idealTimeDoneInSecondsSinceInception)

            return nil if (!hasNxBall and isUpToDate)

            todayTimeInSeconds    = Bank::valueAtDate(uuid, CommonUtils::today(), unrealisedTimespan)
            todayDueTimeInSeconds = (ax39["hours"]*3600).to_f/5
            ratio                 = todayTimeInSeconds.to_f/todayDueTimeInSeconds

            return ratio
        end
        if ax39["type"] == "weekly-starting-on-Monday" then

            return nil if (!hasNxBall and Time.new.wday == 6) # We ignore those on Saturday

            dates                                 = CommonUtils::datesSinceLastMonday()
            actualTimeDoneInSecondsSinceInception = Bank::combinedValueOnThoseDays(uuid, dates, unrealisedTimespan)
            idealTimeDoneInSecondsSinceInception  = (dates.size.to_f/5)*ax39["hours"]*3600
            isUpToDate                            = (actualTimeDoneInSecondsSinceInception > idealTimeDoneInSecondsSinceInception)

            return nil if (!hasNxBall and isUpToDate)

            todayTimeInSeconds    = Bank::valueAtDate(uuid, CommonUtils::today(), unrealisedTimespan)
            todayDueTimeInSeconds = (ax39["hours"]*3600).to_f/5
            ratio                 = todayTimeInSeconds.to_f/todayDueTimeInSeconds

            return ratio
        end
    end

    # Ax39::standardAx39CarrierOperationalRatioOrNull(item)
    def self.standardAx39CarrierOperationalRatioOrNull(item)
        uuid = item["uuid"]
        ax39 = item["ax39"]
        nxball = NxBalls::getNxBallForItemOrNull(item)
        unrealisedTimespan = nxball ? (Time.new.to_f - nxball["unixtime"]) : nil
        Ax39::operationalRatioOrNull(uuid, ax39, !nxball.nil?, unrealisedTimespan)
    end
end
