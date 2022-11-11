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

    # Ax39::toString(ax39)
    def self.toString(ax39)
        if ax39["type"] == "daily-singleton-run" then
            return "daily once"
        end
        if ax39["type"] == "daily-time-commitment" then
            return "daily #{"%4.2f" % ax39["hours"]} hours"
        end
        if ax39["type"] == "weekly-time-commitment" then
            return "weekly #{"%4.2f" % ax39["hours"]} hours"
        end
    end

    # Ax39::completionRatio(ax39, uuid)
    def self.completionRatio(ax39, uuid)
        raise "(error: 92e23de4-61eb-4a07-a128-526e4be0e72a)" if ax39.nil?
        return 1 if !DoNotShowUntil::isVisible(uuid)
        if ax39["type"] == "daily-singleton-run" then
            return 0
        end
        if ax39["type"] == "daily-time-commitment" then
            return [
                Bank::valueAtDate(uuid, CommonUtils::today()).to_f/(3600*ax39["hours"]),
                BankExtended::stdRecoveredDailyTimeInHours(uuid).to_f/ax39["hours"]
            ].max
        end
        if ax39["type"] == "weekly-time-commitment" then
            return [
                Bank::valueAtDate(uuid, CommonUtils::today()).to_f/(0.3*3600*ax39["hours"]),
                Bank::combinedValueOnThoseDays(uuid, CommonUtils::dateSinceLastSaturday()).to_f/(3600*ax39["hours"])
            ].max
        end
    end
end
