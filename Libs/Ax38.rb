# encoding: UTF-8

class Ax38

    # Ax38::type()
    def self.types()
        ["standard (stack until done with hourly overflow)", "today/asap" , "daily-fire-and-forget", "daily-time-commitment", "weekly-time-commitment"]
    end

    # Ax38::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Ax38::types())
    end

    # Ax38::interactivelyCreateNewAxOrNull()
    def self.interactivelyCreateNewAxOrNull()
        type = Ax38::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "standard (stack until done with hourly overflow)" then
            return {
                "type" => "standard"
            }
        end
        if type == "today/asap" then
            return {
                "type" => "today/asap"
            }
        end
        if type == "daily-fire-and-forget" then
            return {
                "type" => "daily-fire-and-forget"
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

    # Ax38::toString(ax38)
    def self.toString(ax38)
        if ax38.nil? then
            return "📥"
        end

        if ax38["type"] == "standard" then
            return "⛵️"
        end

        if ax38["type"] == "today/asap" then
            return "today/asap ❗️"
        end

        if ax38["type"] == "daily-fire-and-forget" then
            return "daily once 🪄"
        end

        if ax38["type"] == "daily-time-commitment" then
            return "today: #{ax38["hours"]} hours ⏱"
        end

        if ax38["type"] == "weekly-time-commitment" then
            return "weekly: #{ax38["hours"]} hours ⏱"
        end
    end
end
