
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

    # NxTodoExpectations::expectationToUrgency(expectation)
    def self.expectationToUrgency(expectation)
        return 1
    end
end
