
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DailyTimes.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Runner.rb"
=begin 
    Runner::isRunning(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

class TimePods

    # TimePods::pathToPodsRepository()
    def self.pathToPodsRepository()
        "/Users/pascal/Galaxy/DataBank/Catalyst/TimePods/pods"
    end

    # TimePods::save(item)
    def self.save(item)
        filepath = "#{TimePods::pathToPodsRepository()}/#{item["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # TimePods::issue(passenger, engine)
    def self.issue(passenger, engine)
        pod = {
            "uuid"      => SecureRandom.uuid,
            "creationUnixtime" => Time.new.to_f,
            "passenger" => passenger,
            "engine"    => engine
        }
        TimePods::save(pod)
        pod
    end

    # TimePods::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{TimePods::pathToPodsRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TimePods::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{TimePods::pathToPodsRepository()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # TimePods::getTimePods()
    def self.getTimePods()
        Dir.entries(TimePods::pathToPodsRepository())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{TimePods::pathToPodsRepository()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
    end

    # TimePods::liveTime(pod)
    def self.liveTime(pod)
        uuid = pod["uuid"]
        x1 = Bank::total(uuid)
        x2 = Runner::runTimeInSecondsOrNull(uuid) || 0
        x1+x2
    end

    # TimePods::metric(pod)
    def self.metric(pod)
        uuid = pod["uuid"]

        return 0.999 if Runner::isRunning(uuid)

        engine = pod["engine"]

        if engine["type"] == "time-commitment-on-curve" then
            timeBank = Bank::total(uuid)
            return -1 if (timeBank >= 3600*pod["engine"]["timeCommitmentInHours"])
            if TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod) < TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod) then
                return 0.76 + 0.001*(TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod) - TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod)).to_f
            else
                return 0.60 - 0.01*(TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod) - TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod)).to_f
            end
        end

        if engine["type"] == "bank-account" then
            timeBank = Bank::total(uuid)
            if timeBank >= 0 then
                return 0.20 + 0.5*Math.exp(-timeBank.to_f/3600) # rapidly drop from 0.7 to 0.2
            else
                return 0.70 + 0.1*(-timeBank.to_f/86400)
            end
        end

        raise "[TimePods] error: 46b84bdb"

    end

    # TimePods::toStringPassengerFragment(pod)
    def self.toStringPassengerFragment(pod)
        passenger = pod["passenger"]
        if passenger["type"] == "description" then
            return "[timepod]"
        end
        if passenger["type"] == "special-circumstances" then
            return "[timepod] [special-circumstances] #{passenger["name"]}"
        end
        if passenger["type"] == "todo-item" then
            return "[timepod] #{KeyValueStore::getOrDefaultValue(nil, "11e20bd2-ee24-48f3-83bb-485ff9396800:#{passenger["uuid"]}", "[todo item]")}"
        end
        if passenger["type"] == "text" then
            return "[timepod] [text] #{passenger["description"]}"
        end
        raise "[TimePods] error: CE8497BB"
    end

    # TimePods::toStringEngineFragment(pod)
    def self.toStringEngineFragment(pod)

        uuid = pod["uuid"]

        engine = pod["engine"]

        if engine["type"] == "time-commitment-on-curve" then
            return "(completion: #{(100*TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod)).round(2)} %) (time commitment: #{engine["timeCommitmentInHours"]} hours, done: #{(TimePods::liveTime(pod).to_f/3600).round(2)} hours, ideal: #{(TimePods::timeCommitmentOnCurve_idealTime(pod).to_f/3600).round(2)} hours)"
        end

        if engine["type"] == "bank-account" then
            return "(bank account: #{(Bank::total(uuid).to_f/3600).round(2)} hours)"
        end

        raise "[TimePods] error: 46b84bdb"

    end

    # TimePods::toString(pod)
    def self.toString(pod)
        uuid = pod["uuid"]
        isRunning = Runner::isRunning(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "#{TimePods::toStringPassengerFragment(pod)} #{TimePods::toStringEngineFragment(pod)}#{runningString}"

    end

    # TimePods::timePodIsStillRelevant(pod)
    def self.timePodIsStillRelevant(pod)
        uuid = pod["uuid"]
        engine = pod["engine"]
        if engine["type"] == "time-commitment-on-curve" then
            return false if (Bank::total(uuid) >= 3600*pod["engine"]["timeCommitmentInHours"])
        end
        true
    end

    # TimePods::makePassengerOrNull()
    def self.makePassengerOrNull()
        options = [
            "text",
            "special-circumstances"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "text" then
            text = CatalystCommon::editTextUsingTextmate("")
            uuid = CatalystCommon::l22()
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/TimePods/text/#{uuid}.txt"
            File.open(filepath, "w"){|f| f.puts(text) }
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return {
                "type"        => "text",
                "uuid"        => uuid,
                "description" => description
            }
        end
        if option == "special-circumstances" then
            return {
                "type" => "special-circumstances",
                "name" => LucilleCore::askQuestionAnswerAsString("name: ")
            }
        end
        nil
    end

    # TimePods::makeEngineOrNull()
    def self.makeEngineOrNull()
        options = [
            "time-commitment-on-curve"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "time-commitment-on-curve" then
            periodInDays = LucilleCore::askQuestionAnswerAsString("timespan to deadline in days: ").to_f
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "time-commitment-on-curve",
                "startUnixtime"         => Time.new.to_i,
                "periodInDays"          => periodInDays,
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        nil
    end

    # --------------------------------------------------------------------

    # TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod)
    def self.timeCommitmentOnCurve_idealCompletionRatio(pod)
        raise "[error c2cb9a0f]" if pod["engine"]["type"] != "time-commitment-on-curve"
        periodInSeconds = 0.9*pod["engine"]["periodInDays"]*86400
                                        # We compute on the basis of completing in 90%% of the allocated time
        timeSinceStart = Time.new.to_i - pod["engine"]["startUnixtime"]
        [timeSinceStart.to_f/periodInSeconds, 1].min
    end

    # TimePods::timeCommitmentOnCurve_idealTime(pod)
    def self.timeCommitmentOnCurve_idealTime(pod)
        raise "[error c2cb9a0f]" if pod["engine"]["type"] != "time-commitment-on-curve"
        TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod)*(3600*pod["engine"]["timeCommitmentInHours"])
    end

    # TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod)
    def self.timeCommitmentOnCurve_actualCompletionRatio(pod)
        raise "[error c2cb9a0f]" if pod["engine"]["type"] != "time-commitment-on-curve"
        TimePods::liveTime(pod).to_f/(3600*pod["engine"]["timeCommitmentInHours"])
    end
end

