
# encoding: UTF-8

class NxTodoExpectations

    # NxTodoExpectations::interactivelyDecidePeriod()
    def self.interactivelyDecidePeriod()
        period = LucilleCore::selectEntityFromListOfEntitiesOrNull("period", ["hours", "days (default)", "weeks", "months"])
        if period.nil? or period == "days (default)" then
            return "days"
        end
        period
    end

    # NxTodoExpectations::makeNew()
    def self.makeNew()
        {
            "creation-unixtime" => Time.new.to_f,
            "period"            => NxTodoExpectations::interactivelyDecidePeriod()
        }
    end

    # NxTodoExpectations::nx54ToUrgency(nx54)
    def self.nx54ToUrgency(nx54)
        return 1
    end
end
