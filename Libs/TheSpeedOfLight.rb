
class TheSpeedOfLight
 
    # TheSpeedOfLight::getDaySpeedOfLightOrNull()
    def self.getDaySpeedOfLightOrNull()
        filepath = "#{Config::pathToDataCenter()}/NxWTimeCommitment-DayTimeLoads/speedOfLight.json"
        return nil if !File.exists?(filepath)
        data = JSON.parse(IO.read(filepath))
        # data: {date, value}
        return nil if data["date"] != CommonUtils::today()
        data["speed"]
    end
 
    # TheSpeedOfLight::issueSpeedOfLightForTheDay(timeInHours)
    def self.issueSpeedOfLightForTheDay(timeInHours)
        total = NxWTimeCommitments::pendingTimeInSeconds()
        speed = 
            if total > 0 then
                available = timeInHours
                available.to_f/total
            else
                1
            end
        data = { "date" => CommonUtils::today(), "speed" => speed }
        filepath = "#{Config::pathToDataCenter()}/NxWTimeCommitment-DayTimeLoads/speedOfLight.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
        speed
    end
 
    # TheSpeedOfLight::interactivelySetSpeedOfLightAndTimeloadsForTheDay()
    def self.interactivelySetSpeedOfLightAndTimeloadsForTheDay()
        timeInHours = LucilleCore::askQuestionAnswerAsString("Time available in hours: ").to_f
        TheSpeedOfLight::issueSpeedOfLightForTheDay(timeInHours)
    end
 
    # TheSpeedOfLight::decrementLightSpeed()
    def self.decrementLightSpeed()
        filepath = "#{Config::pathToDataCenter()}/NxWTimeCommitment-DayTimeLoads/speedOfLight.json"
        data = JSON.parse(IO.read(filepath))
        data["speed"] = [data["speed"] - 0.1, 0].max
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end
 
    # TheSpeedOfLight::incrementLightSpeed()
    def self.incrementLightSpeed()
        filepath = "#{Config::pathToDataCenter()}/NxWTimeCommitment-DayTimeLoads/speedOfLight.json"
        data = JSON.parse(IO.read(filepath))
        data["speed"] = data["speed"] + 0.1
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end
end
