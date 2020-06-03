
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx.rb"

class TimePods

    # TimePods::issue(passenger, engine)
    def self.issue(passenger, engine)
        pod = {
            "uuid"      => SecureRandom.uuid,
            "nyxType"   => "timepod-99a06996-dcad-49f5-a0ce-02365629e4fc",
            "creationUnixtime" => Time.new.to_f,
            "passenger" => passenger,
            "engine"    => engine
        }
        Nyx::commitToDisk(pod)
        pod
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

        if engine["type"] == "bank-account-special-circumstances" then
            timeBank = Bank::total(uuid)
            if timeBank >= 0 then
                return 0.20 + 0.5*Math.exp(-timeBank.to_f/3600) # rapidly drop from 0.7 to 0.2
            else
                return 0.70 + 0.1*(-timeBank.to_f/86400)
            end
        end

        if engine["type"] == "on-going-project" then
            timeBank = TimePods::onGoingProjectAdaptedBankTime(pod)
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
            return "[timepod] #{passenger["description"]}"
        end
        if passenger["type"] == "todo-item" then
            return "[timepod] #{KeyValueStore::getOrDefaultValue(nil, "11e20bd2-ee24-48f3-83bb-485ff9396800:#{passenger["uuid"]}", "[todo item]")}"
        end
        if passenger["type"] == "quark" then
            return "[timepod] [quark] #{passenger["description"]}"
        end
        raise "[TimePods] error: CE8497BB"
    end

    # TimePods::toStringEngineFragment(pod)
    def self.toStringEngineFragment(pod)

        uuid = pod["uuid"]

        engine = pod["engine"]

        if engine["type"] == "time-commitment-on-curve" then
            return "[time-commitment-on-curve] (completion: #{(100*TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod)).round(2)} %) (time commitment: #{engine["timeCommitmentInHours"]} hours, done: #{(TimePods::liveTime(pod).to_f/3600).round(2)} hours, ideal: #{(TimePods::timeCommitmentOnCurve_idealTime(pod).to_f/3600).round(2)} hours)"
        end

        if engine["type"] == "bank-account" then
            return "[bank-account] (bank account: #{(Bank::total(uuid).to_f/3600).round(2)} hours)"
        end

        if engine["type"] == "bank-account-special-circumstances" then
            return "[bank-account-special-circumstances] (bank account: #{(Bank::total(uuid).to_f/3600).round(2)} hours)"
        end

        if engine["type"] == "on-going-project" then
            return "[on-going-project] (bank account (adapted): #{(TimePods::onGoingProjectAdaptedBankTime(pod).to_f/3600).round(2)} hours)"
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

    # TimePods::makePassengerInteractivelyOrNull()
    def self.makePassengerInteractivelyOrNull()
        options = [
            "description",
            "quark"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("passenger type", options)
        return nil if option.nil?
        if option == "description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return {
                "type"        => "description",
                "description" => description
            }
        end
        if option == "quark" then
            quark = Quark::issueNewQuarkInteractivelyOrNull()
            return nil if quark.nil?
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return {
                "type"          => "quark",
                "description"   => description,
                "quarkuuid"     => quark["uuid"]
            }
        end
        nil
    end

    # TimePods::makeEngineInteractivelyOrNull()
    def self.makeEngineInteractivelyOrNull()
        options = [
            "time commitment with deadline",
            "bank managed until completion",
            "on-going time commitment without deadline"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", options)
        return nil if option.nil?
        if option == "time commitment with deadline" then
            periodInDays = LucilleCore::askQuestionAnswerAsString("timespan to deadline in days: ").to_f
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "time-commitment-on-curve",
                "startUnixtime"         => Time.new.to_i,
                "periodInDays"          => periodInDays,
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == "on-going time commitment without deadline" then
            timeCommitmentInHoursPerWeek = LucilleCore::askQuestionAnswerAsString("time commitment in hours per week: ").to_f
            return {
                "type"                         => "on-going-project",
                "referencetUnixtime"           => Time.new.to_i,
                "timeCommitmentInHoursPerWeek" => timeCommitmentInHoursPerWeek
            }
        end
        if option == "bank managed until completion" then
            return {
                "type" => "bank-account"
            }
        end
        nil
    end

    # TimePods::openPassenger(uuid)
    def self.openPassenger(uuid)
        pod = Nyx::getOrNull(uuid)
        return if pod.nil?
        if pod["uuid"] == "cd112847-59f1-4e5a-83aa-1a6a3fcaa0f8" then
            # LucilleTxt
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/LucilleTxt/x-catalyst-objects-processing start")
        end
        if pod["passenger"]["type"] == "todo-item" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/x-catalyst-objects-processing start '#{pod["passenger"]["uuid"]}'")
        end
        if pod["passenger"]["type"] == "quark" then
            point = Nyx::getOrNull(pod["passenger"]["quarkuuid"])
            return if point.nil?
            Quark::openQuark(point)
        end
    end

    # TimePods::startPod(uuid)
    def self.startPod(uuid)
        pod = Nyx::getOrNull(uuid)
        return if pod.nil?
        Runner::start(uuid)
        TimePods::openPassenger(uuid)
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

    # --------------------------------------------------------------------

    # TimePods::onGoingProjectAdaptedBankTime(pod)
    def self.onGoingProjectAdaptedBankTime(pod)
        uuid = pod["uuid"]
        engine = pod["engine"]
        timeBank = Bank::total(uuid)
        timeIdealInSecond = ((Time.new.to_i - engine["referencetUnixtime"]).to_f/(86400*7))*engine["timeCommitmentInHoursPerWeek"]*3600
        timeBank - timeIdealInSecond
    end 

end

