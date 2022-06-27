# encoding: UTF-8

class Ax39

    # Ax39::type()
    def self.types()
        ["daily-time-commitment", "weekly-time-commitment"]
    end

    # Ax39::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Ax39::types())
    end

    # Ax39::interactivelyCreateNewAxOrNull()
    def self.interactivelyCreateNewAxOrNull()
        type = Ax39::interactivelySelectTypeOrNull()
        return nil if type.nil?
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
        if item["ax39"]["type"] == "daily-time-commitment" then
            return "(today: #{TxNumbersAcceleration::rt(item).round(2)} of #{item["ax39"]["hours"]} hours ⏱ )"
        end

        if item["ax39"]["type"] == "weekly-time-commitment" then
            return "(weekly: #{TxNumbersAcceleration::rt(item).round(2)} of #{item["ax39"]["hours"]} hours ⏱ )"
        end
    end

    # Ax39::itemShouldShow(item)
    def self.itemShouldShow(item)
        if item["ax39"] and item["ax39"]["type"] == "daily-time-commitment" then
            return TxNumbersAcceleration::rt(item) < item["ax39"]["hours"]
        end
        if item["ax39"] and item["ax39"]["type"] == "weekly-time-commitment" then
            return false if Time.new.wday == 5 # We don't show those on Fridays
            return TxNumbersAcceleration::combined_value(item) < item["ax39"]["hours"]
        end

        true
    end
end
