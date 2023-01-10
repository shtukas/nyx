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

    # Ax39::data(uuid, ax39, hasNxBall, unrealisedTimespan = nil)
    def self.data(uuid, ax39, hasNxBall, unrealisedTimespan = nil)
        dates = nil
        if ax39["type"] == "weekly-starting-on-Saturday" then
            dates = CommonUtils::datesSinceLastSaturday()
        end
        if ax39["type"] == "weekly-starting-on-Monday" then
            dates = CommonUtils::datesSinceLastMonday()
        end

        weekActualTimeDoneInSeconds  = Bank::combinedValueOnThoseDays(uuid, dates, unrealisedTimespan)
        weekIdealTimeDoneInSeconds   = ([dates.size.to_f/5, 1].min)*ax39["hours"]*3600
        weekIsUpToDate               = (weekActualTimeDoneInSeconds >= weekIdealTimeDoneInSeconds)
        weekMissingTimeInSecondsOpt  = weekIsUpToDate ? nil : (weekIdealTimeDoneInSeconds-weekActualTimeDoneInSeconds)

        todayDoneTimeInSeconds       = Bank::valueAtDate(uuid, CommonUtils::today(), unrealisedTimespan)
        todayDueTimeInSeconds        = (ax39["hours"]*3600).to_f/5
        todayRatio                   = todayDoneTimeInSeconds.to_f/todayDueTimeInSeconds
        todayMissingTimeInSecondsOpt = (todayRatio < 1) ? todayDueTimeInSeconds - todayDoneTimeInSeconds : nil

        shouldListing = (hasNxBall or (!weekIsUpToDate and todayRatio < 1.2))

        if ax39["type"] == "weekly-starting-on-Monday" and Time.new.wday == 6 then
            shouldListing = hasNxBall
        end

        return {
            "dates"                       => dates,
            "shouldListing"               => shouldListing,
            "weekActualTimeDoneInHours"   => weekActualTimeDoneInSeconds.to_f/3600,
            "weekIdealTimeDoneInHours"    => weekIdealTimeDoneInSeconds.to_f/3600,
            "weekIsUpToDate"              => weekIsUpToDate,
            "weekMissingTimeInHoursOpt"   => weekMissingTimeInSecondsOpt ? weekMissingTimeInSecondsOpt.to_f/3600 : nil,
            "todayDoneInHours"            => todayDoneTimeInSeconds.to_f/3600,
            "todayDueInHours"             => todayDueTimeInSeconds.to_f/3600,
            "todayRatio"                  => todayRatio,
            "todayMissingTimeInHoursOpt"  => todayMissingTimeInSecondsOpt ? todayMissingTimeInSecondsOpt.to_f/3600 : nil
        }
    end

    # Ax39::standardAx39CarrierData(item)
    def self.standardAx39CarrierData(item)
        uuid = item["uuid"]
        ax39 = item["ax39"]
        nxball = NxBalls::getNxBallForItemOrNull(item)
        unrealisedTimespan = nxball ? (Time.new.to_f - nxball["unixtime"]) : nil
        Ax39::data(uuid, ax39, !nxball.nil?, unrealisedTimespan)
    end
end
