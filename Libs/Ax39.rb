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
            return "(today: #{TxNumbersAcceleration::rt(item).round(2)} of #{item["ax39"]["hours"]} hours)"
        end

        if item["ax39"]["type"] == "weekly-time-commitment" then
            return "(weekly: #{TxNumbersAcceleration::rt(item).round(2)} of #{item["ax39"]["hours"]} hours)"
        end
    end

    # Ax39::itemShouldShow(item)
    def self.itemShouldShow(item)
        if item["ax39"]["type"] == "daily-singleton-run" then
            return Bank::valueAtDate(item["uuid"], CommonUtils::today()) > 0
        end
        if item["ax39"]["type"] == "daily-time-commitment" then
            return TxNumbersAcceleration::rt(item) < item["ax39"]["hours"]
        end
        if item["ax39"]["type"] == "weekly-time-commitment" then
            return false if Time.new.wday == 5 # We don't show those on Fridays
            return TxNumbersAcceleration::combined_value(item) < item["ax39"]["hours"]
        end
        true
    end
end
