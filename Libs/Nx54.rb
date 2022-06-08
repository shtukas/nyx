
# encoding: UTF-8

class Nx54

    # Nx54::interactivelyDecidePeriod()
    def self.interactivelyDecidePeriod()
        period = LucilleCore::selectEntityFromListOfEntitiesOrNull("period", ["hours", "days (default)", "weeks", "months"])
        if period.nil? or period == "days (default)" then
            return "days"
        end
        period
    end

    # Nx54::makeNew()
    def self.makeNew()
        {
            "type"              => "todo",
            "creation-unixtime" => Time.new.to_f,
            "period"            => Nx54::interactivelyDecidePeriod()
        }
    end

    # Nx54::nx54ToPriority(nx54)
    def self.nx54ToPriority(nx54)
        periodInSeconds = lambda {|period|
            if period == "hours" then
                return 3600*6
            end
            if period == "days" then
                return 86400*4
            end
            if period == "weeks" then
                return 86400*7*6
            end
            if period == "months" then
                return 86400*30*6
            end
            raise "(error: e359d1c6-d2ff-4241-aa9d-a8cd019264f2)"
        }
        if nx54["type"] == "todo" and nx54["period"] == "hours" then
            return 0
        end
        if nx54["type"] == "fire-and-forget-daily" then
            return 1
        end
        if nx54["type"] == "required-hours-days" then
            return 2
        end
        if nx54["type"] == "target-recovery-time" then
            return 3
        end
        if nx54["type"] == "todo" and nx54["period"] == "days" then
            return 4 + 0.1*Math.log(nx54["creation-unixtime"] + periodInSeconds.call(nx54["period"]), 10)
        end
        if nx54["type"] == "required-hours-week-saturday-start" then
            return 5
        end
        if nx54["type"] == "todo" and nx54["period"] == "weeks" then
            return 6 + 0.1*Math.log(nx54["creation-unixtime"] + periodInSeconds.call(nx54["period"]), 10)
        end
        if nx54["type"] == "todo" and nx54["period"] == "months" then
            return 7 + 0.1*Math.log(nx54["creation-unixtime"] + periodInSeconds.call(nx54["period"]), 10)
        end
        raise "(error: 3e95409f-3333-4496-ada9-dc8faf99ab47)"
    end
end
