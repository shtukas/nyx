# encoding: UTF-8

class Ax39

    # Ax39::types(mikuType)
    def self.types(mikuType)
        if mikuType == "TxProject" then
            return ["daily-singleton-run", "daily-time-commitment", "weekly-time-commitment"]
        end
        if mikuType == "TxQueue" then
            return ["daily-time-commitment", "weekly-time-commitment"]
        end
        raise "(error: dbc96edc-58b7-485c-aabc-b436db342881)"
    end

    # Ax39::interactivelySelectTypeOrNull(mikuType)
    def self.interactivelySelectTypeOrNull(mikuType)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Ax39::types(mikuType))
    end

    # Ax39::interactivelyCreateNewAxOrNull(mikuType)
    def self.interactivelyCreateNewAxOrNull(mikuType)
        type = Ax39::interactivelySelectTypeOrNull(mikuType)
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

    # Ax39::interactivelyCreateNewAx(mikuType)
    def self.interactivelyCreateNewAx(mikuType)
        loop {
            ax39 = Ax39::interactivelyCreateNewAxOrNull(mikuType)
            if ax39 then
                return ax39
            end
        }
    end

    # Ax39::toString(item)
    def self.toString(item)
        if item["ax39"]["type"] == "daily-singleton-run" then
            return "(daily fire and forget)"
        end

        if item["ax39"]["type"] == "daily-time-commitment" then
            return "(today: #{BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]).round(2)} of #{item["ax39"]["hours"]} hours; #{(100*Ax39::completionRatio(item)).round(2)} %)"
        end

        if item["ax39"]["type"] == "weekly-time-commitment" then
            return "(weekly: #{(Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()).to_f/3600).round(2)} of #{item["ax39"]["hours"]} hours; #{(100*Ax39::completionRatio(item)).round(2)} %)"
        end
    end

    # Ax39::itemShouldShow(item)
    def self.itemShouldShow(item)
        return false if !DoNotShowUntil::isVisible(item["uuid"])
        if item["ax39"]["type"] == "daily-singleton-run" then
            return !DoneToday::isDoneToday(item["uuid"])
        end
        if item["ax39"]["type"] == "daily-time-commitment" then
            return false if DoneToday::isDoneToday(item["uuid"])
            return false if BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) >= item["ax39"]["hours"]
            return true
        end
        if item["ax39"]["type"] == "weekly-time-commitment" then
            return false if Time.new.wday == 5 # We don't show those on Fridays
            return false if DoneToday::isDoneToday(item["uuid"])
            return false if Bank::valueAtDate(item["uuid"], CommonUtils::today()) >= 0.3*(3600*item["ax39"]["hours"])
            return false if Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()) >= 3600*item["ax39"]["hours"]
            return true
        end
        raise "(error: f2261ec2-25e1-4b60-b548-cee05162151e)"
    end

    # Ax39::completionRatio(item)
    def self.completionRatio(item)
        if item["ax39"]["type"] == "daily-singleton-run" then
            return DoneToday::isDoneToday(item["uuid"]) ? 1 : 0
        end
        if item["ax39"]["type"] == "daily-time-commitment" then
            return BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]).to_f/item["ax39"]["hours"]
        end
        if item["ax39"]["type"] == "weekly-time-commitment" then
            return Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()).to_f/(3600*item["ax39"]["hours"])
        end
    end
end
