
# encoding: UTF-8

class NxTodoExpectations

    # NxTodoExpectations::interactivelyDecidePeriod()
    def self.interactivelyDecidePeriod()
        period = LucilleCore::selectEntityFromListOfEntitiesOrNull("period", ["hours", "days", "weeks", "months"])
        return period if period
        "days"
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
