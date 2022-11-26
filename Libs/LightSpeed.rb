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

    # LightSpeed::metric(lightspeed)
    def self.metric(lightspeed)
        0.5
    end
end