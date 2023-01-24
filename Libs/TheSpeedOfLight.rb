
class TheSpeedOfLight

    # TheSpeedOfLight::getFilepath()
    def self.getFilepath()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/TheSpeedOfLight")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .first
    end

    # TheSpeedOfLight::getDaySpeedOfLight()
    def self.getDaySpeedOfLight()
        filepath = TheSpeedOfLight::getFilepath()
        return 1 if !File.exists?(filepath)
        data = JSON.parse(IO.read(filepath))
        # data: {date, value}
        return 1 if data["date"] != CommonUtils::today()
        data["speed"]
    end

    # TheSpeedOfLight::putData(data)
    def self.putData(data)
        filepath1 = TheSpeedOfLight::getFilepath()
        filepath2 = "#{Config::pathToDataCenter()}/TheSpeedOfLight/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath2, "w"){|f| f.puts(JSON.pretty_generate(data)) }
        FileUtils.rm(filepath1)
    end

    # TheSpeedOfLight::decrementLightSpeed()
    def self.decrementLightSpeed()
        speed = TheSpeedOfLight::getDaySpeedOfLight()
        data = {
            "date"  => CommonUtils::today(),
            "speed" => [speed-0.1*rand, 0].max
        }
        TheSpeedOfLight::putData(data)
    end
 
    # TheSpeedOfLight::incrementLightSpeed()
    def self.incrementLightSpeed()
        speed = TheSpeedOfLight::getDaySpeedOfLight()
        data = {
            "date"  => CommonUtils::today(),
            "speed" => speed+0.1*rand
        }
        TheSpeedOfLight::putData(data)
    end


    # TheSpeedOfLight::performAdjustements(pendingTimeTodayInSeconds)
    def self.manageSpeedOfLight(pendingTimeTodayInSeconds)
        unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone())
        timeToMidnight = unixtime - Time.new.to_i
        if pendingTimeTodayInSeconds > (timeToMidnight-3600*1) then
            TheSpeedOfLight::decrementLightSpeed()
        end
        if pendingTimeTodayInSeconds < (timeToMidnight-3600*2) then
            TheSpeedOfLight::incrementLightSpeed()
        end
    end
end
