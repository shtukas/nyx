
class TheSpeedOfLight
 
    # TheSpeedOfLight::getDaySpeedOfLight()
    def self.getDaySpeedOfLight()
        filepath = "#{Config::pathToDataCenter()}/TheSpeedOfLight.json"
        return 1 if !File.exists?(filepath)
        data = JSON.parse(IO.read(filepath))
        # data: {date, value}
        return 1 if data["date"] != CommonUtils::today()
        data["speed"]
    end

    # TheSpeedOfLight::decrementLightSpeed()
    def self.decrementLightSpeed()
        speed = TheSpeedOfLight::getDaySpeedOfLight()
        data = {
            "date"  => CommonUtils::today(),
            "speed" => speed-0.1*rand
        }
        filepath = "#{Config::pathToDataCenter()}/TheSpeedOfLight.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end
 
    # TheSpeedOfLight::incrementLightSpeed()
    def self.incrementLightSpeed()
        speed = TheSpeedOfLight::getDaySpeedOfLight()
        data = {
            "date"  => CommonUtils::today(),
            "speed" => speed+0.1*rand
        }
        filepath = "#{Config::pathToDataCenter()}/TheSpeedOfLight.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end

    # TheSpeedOfLight::manageSpeedOfLight()
    def self.manageSpeedOfLight()
        unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone())
        timeToMidnight = unixtime - Time.new.to_i
        pendingTimeTodayInSeconds = GeneralTimeCommitments::pendingTimeTodayInHours()*3600
        if pendingTimeTodayInSeconds > timeToMidnight then
            TheSpeedOfLight::decrementLightSpeed()
        end
        if pendingTimeTodayInSeconds < (timeToMidnight-3600*2) then
            TheSpeedOfLight::incrementLightSpeed()
        end
    end
end
