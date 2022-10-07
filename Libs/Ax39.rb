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

    # Ax39::completionRatio(ax39, bankaccount)
    def self.completionRatio(ax39, bankaccount)
        raise "(error: 92e23de4-61eb-4a07-a128-526e4be0e72a)" if ax39.nil?
        return 1 if BankAccountDoneForToday::isDoneToday(bankaccount)
        if ax39["type"] == "daily-singleton-run" then
            return BankAccountDoneForToday::isDoneToday(bankaccount) ? 1 : 0
        end
        if ax39["type"] == "daily-time-commitment" then
            return [
                Bank::valueAtDate(bankaccount, CommonUtils::today()).to_f/(3600*ax39["hours"]),
                BankExtended::stdRecoveredDailyTimeInHours(bankaccount).to_f/ax39["hours"]
            ].max
        end
        if ax39["type"] == "weekly-time-commitment" then
            return [
                Bank::valueAtDate(bankaccount, CommonUtils::today()).to_f/(0.3*3600*ax39["hours"]),
                Bank::combinedValueOnThoseDays(bankaccount, CommonUtils::dateSinceLastSaturday()).to_f/(3600*ax39["hours"])
            ].max
        end
    end

    # Ax39::completionRatioCached(ax39, bankaccount)
    def self.completionRatioCached(ax39, bankaccount)
        key = "#{ax39}:#{bankaccount}"
        value = XCacheValuesWithExpiry::getOrNull(key)
        return value if value
        value = Ax39::completionRatio(ax39, bankaccount)
        XCacheValuesWithExpiry::set(key, value, 300)
        value
    end
end
