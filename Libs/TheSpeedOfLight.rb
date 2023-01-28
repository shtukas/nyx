
class TheSpeedOfLight

    # TheSpeedOfLight::getFilepathOrNull()
    def self.getFilepathOrNull()
        filepaths = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/TheSpeedOfLight")
            .select{|filepath| filepath[-5, 5] == ".json" }
        return nil if filepaths.empty?
        filepath = filepaths.first
        filepaths.drop(1).each{|fp| FileUtils.rm(fp) }
        filepath
    end

    # TheSpeedOfLight::getDaySpeedOfLight()
    def self.getDaySpeedOfLight()
        filepath = TheSpeedOfLight::getFilepathOrNull()
        return 1 if filepath.nil?
        return 1 if !File.exist?(filepath)
        data = JSON.parse(IO.read(filepath))
        # data: {date, value}
        return 1 if data["date"] != CommonUtils::today()
        data["speed"]
    end

    # TheSpeedOfLight::putData(data)
    def self.putData(data)
        filepath1 = TheSpeedOfLight::getFilepathOrNull()
        filepath2 = "#{Config::pathToDataCenter()}/Ops-Data/TheSpeedOfLight/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath2, "w"){|f| f.puts(JSON.pretty_generate(data)) }
        if filepath1 then
            FileUtils.rm(filepath1)
        end
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
    def self.performAdjustements(pendingTimeTodayInSeconds)
        unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone())
        timeToMidnightInSeconds = unixtime - Time.new.to_i
        if pendingTimeTodayInSeconds > (timeToMidnightInSeconds-3600*1) then
            TheSpeedOfLight::decrementLightSpeed()
            return
        end
        if pendingTimeTodayInSeconds < (timeToMidnightInSeconds-3600*2) then
            TheSpeedOfLight::incrementLightSpeed()
            return
        end
    end
end
