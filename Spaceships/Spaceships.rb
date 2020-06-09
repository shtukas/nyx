
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
    Runner::isRunning?(uuid)
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

    # Spaceships::issueSpaceShipInteractivelyOrNull()
    def self.issueSpaceShipInteractivelyOrNull()
        cargo = Spaceships::makeCargoInteractivelyOrNull()
        return if cargo.nil?
        engine = Spaceships::makeEngineInteractivelyOrNull()
        return if engine.nil?
        Spaceships::issue(cargo, engine)
    end

    # Spaceships::issue(cargo, engine)
    def self.issue(cargo, engine)
        spaceship = {
            "uuid"        => SecureRandom.uuid,
            "nyxType"     => "spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc",
            "creationUnixtime" => Time.new.to_f,
            "cargo"       => cargo,
            "engine"      => engine
        }
        Nyx::commitToDisk(spaceship)
        spaceship
    end

    # Spaceships::toString(spaceship)
    def self.toString(spaceship)
        cargoFragment = lambda{|spaceship|
            cargo = spaceship["cargo"]
            if cargo["type"] == "description" then
                return " " + cargo["description"]
            end
            if cargo["type"] == "quark" then
                quark = Nyx::getOrNull(spaceship["cargo"]["quarkuuid"])
                return quark ? (" " + Quark::quarkToString(quark)) : " [could not find quark]"
            end
            raise "[Spaceships] error: CE8497BB"
        }
        engineFragment = lambda{|spaceship|
            uuid = spaceship["uuid"]

            engine = spaceship["engine"]

            if engine["type"] == "bank-account" then
                return " (bank: #{(Spaceships::liveTotalTime(spaceship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "bank-account-special-circumstances" then
                return " (bank: #{(Spaceships::liveTotalTime(spaceship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "time-commitment-indefinitely" then
                return " (bank account: #{(Spaceships::onGoingProjectAdaptedBankTime(spaceship).to_f/3600).round(2)} hours)"
            end

            # Todo: decommission at first opportunity
            if engine["type"] == "arrow" then
                return " (#{"%.2f" % Spaceships::arrowPercentage(spaceship)}%)"
            end

            if engine["type"] == "asap-managed" then
                return " (#{Spaceships::timeRatio(spaceship)})"
            end

            raise "[Spaceships] error: 46b84bdb"
        }

        uuid = spaceship["uuid"]
        isRunning = Runner::isRunning?(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[spaceship] [#{spaceship["engine"]["type"]}]#{cargoFragment.call(spaceship)}#{engineFragment.call(spaceship)}#{runningString}"
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

        opt3 = "On-going time commitment without deadline ( time-commitment-indefinitely )"

        # Todo: decommission at first opportunity
        opt4 = "Arrow                                     ( arrow )"

        opt5 = "asap managed                              ( asap-managed )"
        
        options = [
            opt1,
            opt3,
            opt5,
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", options)
        return nil if option.nil?

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

        if option == opt5 then
            return {
                "type"          => "asap-managed",
                "startunixtime" => Time.new.to_f
            }
        end
        nil
    end

    # Spaceships::spaceships()
    def self.spaceships()
        Nyx::objects("spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc")
    end

    # Spaceships::spaceshipDive(spaceship)
    def self.spaceshipDive(spaceship)
        loop {
            system("clear")
            puts Spaceships::toString(spaceship).green
            options = [
                "open",
                "start",
                "re-cargo",
                "destroy",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                Spaceships::openCargo(spaceship)
            end
            if option == "start" then
                Runner::start(spaceship["uuid"])
                Spaceships::openCargo(spaceship)
            end
            if option == "re-cargo" then
                cargo = Spaceships::makeCargoInteractivelyOrNull()
                next if cargo.nil?
                spaceship["cargo"] = cargo
                puts JSON.pretty_generate(spaceship)
                Nyx::commitToDisk(spaceship)
            end
            if option == "destroy" then
                Nyx::destroy(spaceship["uuid"])
            end
        }
    end

    # --------------------------------------------------------------------
    # Catalyst Object support

    # Spaceships::metric(spaceship)
    def self.metric(spaceship)
        uuid = spaceship["uuid"]

        engine = spaceship["engine"]

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

        # Todo: decommission at first opportunity
        if engine["type"] == "arrow" then
            return 0.20 + 0.80*((Time.new.to_i - engine["startunixtime"]).to_f/86400).to_f/(0.90*engine["lengthInDays"])
        end

        if engine["type"] == "asap-managed" then
            timeBankAdjusted = Spaceships::timeRatio(spaceship)
            return 0.80 + Math.exp(-timeBankAdjusted).to_f/100
        end

        raise "[Spaceships] error: 46b84bdb"
    end

    # Spaceships::isLate?(spaceship)
    def self.isLate?(spaceship)
        uuid = spaceship["uuid"]

        engine = spaceship["engine"]

        if engine["type"] == "bank-account" then
            return Bank::value(uuid) < 0
        end

        if engine["type"] == "bank-account-special-circumstances" then
            return Bank::value(uuid) < 0
        end

        if engine["type"] == "time-commitment-indefinitely" then
            timeBank = Spaceships::onGoingProjectAdaptedBankTime(spaceship)
            return (timeBank < 0)
        end

        # Todo: decommission at first opportunity
        if engine["type"] == "arrow" then
            return true
        end

        if engine["type"] == "asap-managed" then
            return true
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

    # Spaceships::isRunning?(spaceship)
    def self.isRunning?(spaceship)
        Runner::isRunning?(spaceship["uuid"])
    end

    # Spaceships::isRunningForLong?(spaceship)
    def self.isRunningForLong?(spaceship)
        ( Runner::runTimeInSecondsOrNull(spaceship["uuid"]) || 0 ) > 3600
    end

    # Spaceships::spaceshipToCalalystObject(spaceship)
    def self.spaceshipToCalalystObject(spaceship)
        uuid = spaceship["uuid"]
        {
            "uuid"      => uuid,
            "body"      => Spaceships::toString(spaceship),
            "metric"    => Spaceships::metric(spaceship),
            "execute"   => lambda { Spaceships::execute(spaceship) },
            "isFocus"   => Spaceships::isLate?(spaceship),
            "isRunning" => Spaceships::isRunning?(spaceship),
            "isRunningForLong" => Spaceships::isRunningForLong?(spaceship),
            "x-is-spaceship"   => true,
            "x-spaceship"      => spaceship
        }
    end

    # Spaceships::catalystObjects()
    def self.catalystObjects()
        Spaceships::spaceships()
            .map{|spaceship| Spaceships::spaceshipToCalalystObject(spaceship) }
    end

    # Spaceships::spaceshipStartSequence(spaceship)
    def self.spaceshipStartSequence(spaceship)
        return if Spaceships::isRunning?(spaceship)
        Spaceships::openCargo(spaceship)
        if LucilleCore::askQuestionAnswerAsBoolean("Carry on with starting ? ", true) then
            Runner::start(spaceship["uuid"])
        else
            if LucilleCore::askQuestionAnswerAsBoolean("Destroy ? ", false) then
                Spaceships::spaceshipDestroySequence(spaceship)
            else
                puts "Hidding this item by one hour"
                DoNotShowUntil::setUnixtime(spaceship["uuid"], Time.new.to_i+3600)
            end
        end
    end

    # Spaceships::spaceshipStopSequence(spaceship)
    def self.spaceshipStopSequence(spaceship)
        return if !Spaceships::isRunning?(spaceship)
        timespan = Runner::stop(spaceship["uuid"])
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        puts "[spaceship] Bank: putting #{timespan.round(2)} secs into spaceship (#{spaceship["uuid"]})"
        Bank::put(spaceship["uuid"], timespan)
    end

    # Spaceships::spaceshipDestroySequence(spaceship)
    def self.spaceshipDestroySequence(spaceship)
        if spaceship["uuid"] == "5c81927e-c4fb-4f8d-adae-228c346c8c7d" then
            puts "You cannot destroy this one (Guardian Work)"
            LucilleCore::pressEnterToContinue()
            return
        end
        Spaceships::spaceshipStopSequence(spaceship)
        Nyx::destroy(spaceship["uuid"])
    end

    # Spaceships::execute(spaceship)
    def self.execute(spaceship)
        puts Spaceships::toString(spaceship)
        options = ["start", "open", "stop", "dive", "destroy"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return if option.nil?
        if option == "start" then
            Spaceships::spaceshipStartSequence(spaceship)
        end
        if option == "open" then
            Spaceships::openCargo(spaceship)
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to start ? ") then
                Runner::start(spaceship["uuid"])
            end
        end
        if option == "stop" then
            Spaceships::spaceshipStopSequence(spaceship)
        end
        if option == "dive" then
            Spaceships::spaceshipDive(spaceship)
        end
        if option == "destroy" then
            Spaceships::spaceshipDestroySequence(spaceship)
        end
    end

    # Spaceships::openCargo(spaceship)
    def self.openCargo(spaceship)
        if spaceship["cargo"]["type"] == "quark" then
            quark = Nyx::getOrNull(spaceship["cargo"]["quarkuuid"])
            return if quark.nil?
            Quark::openQuark(quark)
        end
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
    # arrow

    # Spaceships::arrowPercentage(spaceship)
    def self.arrowPercentage(spaceship)
        engine = spaceship["engine"]
        timeSinceStart = Time.new.to_f - engine["startunixtime"]
        arrowTime = engine["lengthInDays"] * 86400
        ratio = timeSinceStart.to_f/arrowTime
        100*ratio
    end

    # --------------------------------------------------------------------
    # asap-managed

    # Spaceships::timeRatio(spaceship)
    def self.timeRatio(spaceship)
        uuid = spaceship["uuid"]
        engine = spaceship["engine"]
        timeBank = Bank::value(uuid)
        timeBank.to_f/(Time.new.to_i - engine["startunixtime"])
    end
end

