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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataNetwork/DataNetwork.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Bank.rb"
=begin 
    Bank::put(uuid, weight)
    Bank::value(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

# -----------------------------------------------------------------------------

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
        DataNetwork::commitToDisk(spaceship)
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
                quark = DataNetwork::getOrNull(spaceship["cargo"]["quarkuuid"])
                return quark ? (" " + Quark::quarkToString(quark)) : " [could not find quark]"
            end
            raise "[Spaceships] error: CE8497BB"
        }
        engineFragment = lambda{|spaceship|
            uuid = spaceship["uuid"]

            engine = spaceship["engine"]

            if engine["type"] == "bank-account-3282f7af-ff9e-4c9b-84eb-306882c05f38" then
                return " (bank: #{(Spaceships::liveTotalTime(spaceship).to_f/3600).round(2)} hours)"
            end

            if engine["type"] == "on-going-weekly-commitment-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada" then
                return " (ratio: #{Spaceships::onGoingTimeRatio(spaceship)})"
            end

            if engine["type"] == "asap-managed-dd79cb44-5b70-4043-91e8-68c1a34e1fad" then
                return " (bank: #{(Bank::value(uuid).to_f/3600).round(2)} hours, time ratio: #{Spaceships::asapManagedBestTimeRatio(spaceship)})"
            end

            raise "[Spaceships] error: 46b84bdb"
        }
        typeAsUserFriendly = lambda {|type|
            return "bank-account" if type == "bank-account-3282f7af-ff9e-4c9b-84eb-306882c05f38"
            return "on-going-weekly-commitment" if type == "on-going-weekly-commitment-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada"
            return "asap-managed" if type == "asap-managed-dd79cb44-5b70-4043-91e8-68c1a34e1fad"
        }
        uuid = spaceship["uuid"]
        isRunning = Runner::isRunning?(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[spaceship] [#{typeAsUserFriendly.call(spaceship["engine"]["type"])}]#{cargoFragment.call(spaceship)}#{engineFragment.call(spaceship)}#{runningString}"
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
        opt1 = "bank managed until completion             ( bank-account-3282f7af-ff9e-4c9b-84eb-306882c05f38 )"
        opt5 = "asap managed                              ( asap-managed-dd79cb44-5b70-4043-91e8-68c1a34e1fad )"
        opt3 = "On-going time commitment without deadline ( on-going-weekly-commitment-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada )"

        options = [
            opt1,
            opt5,
            opt3,
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", options)
        return nil if option.nil?

        if option == opt3 then
            timeCommitmentInHoursPerWeek = LucilleCore::askQuestionAnswerAsString("time commitment in hours per week: ").to_f
            return {
                "type"                         => "on-going-weekly-commitment-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada",
                "referenceunixtime"           => Time.new.to_i,
                "timeCommitmentInHoursPerWeek" => timeCommitmentInHoursPerWeek
            }
        end
        if option == opt1 then
            return {
                "type" => "bank-account-3282f7af-ff9e-4c9b-84eb-306882c05f38"
            }
        end

        if option == opt5 then
            return {
                "type" => "asap-managed-dd79cb44-5b70-4043-91e8-68c1a34e1fad"
            }
        end
        nil
    end

    # Spaceships::spaceships()
    def self.spaceships()
        DataNetwork::objects("spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc")
    end

    # Spaceships::recargo(spaceship)
    def self.recargo(spaceship)
        cargo = Spaceships::makeCargoInteractivelyOrNull()
        return if cargo.nil?
        spaceship["cargo"] = cargo
        puts JSON.pretty_generate(spaceship)
        DataNetwork::commitToDisk(spaceship)
    end

    # Spaceships::reengine(spaceship)
    def self.reengine(spaceship)
        engine = Spaceships::makeEngineInteractivelyOrNull()
        return if engine.nil?
        spaceship["engine"] = engine
        puts JSON.pretty_generate(spaceship)
        DataNetwork::commitToDisk(spaceship)
    end

    # Spaceships::spaceshipDive(spaceship)
    def self.spaceshipDive(spaceship)
        loop {
            system("clear")
            puts Spaceships::toString(spaceship).green
            options = [
                "open",
                "start",
                "stop",
                "recargo",
                "reengine",
                "destroy",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                Spaceships::openCargo(spaceship)
                if !Spaceships::isRunning?(spaceship) and LucilleCore::askQuestionAnswerAsBoolean("Would you like to start ? ") then
                    Runner::start(spaceship["uuid"])
                end
            end
            if option == "start" then
                Spaceships::spaceshipStartSequence(spaceship)
            end
            if option == "stop" then
                Spaceships::spaceshipStopSequence(spaceship)
            end
            if option == "recargo" then
                Spaceships::recargo(spaceship)
            end
            if option == "reengine" then
                Spaceships::reengine(spaceship)
            end
            if option == "destroy" then
                Spaceships::spaceshipStopSequence(spaceship)
                Spaceships::spaceshipDestroySequence(spaceship)
            end
        }
    end

    # --------------------------------------------------------------------
    # Catalyst Object support

    # Spaceships::metric(spaceship)
    def self.metric(spaceship)
        uuid = spaceship["uuid"]

        engine = spaceship["engine"]

        return 1 if Spaceships::isRunning?(spaceship)

        # Lucille.txt
        return 0 if (spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" and IO.read("/Users/pascal/Desktop/Lucille.txt").strip.size == 0)
 
        if engine["type"] == "bank-account-3282f7af-ff9e-4c9b-84eb-306882c05f38" then
            timeBank = Bank::value(uuid)
            if timeBank >= 0 then
                return 0.20 + 0.2*Math.exp(-timeBank.to_f/3600)
            else
                return 0.70 + 0.1*(-timeBank).to_f/3600
            end
        end

        if engine["type"] == "on-going-weekly-commitment-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada" then
            if Ping::totalOverTimespan(uuid, 86400*7) >= engine["timeCommitmentInHoursPerWeek"]*86400 then
                return 0.30 - Spaceships::onGoingTimeRatio(spaceship)
            else
                return 0.70 - Spaceships::onGoingTimeRatio(spaceship)
            end
        end

        if engine["type"] == "asap-managed-dd79cb44-5b70-4043-91e8-68c1a34e1fad" then
            return 0.74 - 0.1*Spaceships::asapManagedBestTimeRatio(spaceship) - 0.1*Ping::totalOverTimespan(uuid, 86400).to_f/3600
        end

        raise "[Spaceships] error: 46b84bdb"
    end

    # Spaceships::isLate?(spaceship)
    def self.isLate?(spaceship)
        uuid = spaceship["uuid"]

        engine = spaceship["engine"]

        if engine["type"] == "bank-account-3282f7af-ff9e-4c9b-84eb-306882c05f38" then
            return Bank::value(uuid) < 0
        end

        if engine["type"] == "on-going-weekly-commitment-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada" then
            return Ping::totalOverTimespan(uuid, 86400*7) < engine["timeCommitmentInHoursPerWeek"]*86400
        end

        if engine["type"] == "asap-managed-dd79cb44-5b70-4043-91e8-68c1a34e1fad" then
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

        getBody = lambda{|spaceship|
            if spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" then
                if Spaceships::isRunning?(spaceship) then
                    return "#{Spaceships::toString(spaceship)}\n" + IO.read("/Users/pascal/Desktop/Lucille.txt").lines.first(10).join()
                else
                    return Spaceships::toString(spaceship)
                end
            end
            Spaceships::toString(spaceship)
        }

        {
            "uuid"      => uuid,
            "body"      => getBody.call(spaceship),
            "metric"    => Spaceships::metric(spaceship) + (uuid == "5c81927e-c4fb-4f8d-adae-228c346c8c7d" ? 0.06 : 0), # Bumping Guardian Work by 0.06 to match interface metric specification.
            "execute"   => lambda { Spaceships::spaceshipDive(spaceship) },
            "isFocus"   => Spaceships::isLate?(spaceship),
            "isRunning" => Spaceships::isRunning?(spaceship),
            "isRunningForLong" => Spaceships::isRunningForLong?(spaceship),
            "x-spaceship"      => spaceship
        }
    end

    # Spaceships::catalystObjects()
    def self.catalystObjects()
        objects = Spaceships::spaceships()
                    .map{|spaceship| Spaceships::spaceshipToCalalystObject(spaceship) }
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse
        return [] if objects.empty?
        if objects[0]["uuid"] == "1da6ff24-e81b-4257-b533-0a9e6a5bd1e9" then
            objects = objects.reject{|object| object["x-spaceship"]["engine"]["type"] == "asap-managed-dd79cb44-5b70-4043-91e8-68c1a34e1fad" and object["x-spaceship"]["uuid"] != "1da6ff24-e81b-4257-b533-0a9e6a5bd1e9" }
        end
        objects
    end

    # Spaceships::spaceshipStartSequence(spaceship)
    def self.spaceshipStartSequence(spaceship)
        return if Spaceships::isRunning?(spaceship)

        if spaceship["uuid"] == "5c81927e-c4fb-4f8d-adae-228c346c8c7d" then # Guardian Work
            Runner::start(spaceship["uuid"])
            return
        end

        if spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" then # Lucille.txt
            Runner::start(spaceship["uuid"])
            return
        end

        if spaceship["uuid"] == "1da6ff24-e81b-4257-b533-0a9e6a5bd1e9" then # asap-managed-killer
            Runner::start(spaceship["uuid"])
            return
        end

        Spaceships::openCargo(spaceship)

        if LucilleCore::askQuestionAnswerAsBoolean("Carry on with starting ? ", true) then
            Runner::start(spaceship["uuid"])
        else
            if LucilleCore::askQuestionAnswerAsBoolean("Destroy ? ", false) then
                Spaceships::spaceshipStopSequence(spaceship)
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
        puts "[spaceship] Putting #{timespan.round(2)} secs into Bank (#{spaceship["uuid"]})"
        Bank::put(spaceship["uuid"], timespan)
        puts "[spaceship] Putting #{timespan.round(2)} secs into Ping (#{spaceship["uuid"]})"
        Ping::put(spaceship["uuid"], timespan)

        return if spaceship["uuid"] == "5c81927e-c4fb-4f8d-adae-228c346c8c7d" # Guardian Work
        return if spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" # Lucille.txt
        return if spaceship["uuid"] == "1da6ff24-e81b-4257-b533-0a9e6a5bd1e9" # asap-managed-killer

        if LucilleCore::askQuestionAnswerAsBoolean("Destroy ? ", false) then
            DataNetwork::destroy(spaceship["uuid"])
        end
    end

    # Spaceships::spaceshipDestroySequence(spaceship)
    def self.spaceshipDestroySequence(spaceship)
        if spaceship["uuid"] == "5c81927e-c4fb-4f8d-adae-228c346c8c7d" then
            puts "You cannot destroy this one (Guardian Work)"
            LucilleCore::pressEnterToContinue()
            return
        end
        if spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" then
            puts "You cannot destroy this one (Lucille.txt)"
            LucilleCore::pressEnterToContinue()
            return
        end
        if spaceship["uuid"] == "1da6ff24-e81b-4257-b533-0a9e6a5bd1e9" then
            puts "You cannot destroy this one (asap-managed-killer)"
            LucilleCore::pressEnterToContinue()
            return
        end

        DataNetwork::destroy(spaceship["uuid"])
    end

    # Spaceships::openCargo(spaceship)
    def self.openCargo(spaceship)
        if spaceship["cargo"]["type"] == "quark" then
            quark = DataNetwork::getOrNull(spaceship["cargo"]["quarkuuid"])
            return if quark.nil?
            Quark::openQuark(quark)
        end
    end

    # --------------------------------------------------------------------
    # on-going-weekly-commitment-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada

    # Spaceships::onGoingTimeRatio(spaceship)
    def self.onGoingTimeRatio(spaceship)
        uuid = spaceship["uuid"]
        timedone = Ping::totalOverTimespan(uuid, 7*86400)
        trueTime = 7*86400
        timedone.to_f/trueTime
    end

    # --------------------------------------------------------------------
    # asap-managed-dd79cb44-5b70-4043-91e8-68c1a34e1fad

    # Spaceships::asapManagedBestTimeRatio(spaceship)
    def self.asapManagedBestTimeRatio(spaceship)
        uuid = spaceship["uuid"]
        (1..7)
            .map{|i|
                timedone = Ping::totalOverTimespan(uuid, i*86400)
                trueTime = i*86400
                timedone.to_f/trueTime
            }
            .max
    end
end

