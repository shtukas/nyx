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
end
