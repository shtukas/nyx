
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

class Spaceships

    # Spaceships::issue(cargo, engine)
    def self.issue(cargo, engine)
        spaceship = {
            "uuid"      => SecureRandom.uuid,
            "nyxType"   => "spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc",
            "creationUnixtime" => Time.new.to_f,
            "cargo" => cargo,
            "engine"    => engine
        }
        Nyx::commitToDisk(spaceship)
        spaceship
    end

    # Spaceships::toString(spaceship)
    def self.toString(spaceship)
        cargoFragment = lambda{|spaceship|
            cargo = spaceship["cargo"]
            if cargo["type"] == "description" then
                return cargo["description"]
            end
            if cargo["type"] == "asteroid" then
                return KeyValueStore::getOrDefaultValue(nil, "11e20bd2-ee24-48f3-83bb-485ff9396800:#{cargo["uuid"]}")
            end
            if cargo["type"] == "quark" then
                quark = Nyx::getOrNull(spaceship["cargo"]["quarkuuid"])
                return quark ? Quark::quarkToString(quark) : "[could not find quark]"
            end
            raise "[Spaceships] error: CE8497BB"
        }
        engineFragment = lambda{|spaceship|
            uuid = spaceship["uuid"]

            engine = spaceship["engine"]

            if engine["type"] == "time-commitment-on-curve" then
                return "(completion: #{(100*Spaceships::timeCommitmentOnCurve_actualCompletionRatio(spaceship)).round(2)} %)"
            end

            if engine["type"] == "bank-account" then
                return "(bank: #{(Spaceships::liveTotalTime(spaceship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "bank-account-special-circumstances" then
                return "(bank: #{(Spaceships::liveTotalTime(spaceship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "time-commitment-indefinitely" then
                return "(bank account: #{(Spaceships::onGoingProjectAdaptedBankTime(spaceship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "arrow" then
                return "(#{"%.2f" % Spaceships::arrowPercentage(spaceship).round(2)}%)"
            end

            raise "[Spaceships] error: 46b84bdb"
        }

        uuid = spaceship["uuid"]
        isRunning = Runner::isRunning(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[spaceship] [#{spaceship["engine"]["type"]}] #{cargoFragment.call(spaceship)} #{engineFragment.call(spaceship)}"
    end

    # Spaceships::makeCargoInteractivelyOrNull()
    def self.makeCargoInteractivelyOrNull()
        options = [
            "description",
            "quark"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("cargo type", options)
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
            description = LucilleCore::askQuestionAnswerAsString("spaceship cargo description: ")
            return {
                "type"          => "quark",
                "description"   => description,
                "quarkuuid"     => quark["uuid"]
            }
        end
        nil
    end

    # Spaceships::makeEngineInteractivelyOrNull()
    def self.makeEngineInteractivelyOrNull()
        opt1 = "Bank managed until completion             ( bank-account )"
        opt2 = "Time commitment with deadline             ( time-commitment-on-curve )"
        opt3 = "On-going time commitment without deadline ( time-commitment-indefinitely )"
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
                "type"                         => "time-commitment-indefinitely",
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

    # Spaceships::openCargo(uuid)
    def self.openCargo(uuid)
        spaceship = Nyx::getOrNull(uuid)
        return if spaceship.nil?
        if spaceship["uuid"] == "cd112847-59f1-4e5a-83aa-1a6a3fcaa0f8" then
            # LucilleTxt
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/LucilleTxt/x-catalyst-objects-processing start")
        end
        if spaceship["cargo"]["type"] == "asteroid" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/x-catalyst-objects-processing start '#{spaceship["cargo"]["uuid"]}'")
        end
        if spaceship["cargo"]["type"] == "quark" then
            quark = Nyx::getOrNull(spaceship["cargo"]["quarkuuid"])
            return if quark.nil?
            Quark::openQuark(quark)
        end
    end

    # Spaceships::startSpaceship(uuid)
    def self.startSpaceship(uuid)
        spaceship = Nyx::getOrNull(uuid)
        return if spaceship.nil?
        Runner::start(uuid)
        Spaceships::openCargo(uuid)
    end

    # Spaceships::spaceships()
    def self.spaceships()
        Nyx::objects("spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc")
    end

    # --------------------------------------------------------------------
    # Catalyst Object support

    # Spaceships::metric(spaceship)
    def self.metric(spaceship)
        uuid = spaceship["uuid"]

        return 0.999 if Runner::isRunning(uuid)

        engine = spaceship["engine"]

        if engine["type"] == "time-commitment-on-curve" then
            timeBank = Bank::value(uuid)
            return -1 if (timeBank >= 3600*spaceship["engine"]["timeCommitmentInHours"])
            if Spaceships::timeCommitmentOnCurve_actualCompletionRatio(spaceship) < Spaceships::timeCommitmentOnCurve_idealCompletionRatio(spaceship) then
                return 0.76 + 0.001*(Spaceships::timeCommitmentOnCurve_idealCompletionRatio(spaceship) - Spaceships::timeCommitmentOnCurve_actualCompletionRatio(spaceship)).to_f
            else
                return 0.60 - 0.01*(Spaceships::timeCommitmentOnCurve_actualCompletionRatio(spaceship) - Spaceships::timeCommitmentOnCurve_idealCompletionRatio(spaceship)).to_f
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

        if engine["type"] == "time-commitment-indefinitely" then
            timeBank = Spaceships::onGoingProjectAdaptedBankTime(spaceship)
            if timeBank >= 0 then
                return 0.20 + 0.5*Math.exp(-timeBank.to_f/3600) # rapidly drop from 0.7 to 0.2
            else
                return 0.70 + 0.1*(-timeBank.to_f/86400)
            end
        end

        if engine["type"] == "arrow" then
            return 0.20 + 0.80*((Time.new.to_i - engine["startunixtime"]).to_f/86400).to_f/(0.90*engine["lengthInDays"])
        end

        raise "[Spaceships] error: 46b84bdb"
    end

    # Spaceships::liveRunTimeIfAny(spaceship)
    def self.liveRunTimeIfAny(spaceship)
        uuid = spaceship["uuid"]
        Runner::runTimeInSecondsOrNull(uuid) || 0
    end

    # Spaceships::liveTotalTime(spaceship)
    def self.liveTotalTime(spaceship)
        uuid = spaceship["uuid"]
        Bank::value(uuid) + Spaceships::liveRunTimeIfAny(spaceship)
    end

    # Spaceships::isDone?
    def self.isDone?(spaceship)
        uuid = spaceship["uuid"]
        engine = spaceship["engine"]
        if engine["type"] == "time-commitment-on-curve" then
            return (Spaceships::timeCommitmentOnCurve_actualCompletionRatio(spaceship) > Spaceships::timeCommitmentOnCurve_idealCompletionRatio(spaceship))
        end 
        if engine["type"] == "time-commitment-indefinitely" then
            return Spaceships::onGoingProjectAdaptedBankTime(spaceship)
        end 
        isDone = Spaceships::liveTotalTime(spaceship) > 0
    end

    # --------------------------------------------------------------------
    # time-commitment-on-curve

    # Spaceships::timeCommitmentOnCurve_idealCompletionRatio(spaceship)
    def self.timeCommitmentOnCurve_idealCompletionRatio(spaceship)
        raise "[error c2cb9a0f]" if spaceship["engine"]["type"] != "time-commitment-on-curve"
        periodInSeconds = 0.9*spaceship["engine"]["periodInDays"]*86400
                                        # We compute on the basis of completing in 90%% of the allocated time
        timeSinceStart = Time.new.to_i - spaceship["engine"]["startUnixtime"]
        [timeSinceStart.to_f/periodInSeconds, 1].min
    end

    # Spaceships::timeCommitmentOnCurve_idealTime(spaceship)
    def self.timeCommitmentOnCurve_idealTime(spaceship)
        raise "[error c2cb9a0f]" if spaceship["engine"]["type"] != "time-commitment-on-curve"
        Spaceships::timeCommitmentOnCurve_idealCompletionRatio(spaceship)*(3600*spaceship["engine"]["timeCommitmentInHours"])
    end

    # Spaceships::timeCommitmentOnCurve_actualCompletionRatio(spaceship)
    def self.timeCommitmentOnCurve_actualCompletionRatio(spaceship)
        raise "[error c2cb9a0f]" if spaceship["engine"]["type"] != "time-commitment-on-curve"
        Spaceships::liveTotalTime(spaceship).to_f/(3600*spaceship["engine"]["timeCommitmentInHours"])
    end

    # --------------------------------------------------------------------
    # time-commitment-indefinitely

    # Spaceships::onGoingProjectAdaptedBankTime(spaceship)
    def self.onGoingProjectAdaptedBankTime(spaceship)
        uuid = spaceship["uuid"]
        engine = spaceship["engine"]
        idealTimeInSecond = ((Time.new.to_i - engine["referencetUnixtime"]).to_f/(86400*7))*engine["timeCommitmentInHoursPerWeek"]*3600
        Spaceships::liveTotalTime(spaceship) - idealTimeInSecond
    end 

    # --------------------------------------------------------------------
    # arrow percentage

    # Spaceships::arrowPercentage(spaceship)
    def self.arrowPercentage(spaceship)
        engine = spaceship["engine"]
        timeSinceStart = Time.new.to_f - engine["startunixtime"]
        arrowTime = engine["lengthInDays"] * 86400
        ratio = timeSinceStart.to_f/arrowTime
        100*ratio
    end
end

