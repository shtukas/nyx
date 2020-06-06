
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
            quark = Nyx::getOrNull(pod["passenger"]["quarkuuid"])
            return "[timepod] #{passenger["description"]} #{quark ? Quark::quarkToString(quark) : "[could not find quark]"}"
        end
        raise "[TimePods] error: CE8497BB"
    end

    # TimePods::toStringEngineFragment(pod)
    def self.toStringEngineFragment(pod)

        uuid = pod["uuid"]

        engine = pod["engine"]

        if engine["type"] == "time-commitment-on-curve" then
            return "[time-commitment-on-curve] (completion: #{(100*TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod)).round(2)} %) (time commitment: #{engine["timeCommitmentInHours"]} hours, done: #{(TimePods::liveTotalTime(pod).to_f/3600).round(2)} hours, ideal: #{(TimePods::timeCommitmentOnCurve_idealTime(pod).to_f/3600).round(2)} hours)"
        end

        if engine["type"] == "bank-account" then
            return "[bank-account] (bank account: #{(Bank::value(uuid).to_f/3600).round(2)} hours)"
        end

        if engine["type"] == "bank-account-special-circumstances" then
            return "[bank-account-special-circumstances] (bank account: #{(Bank::value(uuid).to_f/3600).round(2)} hours)"
        end

        if engine["type"] == "on-going-project" then
            return "[on-going-project] (bank account (adapted): #{(TimePods::onGoingProjectAdaptedBankTime(pod).to_f/3600).round(2)} hours)"
        end

        if engine["type"] == "arrow" then
            timeSinceStart = Time.new.to_f - engine["startunixtime"]
            arrowTime = engine["lengthInDays"] * 86400
            ratio = timeSinceStart.to_f/arrowTime
            percentage = 100*ratio
            return "[arrow] (#{"%.2f" % percentage.round(2)}%)"
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
            description = LucilleCore::askQuestionAnswerAsString("timepod passenger description: ")
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
        opt1 = "Bank managed until completion             ( bank-account )"
        opt2 = "Time commitment with deadline             ( time-commitment-on-curve )"
        opt3 = "On-going time commitment without deadline ( on-going-project )"
        opt4 = "Arrow                                     ( arrow )"
        options = [
            opt1,
            opt2,
            opt3,
            opt4,
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", options)
        return nil if option.nil?
        if option == opt2 then
            periodInDays = LucilleCore::askQuestionAnswerAsString("timespan to deadline in days: ").to_f
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "time-commitment-on-curve",
                "startUnixtime"         => Time.new.to_i,
                "periodInDays"          => periodInDays,
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt3 then
            timeCommitmentInHoursPerWeek = LucilleCore::askQuestionAnswerAsString("time commitment in hours per week: ").to_f
            return {
                "type"                         => "on-going-project",
                "referencetUnixtime"           => Time.new.to_i,
                "timeCommitmentInHoursPerWeek" => timeCommitmentInHoursPerWeek
            }
        end
        if option == opt1 then
            return {
                "type" => "bank-account"
            }
        end
        if option == opt4 then
            lengthInDays = LucilleCore::askQuestionAnswerAsString("length in days: ").to_f
            return {
                "type"          => "arrow",
                "startunixtime" => Time.new.to_f,
                "lengthInDays"  => lengthInDays
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
            quark = Nyx::getOrNull(pod["passenger"]["quarkuuid"])
            return if quark.nil?
            Quark::openQuark(quark)
        end
    end

    # TimePods::startPod(uuid)
    def self.startPod(uuid)
        pod = Nyx::getOrNull(uuid)
        return if pod.nil?
        Runner::start(uuid)
        TimePods::openPassenger(uuid)
    end

    # TimePods::timepods()
    def self.timepods()
        Nyx::objects("timepod-99a06996-dcad-49f5-a0ce-02365629e4fc")
    end

    # --------------------------------------------------------------------
    # Catalyst Object support

    # TimePods::metric(pod)
    def self.metric(pod)
        uuid = pod["uuid"]

        return 0.999 if Runner::isRunning(uuid)

        engine = pod["engine"]

        if engine["type"] == "time-commitment-on-curve" then
            timeBank = Bank::value(uuid)
            return -1 if (timeBank >= 3600*pod["engine"]["timeCommitmentInHours"])
            if TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod) < TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod) then
                return 0.76 + 0.001*(TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod) - TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod)).to_f
            else
                return 0.60 - 0.01*(TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod) - TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod)).to_f
            end
        end

        if engine["type"] == "bank-account" then
            timeBank = Bank::value(uuid)
            if timeBank >= 0 then
                return 0.20 + 0.5*Math.exp(-timeBank.to_f/3600) # rapidly drop from 0.7 to 0.2
            else
                return 0.70 + 0.1*(-timeBank.to_f/86400)
            end
        end

        if engine["type"] == "bank-account-special-circumstances" then
            timeBank = Bank::value(uuid)
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

        if engine["type"] == "arrow" then
            return 0.20 + 0.80*((Time.new.to_i - engine["startunixtime"]).to_f/86400).to_f/(0.90*engine["lengthInDays"])
        end

        raise "[TimePods] error: 46b84bdb"
    end

    # TimePods::liveRunTimeIfAny(pod)
    def self.liveRunTimeIfAny(pod)
        uuid = pod["uuid"]
        Runner::runTimeInSecondsOrNull(uuid) || 0
    end

    # TimePods::liveTotalTime(pod)
    def self.liveTotalTime(pod)
        uuid = pod["uuid"]
        Bank::value(uuid) + TimePods::liveRunTimeIfAny(pod)
    end

    # TimePods::isDone?
    def self.isDone?(pod)
        uuid = pod["uuid"]
        engine = pod["engine"]
        if engine["type"] == "time-commitment-on-curve" then
            return (TimePods::timeCommitmentOnCurve_actualCompletionRatio(pod) > TimePods::timeCommitmentOnCurve_idealCompletionRatio(pod))
        end 
        if engine["type"] == "on-going-project" then
            return TimePods::onGoingProjectAdaptedBankTime(pod)
        end 
        isDone = TimePods::liveTotalTime(pod) > 0
    end

    # --------------------------------------------------------------------
    # time-commitment-on-curve

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
        TimePods::liveTotalTime(pod).to_f/(3600*pod["engine"]["timeCommitmentInHours"])
    end

    # --------------------------------------------------------------------
    # on-going-project

    # TimePods::onGoingProjectAdaptedBankTime(pod)
    def self.onGoingProjectAdaptedBankTime(pod)
        uuid = pod["uuid"]
        engine = pod["engine"]
        idealTimeInSecond = ((Time.new.to_i - engine["referencetUnixtime"]).to_f/(86400*7))*engine["timeCommitmentInHoursPerWeek"]*3600
        TimePods::liveTotalTime(pod) - idealTimeInSecond
    end 

end

