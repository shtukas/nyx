# encoding: UTF-8

class LightSpeed

    # LightSpeed::periods()
    def self.periods()
        ["hours", "days", "weeks", "months"]
    end

    # Makers

    # LightSpeed::interactivelySelectPeriodOrNull()
    def self.interactivelySelectPeriodOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("period (none to abort):", LightSpeed::periods())
    end

    # LightSpeed::interactivelySelectPeriod()
    def self.interactivelySelectPeriod()
        loop {
            period = LightSpeed::interactivelySelectPeriodOrNull()
            if period then
                return period
            end
        }
    end

    # LightSpeed::interactivelyCreateNewLightSpeed()
    def self.interactivelyCreateNewLightSpeed()
        {
            "unixtime" => Time.new.to_f,
            "period"   => LightSpeed::interactivelySelectPeriod()
        }
    end

    # LightSpeed::fromComponents(unixtime, period)
    def self.fromComponents(unixtime, period)
        {
            "unixtime" => unixtime,
            "period"   => period
        }
    end

    # LightSpeed::metric(itemuuid, lightspeed)
    def self.metric(itemuuid, lightspeed)

        ageingRatio = lambda {|lightspeed|
            if lightspeed["period"] == "hours" then
                return 1
            end
            if lightspeed["period"] == "days" then
                return (Time.new.to_f - lightspeed["unixtime"]).to_f/(86400*7)
            end
            if lightspeed["period"] == "weeks" then
                return (Time.new.to_f - lightspeed["unixtime"]).to_f/(86400*7*30)
            end
            if lightspeed["period"] == "months" then
                return (Time.new.to_f - lightspeed["unixtime"]).to_f/(86400*7*30*6)
            end
        }

        shiftOnUnixtime = lambda {|unixtime|
            0.001*Math.log(Time.new.to_f - unixtime)
        }

        if lightspeed["period"] == "hours" then
            return 0.76 + shiftOnUnixtime.call(lightspeed["unixtime"])
        end

        if lightspeed["period"] == "days" then
            ageing = ageingRatio.call(lightspeed)
            return 0.25 + (0.5 * ageing)
        end

        if lightspeed["period"] == "weeks" then
            ageing = ageingRatio.call(lightspeed)
            return 0.20 + (0.5 * ageing)
        end

        if lightspeed["period"] == "months" then
            ageing = ageingRatio.call(lightspeed)
            return 0.15 + (0.5 * ageing)
        end
    end
end