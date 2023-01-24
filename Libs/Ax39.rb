# encoding: UTF-8

class Ax39

    # Ax39::types()
    def self.types()
        [
            "daily-provision-fillable",
            "weekly-starting-on-Saturday",
            "weekly-starting-on-Monday"
        ]
    end

    # Ax39::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Ax39::types())
    end

    # Ax39::interactivelyCreateNewAxOrNull()
    def self.interactivelyCreateNewAxOrNull()
        type = Ax39::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "daily-provision-fillable" then
            hours = LucilleCore::askQuestionAnswerAsString("hours : ")
            return nil if hours == ""
            return {
                "type"  => "daily-provision-fillable",
                "hours" => hours.to_f
            }
        end
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
        if ax39["type"] == "daily-provision-fillable" then
            return "daily #{ax39["hours"]} hours"
        end
        if ax39["type"] == "weekly-starting-on-Saturday" then
            return "weekly:saturday #{ax39["hours"]} hours"
        end
        if ax39["type"] == "weekly-starting-on-Monday" then
            return "weekly:monday #{ax39["hours"]} hours"
        end
    end

    # Ax39::toStringFormatted(ax39)
    def self.toStringFormatted(ax39)
        if ax39["type"] == "daily-provision-fillable" then
            return "daily           #{"%5.2f" % ax39["hours"]} hours"
        end
        if ax39["type"] == "weekly-starting-on-Saturday" then
            return "weekly:saturday #{"%5.2f" % ax39["hours"]} hours"
        end
        if ax39["type"] == "weekly-starting-on-Monday" then
            return "weekly:monday   #{"%5.2f" % ax39["hours"]} hours"
        end
    end

    # Ax39::liveNumbers(uuid, ax39, hasNxBall, unrealisedTimespan = nil)
    def self.liveNumbers(uuid, ax39, hasNxBall, unrealisedTimespan = nil)

        # This is the only place where the speed of light is used in a computation
        # We override the hours of the Ax39
        ax39["hours"] = ax39["hours"] * TheSpeedOfLight::getDaySpeedOfLight()

        # return {pendingTimeTodayInHoursLive}

        if ax39["type"] == "daily-provision-fillable" then
            doneTodayInSeconds = Bank::valueAtDate(uuid, CommonUtils::today(), unrealisedTimespan)
            requiredTodayInSeconds = ax39["hours"]*3600
            pendingTimeTodayInHoursLive = [requiredTodayInSeconds - doneTodayInSeconds, 0].max.to_f/3600
            return {
                "pendingTimeTodayInHoursLive"  => pendingTimeTodayInHoursLive
            }
        end

        dates = nil

        if ax39["type"] == "weekly-starting-on-Saturday" then
            dates = CommonUtils::datesSinceLastSaturday()
        end

        if ax39["type"] == "weekly-starting-on-Monday" then
            dates = CommonUtils::datesSinceLastMonday()
        end

        totalTimeForWeekInSeconds               = ax39["hours"]*3600
        doneTimeThisWeekBeforeTodayInSeconds    = Bank::combinedValueOnThoseDays(uuid, dates - [CommonUtils::today()], unrealisedTimespan)

        missingTimeThisWeekBeforeTodayInSeconds = [totalTimeForWeekInSeconds - doneTimeThisWeekBeforeTodayInSeconds, 0].max # We count the time before today to avoid this to change during today [1]
        numberOfDaysLeft                        = 7 - dates.size + 1

        timeWeShouldDoTodayInSeconds            = missingTimeThisWeekBeforeTodayInSeconds.to_f/numberOfDaysLeft
        timeWeDidTodayInSeconds                 = Bank::valueAtDate(uuid, CommonUtils::today(), unrealisedTimespan)
        pendingTimeTodayInSeconds               = [timeWeShouldDoTodayInSeconds - timeWeDidTodayInSeconds, 0].max

        {
            "pendingTimeTodayInHoursLive" => pendingTimeTodayInSeconds.to_f/3600,
        }
    end

    # Ax39::standardAx39CarrierLiveNumbers(item) # {pendingTimeTodayInHoursLive}
    def self.standardAx39CarrierLiveNumbers(item)
        uuid = item["uuid"]
        ax39 = item["ax39"]
        hasNxBall = NxBalls::getNxBallForItemOrNull(item)
        Ax39::liveNumbers(uuid, ax39, hasNxBall, NxBalls::itemUnrealisedRunTimeInSecondsOrNull(item))
    end
end
