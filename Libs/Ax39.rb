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
        if item["ax39"].nil? then
            return false if DoneForToday::isDoneToday(item["uuid"])
            return true
        end
        if item["ax39"]["type"] == "daily-singleton-run" then
            return false if DoneForToday::isDoneToday(item["uuid"])
            return true
        end
        if item["ax39"]["type"] == "daily-time-commitment" then
            return false if DoneForToday::isDoneToday(item["uuid"])
            return false if Ax39::completionRatio(item) >= 1
            return true
        end
        if item["ax39"]["type"] == "weekly-time-commitment" then
            return false if Time.new.wday == 5 # We don't show those on Fridays
            return false if DoneForToday::isDoneToday(item["uuid"])
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
end
