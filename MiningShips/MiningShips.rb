
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

class MiningShips

    # MiningShips::issue(cargo, engine)
    def self.issue(cargo, engine)
        miningship = {
            "uuid"      => SecureRandom.uuid,
            "nyxType"   => "miningship-99a06996-dcad-49f5-a0ce-02365629e4fc",
            "creationUnixtime" => Time.new.to_f,
            "cargo" => cargo,
            "engine"    => engine
        }
        Nyx::commitToDisk(miningship)
        miningship
    end

    # MiningShips::toString(miningship)
    def self.toString(miningship)
        cargoFragment = lambda{|miningship|
            cargo = miningship["cargo"]
            if cargo["type"] == "description" then
                return " " + cargo["description"]
            end
            if cargo["type"] == "asteroid" then
                return " " + KeyValueStore::getOrDefaultValue(nil, "11e20bd2-ee24-48f3-83bb-485ff9396800:#{cargo["uuid"]}")
            end
            if cargo["type"] == "quark" then
                return (" " + miningship["description"]) if miningship["description"]
                quark = Nyx::getOrNull(miningship["cargo"]["quarkuuid"])
                return quark ? (" " + Quark::quarkToString(quark)) : " [could not find quark]"
            end
            raise "[MiningShips] error: CE8497BB"
        }
        engineFragment = lambda{|miningship|
            uuid = miningship["uuid"]

            engine = miningship["engine"]

            if engine["type"] == "time-commitment-on-curve" then
                return " (completion: #{(100*MiningShips::timeCommitmentOnCurve_actualCompletionRatio(miningship)).round(2)} %)"
            end

            if engine["type"] == "bank-account" then
                return " (bank: #{(MiningShips::liveTotalTime(miningship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "bank-account-special-circumstances" then
                return " (bank: #{(MiningShips::liveTotalTime(miningship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "time-commitment-indefinitely" then
                return " (bank account: #{(MiningShips::onGoingProjectAdaptedBankTime(miningship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "arrow" then
                return " (#{"%.2f" % MiningShips::arrowPercentage(miningship).round(2)}%)"
            end

            raise "[MiningShips] error: 46b84bdb"
        }

        uuid = miningship["uuid"]
        isRunning = Runner::isRunning(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[miningship] [#{miningship["engine"]["type"]}]#{cargoFragment.call(miningship)}#{engineFragment.call(miningship)}"
    end

    # MiningShips::makeCargoInteractivelyOrNull()
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
            description = LucilleCore::askQuestionAnswerAsString("miningship cargo description: ")
            return {
                "type"          => "quark",
                "description"   => description,
                "quarkuuid"     => quark["uuid"]
            }
        end
        nil
    end

    # MiningShips::makeEngineInteractivelyOrNull()
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

    # MiningShips::openCargo(uuid)
    def self.openCargo(uuid)
        miningship = Nyx::getOrNull(uuid)
        return if miningship.nil?
        if miningship["uuid"] == "cd112847-59f1-4e5a-83aa-1a6a3fcaa0f8" then
            # LucilleTxt
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/LucilleTxt/x-catalyst-objects-processing start")
        end
        if miningship["cargo"]["type"] == "asteroid" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/x-catalyst-objects-processing start '#{miningship["cargo"]["uuid"]}'")
        end
        if miningship["cargo"]["type"] == "quark" then
            quark = Nyx::getOrNull(miningship["cargo"]["quarkuuid"])
            return if quark.nil?
            Quark::openQuark(quark)
        end
    end

    # MiningShips::startMiningShip(uuid)
    def self.startMiningShip(uuid)
        miningship = Nyx::getOrNull(uuid)
        return if miningship.nil?
        Runner::start(uuid)
        MiningShips::openCargo(uuid)
    end

    # MiningShips::miningships()
    def self.miningships()
        Nyx::objects("miningship-99a06996-dcad-49f5-a0ce-02365629e4fc")
    end

    # --------------------------------------------------------------------
    # Catalyst Object support

    # MiningShips::metric(miningship)
    def self.metric(miningship)
        uuid = miningship["uuid"]

        return 0.999 if Runner::isRunning(uuid)

        engine = miningship["engine"]

        if engine["type"] == "time-commitment-on-curve" then
            timeBank = Bank::value(uuid)
            return -1 if (timeBank >= 3600*miningship["engine"]["timeCommitmentInHours"])
            if MiningShips::timeCommitmentOnCurve_actualCompletionRatio(miningship) < MiningShips::timeCommitmentOnCurve_idealCompletionRatio(miningship) then
                return 0.76 + 0.001*(MiningShips::timeCommitmentOnCurve_idealCompletionRatio(miningship) - MiningShips::timeCommitmentOnCurve_actualCompletionRatio(miningship)).to_f
            else
                return 0.60 - 0.01*(MiningShips::timeCommitmentOnCurve_actualCompletionRatio(miningship) - MiningShips::timeCommitmentOnCurve_idealCompletionRatio(miningship)).to_f
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
            timeBank = MiningShips::onGoingProjectAdaptedBankTime(miningship)
            if timeBank >= 0 then
                return 0.20 + 0.5*Math.exp(-timeBank.to_f/3600) # rapidly drop from 0.7 to 0.2
            else
                return 0.70 + 0.1*(-timeBank.to_f/86400)
            end
        end

        if engine["type"] == "arrow" then
            return 0.20 + 0.80*((Time.new.to_i - engine["startunixtime"]).to_f/86400).to_f/(0.90*engine["lengthInDays"])
        end

        raise "[MiningShips] error: 46b84bdb"
    end

    # MiningShips::liveRunTimeIfAny(miningship)
    def self.liveRunTimeIfAny(miningship)
        uuid = miningship["uuid"]
        Runner::runTimeInSecondsOrNull(uuid) || 0
    end

    # MiningShips::liveTotalTime(miningship)
    def self.liveTotalTime(miningship)
        uuid = miningship["uuid"]
        Bank::value(uuid) + MiningShips::liveRunTimeIfAny(miningship)
    end

    # MiningShips::isDone?
    def self.isDone?(miningship)
        uuid = miningship["uuid"]
        engine = miningship["engine"]
        if engine["type"] == "time-commitment-on-curve" then
            return (MiningShips::timeCommitmentOnCurve_actualCompletionRatio(miningship) > MiningShips::timeCommitmentOnCurve_idealCompletionRatio(miningship))
        end 
        if engine["type"] == "time-commitment-indefinitely" then
            return MiningShips::onGoingProjectAdaptedBankTime(miningship)
        end 
        if engine["type"] == "arrow" then
            return false
        end 
        isDone = MiningShips::liveTotalTime(miningship) > 0
    end

    # --------------------------------------------------------------------
    # time-commitment-on-curve

    # MiningShips::timeCommitmentOnCurve_idealCompletionRatio(miningship)
    def self.timeCommitmentOnCurve_idealCompletionRatio(miningship)
        raise "[error c2cb9a0f]" if miningship["engine"]["type"] != "time-commitment-on-curve"
        periodInSeconds = 0.9*miningship["engine"]["periodInDays"]*86400
                                        # We compute on the basis of completing in 90%% of the allocated time
        timeSinceStart = Time.new.to_i - miningship["engine"]["startUnixtime"]
        [timeSinceStart.to_f/periodInSeconds, 1].min
    end

    # MiningShips::timeCommitmentOnCurve_idealTime(miningship)
    def self.timeCommitmentOnCurve_idealTime(miningship)
        raise "[error c2cb9a0f]" if miningship["engine"]["type"] != "time-commitment-on-curve"
        MiningShips::timeCommitmentOnCurve_idealCompletionRatio(miningship)*(3600*miningship["engine"]["timeCommitmentInHours"])
    end

    # MiningShips::timeCommitmentOnCurve_actualCompletionRatio(miningship)
    def self.timeCommitmentOnCurve_actualCompletionRatio(miningship)
        raise "[error c2cb9a0f]" if miningship["engine"]["type"] != "time-commitment-on-curve"
        MiningShips::liveTotalTime(miningship).to_f/(3600*miningship["engine"]["timeCommitmentInHours"])
    end

    # --------------------------------------------------------------------
    # time-commitment-indefinitely

    # MiningShips::onGoingProjectAdaptedBankTime(miningship)
    def self.onGoingProjectAdaptedBankTime(miningship)
        uuid = miningship["uuid"]
        engine = miningship["engine"]
        idealTimeInSecond = ((Time.new.to_i - engine["referencetUnixtime"]).to_f/(86400*7))*engine["timeCommitmentInHoursPerWeek"]*3600
        MiningShips::liveTotalTime(miningship) - idealTimeInSecond
    end 

    # --------------------------------------------------------------------
    # arrow percentage

    # MiningShips::arrowPercentage(miningship)
    def self.arrowPercentage(miningship)
        engine = miningship["engine"]
        timeSinceStart = Time.new.to_f - engine["startunixtime"]
        arrowTime = engine["lengthInDays"] * 86400
        ratio = timeSinceStart.to_f/arrowTime
        100*ratio
    end
end

