# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Metrics.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/ProgrammableBooleans.rb"

# -----------------------------------------------------------------------------

class Asteroids

    # Asteroids::makePayloadInteractivelyOrNull()
    def self.makePayloadInteractivelyOrNull()
        options = [
            "description",
            "quark"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("payload type", options)
        return nil if option.nil?
        if option == "description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return {
                "type"        => "description",
                "description" => description
            }
        end
        if option == "quark" then
            quark = Quarks::issueNewQuarkInteractivelyOrNull()
            return nil if quark.nil?
            return {
                "type"      => "quark",
                "quarkuuid" => quark["uuid"]
            }
        end
        nil
    end

    # Asteroids::makeEngineInteractivelyOrNull()
    def self.makeEngineInteractivelyOrNull()
        opt1 = "deadline"
        opt2 = "single time commitment for a day"
        opt5 = "until completion"
        opt3 = "on-going time commitment"
        opt4 = "todo"

        options = [
            opt1,
            opt2,
            opt5,
            opt3,
            opt4
        ]

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", options)
        return nil if option.nil?
        if option == opt5 then
            return {
                "type" => "in-progress-until-completion-5b26f145-7ebf-4987-8091-2e78b16fa219"
            }
        end
        if option == opt2 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt3 then
            return {
                "type" => "in-progress-indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada"
            }
        end
        if option == opt3 then
            return {
                "type" => "todo-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
            }
        end
        if option == opt1 then
            timeToDeadlineInDays = LucilleCore::askQuestionAnswerAsString("Time to deadline in days: ").to_f
            return {
                "type"     => "in-progress-with-deadline-13641a9f-58db-4299-b322-65e1bbea82a2",
                "deadline" => Time.new.to_i + timeToDeadlineInDays*86400
            }
        end
        nil
    end

    # Asteroids::issueSpaceShipInteractivelyOrNull()
    def self.issueSpaceShipInteractivelyOrNull()
        payload = Asteroids::makePayloadInteractivelyOrNull()
        return if payload.nil?
        orbital = Asteroids::makeEngineInteractivelyOrNull()
        return if orbital.nil?
        Asteroids::issue(payload, orbital)
    end

    # Asteroids::issue(payload, orbital)
    def self.issue(payload, orbital)
        asteroid = {
            "uuid"     => CatalystCommon::l22(),
            "nyxType"  => "asteroid-99a06996-dcad-49f5-a0ce-02365629e4fc",
            "unixtime" => Time.new.to_f,
            "payload"  => payload,
            "orbital"  => orbital
        }
        NyxIO::commitToDisk(asteroid)
        asteroid
    end

    # Asteroids::issueStartshipTodoFromQuark(quark)
    def self.issueStartshipTodoFromQuark(quark)
        payload = {
            "type"      => "quark",
            "quarkuuid" => quark["uuid"]
        }
        orbital = {
            "type" => "todo-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        }
        Asteroids::issue(payload, orbital)
    end

    # Asteroids::asteroidToString(asteroid)
    def self.asteroidToString(asteroid)
        payloadFragment = lambda{|asteroid|
            payload = asteroid["payload"]
            if payload["type"] == "description" then
                return " " + payload["description"]
            end
            if payload["type"] == "quark" then
                quark = NyxIO::getOrNull(asteroid["payload"]["quarkuuid"])
                return quark ? (" " + Quarks::quarkToString(quark)) : " [could not find quark]"
            end
            raise "[Asteroids] error: CE8497BB"
        }
        orbitalFragment = lambda{|asteroid|
            uuid = asteroid["uuid"]
            if asteroid["orbital"]["type"] == "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32" then
                return " (commitment for a day: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, done: #{(Bank::value(uuid).to_f/3600).round(2)} hours)"
            end
            if asteroid["orbital"]["type"] == "in-progress-with-deadline-13641a9f-58db-4299-b322-65e1bbea82a2" then
                timeToDeadline = asteroid["orbital"]["deadline"] - Time.new.to_f
                return " (deadline: #{Time.at(asteroid["orbital"]["deadline"]).to_s}, #{(timeToDeadline.to_f/86400).round(2)} days)"
            end
            ""
        }
        typeAsUserFriendly = lambda {|type|
            return "⛵"  if type == "in-progress-until-completion-5b26f145-7ebf-4987-8091-2e78b16fa219"
            return "⏱️ " if type == "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32"
            return "🎡 "  if type == "in-progress-indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada"
            return "🗓️ "  if type == "in-progress-with-deadline-13641a9f-58db-4299-b322-65e1bbea82a2"
            return "🌇"  if type == "todo-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        }
        uuid = asteroid["uuid"]
        isRunning = Runner::isRunning?(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[asteroid] #{typeAsUserFriendly.call(asteroid["orbital"]["type"])}#{payloadFragment.call(asteroid)}#{orbitalFragment.call(asteroid)}#{runningString}"
    end

    # Asteroids::asteroids()
    def self.asteroids()
        NyxIO::objects("asteroid-99a06996-dcad-49f5-a0ce-02365629e4fc")
    end

    # Asteroids::getAsteroidsByTargetUUID(targetuuid)
    def self.getAsteroidsByTargetUUID(targetuuid)
        Asteroids::asteroids()
            .select{|asteroid| asteroid["payload"]["type"] == "quark" }
            .select{|asteroid| asteroid["payload"]["quarkuuid"] == targetuuid }
    end

    # Asteroids::repayload(asteroid)
    def self.repayload(asteroid)
        payload = Asteroids::makePayloadInteractivelyOrNull()
        return if payload.nil?
        asteroid["payload"] = payload
        puts JSON.pretty_generate(asteroid)
        NyxIO::commitToDisk(asteroid)
    end

    # Asteroids::reorbital(asteroid)
    def self.reorbital(asteroid)
        orbital = Asteroids::makeEngineInteractivelyOrNull()
        return if orbital.nil?
        asteroid["orbital"] = orbital
        puts JSON.pretty_generate(asteroid)
        NyxIO::commitToDisk(asteroid)
    end

    # Asteroids::asteroidDive(asteroid)
    def self.asteroidDive(asteroid)
        loop {
            system("clear")
            puts Asteroids::asteroidToString(asteroid).green
            puts "Bank      : #{Bank::value(asteroid["uuid"]).to_f/3600} hours"
            puts "Ping Day  : #{Ping::totalOverTimespan(asteroid["uuid"], 86400).to_f/3600} hours"
            puts "Ping Week : #{Ping::totalOverTimespan(asteroid["uuid"], 86400*7).to_f/3600} hours"
            options = [
                "open",
                "start",
                "stop",
                "repayload",
                "reorbital",
                "show json",
                "add time",
                "destroy",
            ]

            if asteroid["payload"]["type"] == "quark" then
                options << "quark (dive)"
            end

            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                Asteroids::openPayload(asteroid)
                if !Asteroids::isRunning?(asteroid) and LucilleCore::askQuestionAnswerAsBoolean("Would you like to start ? ", false) then
                    Runner::start(asteroid["uuid"])
                end
            end
            if option == "start" then
                Asteroids::asteroidStartSequence(asteroid)
            end
            if option == "stop" then
                Asteroids::asteroidStopSequence(asteroid)
            end
            if option == "repayload" then
                Asteroids::repayload(asteroid)
            end
            if option == "reorbital" then
                Asteroids::reorbital(asteroid)
            end
            if option == "show json" then
                puts JSON.pretty_generate(asteroid)
                LucilleCore::pressEnterToContinue()
            end
            if option == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                Asteroids::addTimeToAsteroid(asteroid, timeInHours*3600)
            end
            if option == "quark (dive)" then
                quarkuuid = asteroid["payload"]["quarkuuid"]
                quark = Quarks::getOrNull(quarkuuid)
                return if quark.nil?
                Quarks::quarkDive(quark)
            end
            if option == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this starship ? ") then
                    Asteroids::asteroidStopSequence(asteroid)
                    Asteroids::asteroidDestroySequence(asteroid)
                end
                return
            end
        }
    end

    # Asteroids::shiftNX71(unixtime)
    def self.shiftNX71(unixtime)
        # "Unixtime To Decreasing Metric Shift Normalised To Interval Zero One"
        unixtimeAtNextMidnightIsh = (1+Time.now.utc.to_i/86400) * 86400
        positiveDatationInMonths = unixtimeAtNextMidnightIsh-unixtime
        1 - positiveDatationInMonths.to_f/(86400*365*100)
    end

    # Asteroids::metric(asteroid)
    def self.metric(asteroid)
        uuid = asteroid["uuid"]

        orbital = asteroid["orbital"]

        return 1 if Asteroids::isRunning?(asteroid)

        if orbital["type"] == "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32" then
            return 0.70 - 0.1*Ping::bestTimeRatioOverPeriod7Samples(uuid, 86400)
        end

        if orbital["type"] == "in-progress-with-deadline-13641a9f-58db-4299-b322-65e1bbea82a2" then
            uuid = asteroid["uuid"]
            return Metrics::metricNX1RequiredValueAndThenFall(0.68, Ping::totalToday(uuid), 0.5*3600) - 0.1*Ping::bestTimeRatioOverPeriod7Samples(uuid, 86400*7)
        end

        if orbital["type"] == "in-progress-until-completion-5b26f145-7ebf-4987-8091-2e78b16fa219" then
            uuid = asteroid["uuid"]
            return Metrics::metricNX1RequiredValueAndThenFall(0.66, Ping::totalToday(uuid), 3600) - 0.1*Ping::bestTimeRatioOverPeriod7Samples(uuid, 86400*7)
        end
 
        if orbital["type"] == "in-progress-indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada" then
            uuid = asteroid["uuid"]
            return Metrics::metricNX1RequiredValueAndThenFall(0.64, Ping::totalToday(uuid), 0.5*3600) - 0.1*Ping::bestTimeRatioOverPeriod7Samples(uuid, 86400*7)
        end

        if orbital["type"] == "todo-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            return 0.49 - 0.01*Asteroids::shiftNX71(asteroid["unixtime"])
        end

        raise "[Asteroids] error: 46b84bdb"
    end

    # Asteroids::isLate?(asteroid)
    def self.isLate?(asteroid)
        uuid = asteroid["uuid"]

        orbital = asteroid["orbital"]

        if orbital["type"] == "in-progress-until-completion-5b26f145-7ebf-4987-8091-2e78b16fa219" then
            return true
        end

        if orbital["type"] == "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32" then
            return false
        end

        if orbital["type"] == "in-progress-indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada" then
            return false
        end

        if orbital["type"] == "in-progress-with-deadline-13641a9f-58db-4299-b322-65e1bbea82a2" then
            return true
        end

        if orbital["type"] == "todo-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            return false
        end

        raise "[Asteroids] error: 46b84bdb"
    end

    # Asteroids::runTimeIfAny(asteroid)
    def self.runTimeIfAny(asteroid)
        uuid = asteroid["uuid"]
        Runner::runTimeInSecondsOrNull(uuid) || 0
    end

    # Asteroids::bankValueLive(asteroid)
    def self.bankValueLive(asteroid)
        uuid = asteroid["uuid"]
        Bank::value(uuid) + Asteroids::runTimeIfAny(asteroid)
    end

    # Asteroids::isRunning?(asteroid)
    def self.isRunning?(asteroid)
        Runner::isRunning?(asteroid["uuid"])
    end

    # Asteroids::isRunningForLong?(asteroid)
    def self.isRunningForLong?(asteroid)
        uuid = asteroid["uuid"]
        orbital = asteroid["orbital"]
 
        if orbital["type"] == "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32" then
            if Asteroids::bankValueLive(asteroid)  >= orbital["timeCommitmentInHours"]*3600 then
                return true
            end
        end

        ( Runner::runTimeInSecondsOrNull(asteroid["uuid"]) || 0 ) > 3600
    end

    # Asteroids::asteroidToCalalystObject(asteroid)
    def self.asteroidToCalalystObject(asteroid)
        uuid = asteroid["uuid"]

        {
            "uuid"      => uuid,
            "body"      => Asteroids::asteroidToString(asteroid),
            "metric"    => Asteroids::metric(asteroid),
            "execute"   => lambda { Asteroids::asteroidDive(asteroid) },
            "isFocus"   => Asteroids::isLate?(asteroid),
            "isRunning" => Asteroids::isRunning?(asteroid),
            "isRunningForLong" => Asteroids::isRunningForLong?(asteroid),
            "x-asteroid"      => asteroid
        }
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()

        if [1,2,3,4,5].include?(Time.new.wday) and !KeyValueStore::flagIsTrue(nil, "f65f092d-4626-4aa7-bb77-9eae0592910c:#{Time.new.to_s[0, 10]}") then
            Asteroids::issue({
                    "type"        => "description",
                    "description" => "Daily Guardian Work"
                }, {
                "type"                  => "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32",
                "timeCommitmentInHours" => 6,
            })
            KeyValueStore::setFlagTrue(nil, "f65f092d-4626-4aa7-bb77-9eae0592910c:#{Time.new.to_s[0, 10]}")
        end

        if [1,2,3,4,5,6].include?(Time.new.wday) and !KeyValueStore::flagIsTrue(nil, "3f0445e5-0a83-49ba-b4c0-0f081ef05feb:#{Time.new.to_s[0, 10]}") then
            Asteroids::issue({
                    "type"        => "description",
                    "description" => "Lucille.txt"
                }, {
                "type"                  => "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32",
                "timeCommitmentInHours" => 1,
            })
            KeyValueStore::setFlagTrue(nil, "3f0445e5-0a83-49ba-b4c0-0f081ef05feb:#{Time.new.to_s[0, 10]}")
        end

        Asteroids::asteroids()
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

    # Asteroids::cacheWorkingUUIDs()
    def self.cacheWorkingUUIDs()
        uuids = Asteroids::catalystObjects()
                    .first(64)
                    .map{|object| object["uuid"] }
        KeyValueStore::set(nil, "af2c7ba1-c137-4303-b0c8-5127cecb3b06", JSON.generate(uuids))

        uuids = Asteroids::asteroids()
                    .select{|asteroid| asteroid["orbital"]["type"] == "in-progress-with-deadline-13641a9f-58db-4299-b322-65e1bbea82a2" }
                    .map{|asteroid| asteroid["uuid"] }
        KeyValueStore::set(nil, "66ecd959-967c-4c5e-b437-c07169f3d3b1", JSON.generate(uuids))
    end

    # Asteroids::cacheWorkingUUIDsIfNeeded()
    def self.cacheWorkingUUIDsIfNeeded()
        if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("5a56e54d-c24d-4ae9-a8ae-f95729bd010f", 1200) then
            Asteroids::cacheWorkingUUIDs()
        end
    end

    # Asteroids::catalystObjectsFast()
    def self.catalystObjectsFast()
        Asteroids::cacheWorkingUUIDsIfNeeded()
        uuids = KeyValueStore::getOrDefaultValue(nil, "af2c7ba1-c137-4303-b0c8-5127cecb3b06", "[]")
        JSON.parse(uuids)
            .map{|uuid| NyxIO::getOrNull(uuid) }
            .compact
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
    end

    # Asteroids::asteroidStartSequence(asteroid)
    def self.asteroidStartSequence(asteroid)
        return if Asteroids::isRunning?(asteroid)

        uuid = asteroid["uuid"]
        orbital = asteroid["orbital"]

        if orbital["type"] == "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32" then
            if Bank::value(uuid) >= orbital["timeCommitmentInHours"]*3600 then
                puts "time commitment asteroid is completed, destroying it..."
                LucilleCore::pressEnterToContinue()
                Asteroids::asteroidDestroySequence(asteroid)
                return
            end
        end

        Runner::start(asteroid["uuid"])

        if asteroid["payload"]["type"] == "quark" then
            Asteroids::openPayload(asteroid)
        end
    end

    # Asteroids::addTimeToAsteroid(asteroid, timespanInSeconds)
    def self.addTimeToAsteroid(asteroid, timespanInSeconds)
        Bank::put(asteroid["uuid"], timespanInSeconds)
        Ping::put(asteroid["uuid"], timespanInSeconds)
        Ping::put("b14be1e3-ff3f-457b-8595-685db7b98a9d", timespanInSeconds)
    end

    # Asteroids::asteroidStopSequence(asteroid)
    def self.asteroidStopSequence(asteroid)
        return if !Asteroids::isRunning?(asteroid)
        timespan = Runner::stop(asteroid["uuid"])
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running

        Asteroids::addTimeToAsteroid(asteroid, timespan)

        orbital = asteroid["orbital"]

        if orbital["type"] == "in-progress-until-completion-5b26f145-7ebf-4987-8091-2e78b16fa219" then
            if LucilleCore::askQuestionAnswerAsBoolean("Done ? ", false) then
                Asteroids::asteroidDestroySequence(asteroid)
            end
        end

        if orbital["type"] == "in-progress-time-commitment-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32" then
            if Bank::value(asteroid["uuid"]) >= orbital["timeCommitmentInHours"]*3600 then
                puts "time commitment asteroid is completed, destroying it..."
                LucilleCore::pressEnterToContinue()
                Asteroids::asteroidDestroySequence(asteroid)
            end
        end
    end

    # Asteroids::asteroidDestructionQuarkHandling(quark)
    def self.asteroidDestructionQuarkHandling(quark)
        if LucilleCore::askQuestionAnswerAsBoolean("Retain quark ? ") then
            quark = Quarks::ensureQuarkDescription(quark)
            Quarks::ensureAtLeastOneQuarkTags(quark)
            Quarks::ensureAtLeastOneQuarkCliques(quark)
        else
            Quarks::destroyQuarkByUUID(quark["uuid"])
        end
    end

    # Asteroids::asteroidDestroySequence(asteroid)
    def self.asteroidDestroySequence(asteroid)
        Asteroids::asteroidStopSequence(asteroid)
        if asteroid["payload"]["type"] == "quark" then
            quark = NyxIO::getOrNull(asteroid["payload"]["quarkuuid"])
            if !quark.nil? then
                Asteroids::asteroidDestructionQuarkHandling(quark)
            end
        end
        NyxIO::destroy(asteroid["uuid"])
    end

    # Asteroids::openPayload(asteroid)
    def self.openPayload(asteroid)
        if asteroid["payload"]["type"] == "quark" then
            quark = NyxIO::getOrNull(asteroid["payload"]["quarkuuid"])
            return if quark.nil?
            Quarks::openQuark(quark)
        end
    end
end

