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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxGenericObjectInterface.rb"

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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx.v2/NyxSets.rb"

# -----------------------------------------------------------------------------

class Asteroids

    # Asteroids::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxSets::getObjectOrNull(uuid)
    end

    # Asteroids::commitToDisk(asteroid)
    def self.commitToDisk(asteroid)
        NyxSets::putObject(asteroid)
        $charlotte.incomingAsteroid(asteroid)
    end

    # Asteroids::makePayloadInteractivelyOrNull()
    def self.makePayloadInteractivelyOrNull()
        options = [
            "description",
            "quark",
            "clique"
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
        if option == "clique" then
            clique = Cliques::selectCliqueFromExistingCliquesOrNull()
            return nil if clique.nil?
            return {
                "type"       => "clique",
                "cliqueuuid" => clique["uuid"]
            }
        end
        nil
    end

    # Asteroids::makeOrbitalInteractivelyOrNull()
    def self.makeOrbitalInteractivelyOrNull()
        opt0 = "top priority"
        opt1 = "single day time commitment"
        opt2 = "repeating daily time commitment"
        opt3 = "on going until completion"
        opt4 = "indefinite"
        opt6 = "float to do today"
        opt7 = "open project in the background"
        opt5 = "todo"

        options = [
            opt0,
            opt1,
            opt2,
            opt3,
            opt4,
            opt6,
            opt7,
            opt5,
        ]

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", options)
        return nil if option.nil?
        if option == opt0 then
            return {
                "type"                  => "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3"
            }
        end
        if option == opt1 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "singleton-time-commitment-7c67cb4f-77e0-4fd",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt2 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "repeating-daily-time-commitment-8123956c-05",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt3 then
            return {
                "type"                  => "on-going-until-completion-5b26f145-7ebf-498"
            }
        end
        if option == opt4 then
            return {
                "type"                  => "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2"
            }
        end
        if option == opt5 then
            return {
                "type"                  => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
            }
        end
        if option == opt6 then
            return {
                "type"                  => "float-to-do-today-b0d902a8-3184-45fa-9808-1"
            }
        end
        if option == opt7 then
            return {
                "type"                  => "open-project-in-the-background-b458aa91-6e1"
            }
        end
        nil
    end

    # Asteroids::issueAsteroidInteractivelyOrNull()
    def self.issueAsteroidInteractivelyOrNull()
        payload = Asteroids::makePayloadInteractivelyOrNull()
        return if payload.nil?
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        Asteroids::issue(payload, orbital)
    end

    # Asteroids::issue(payload, orbital)
    def self.issue(payload, orbital)
        asteroid = {
            "uuid"     => CatalystCommon::l22(),
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "payload"  => payload,
            "orbital"  => orbital
        }
        Asteroids::commitToDisk(asteroid)
        asteroid
    end

    # Asteroids::issueStartshipTodoFromQuark(quark)
    def self.issueStartshipTodoFromQuark(quark)
        payload = {
            "type"      => "quark",
            "quarkuuid" => quark["uuid"]
        }
        orbital = {
            "type" => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
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
                quark = Quarks::getOrNull(asteroid["payload"]["quarkuuid"])
                return quark ? (" " + Quarks::quarkToString(quark)) : " [could not find quark]"
            end
            if payload["type"] == "clique" then
                clique = Cliques::getOrNull(asteroid["payload"]["cliqueuuid"])
                return clique ? (" " + Cliques::cliqueToString(clique)) : " [could not find clique]"
            end
            raise "[Asteroids] error: CE8497BB"
        }
        orbitalFragment = lambda{|asteroid|
            uuid = asteroid["uuid"]
            if asteroid["orbital"]["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
                return " (singleton: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, done: #{(Asteroids::bankValueLive(asteroid).to_f/3600).round(2)} hours)"
            end
            if asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
                return " (repeating daily: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, today: #{(Asteroids::pingTodayValueLive(asteroid).to_f/3600).round(2)} hours)"
            end
            if asteroid["orbital"]["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
                return " (indefinite: today: #{(Asteroids::pingTodayValueLive(asteroid).to_f/3600).round(2)} hours, #{(100*Asteroids::pingTodayValueLive(asteroid).to_f/1800).round(2)} %)"
            end
            ""
        }
        typeAsUserFriendly = lambda {|type|
            return "‼️ "  if type == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3"
            return "⏱️ " if type == "singleton-time-commitment-7c67cb4f-77e0-4fd"
            return "💫"  if type == "repeating-daily-time-commitment-8123956c-05"
            return "⛵"  if type == "on-going-until-completion-5b26f145-7ebf-498"
            return "⛲"  if type == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2"
            return "👩‍💻"  if type == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
            return "☀️ " if type == "float-to-do-today-b0d902a8-3184-45fa-9808-1"
            return "😴"  if type == "open-project-in-the-background-b458aa91-6e1"
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
        NyxSets::objects("b66318f4-2662-4621-a991-a6b966fb4398")
    end

    # Asteroids::getAsteroidsTypeQuarkByQuarkUUID(targetuuid)
    def self.getAsteroidsTypeQuarkByQuarkUUID(targetuuid)
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
        Asteroids::commitToDisk(asteroid)
    end

    # Asteroids::reorbital(asteroid)
    def self.reorbital(asteroid)
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        asteroid["orbital"] = orbital
        puts JSON.pretty_generate(asteroid)
        Asteroids::commitToDisk(asteroid)
    end

    # Asteroids::asteroidDive(asteroid)
    def self.asteroidDive(asteroid)
        loop {

            asteroid = Asteroids::getOrNull(asteroid["uuid"])
            return if asteroid.nil?

            system("clear")

            CatalystCommon::horizontalRule(false)

            puts Asteroids::asteroidToString(asteroid)
            puts "uuid: #{asteroid["uuid"]}"

            unixtime = DoNotShowUntil::getUnixtimeOrNull(asteroid["uuid"])
            if unixtime then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}"
            end

            CatalystCommon::horizontalRule(true)

            puts "Bank           : #{Bank::value(asteroid["uuid"]).to_f/3600} hours"
            puts "Ping 24 hours  : #{Ping::totalOverTimespan(asteroid["uuid"], 86400).to_f/3600} hours"
            puts "Ping 7 days    : #{Ping::totalOverTimespan(asteroid["uuid"], 86400*7).to_f/3600} hours"

            menuitems = LCoreMenuItemsNX1.new()

            CatalystCommon::horizontalRule(true)

            menuitems.item(
                "open",
                lambda {
                    Asteroids::openPayload(asteroid)
                    if !Asteroids::isRunning?(asteroid) and LucilleCore::askQuestionAnswerAsBoolean("Would you like to start ? ", false) then
                        Runner::start(asteroid["uuid"])
                    end
                }
            )

            menuitems.item(
                "start",
                lambda { Asteroids::asteroidStartSequence(asteroid) }
            )

            menuitems.item(
                "stop",
                lambda { Asteroids::asteroidStopSequence(asteroid) }
            )


            if asteroid["payload"]["type"] == "description" then
                menuitems.item(
                    "edit description",
                    lambda {
                        asteroid["payload"]["description"] = CatalystCommon::editTextUsingTextmate(asteroid["payload"]["description"]).strip
                        Asteroids::commitToDisk(asteroid)
                    }
                )
            end

            menuitems.item(
                "re-payload",
                lambda { Asteroids::repayload(asteroid) }
            )

            menuitems.item(
                "re-orbital",
                lambda { Asteroids::reorbital(asteroid) }
            )

            menuitems.item(
                "show json",
                lambda {
                    puts JSON.pretty_generate(asteroid)
                    LucilleCore::pressEnterToContinue()
                }
            )

            menuitems.item(
                "add time",
                lambda {
                    timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                    Asteroids::addTimeToAsteroid(asteroid, timeInHours*3600)
                }
            )

            if asteroid["payload"]["type"] == "quark" then
                menuitems.item(
                    "quark (dive)",
                    lambda {
                        quarkuuid = asteroid["payload"]["quarkuuid"]
                        quark = Quarks::getOrNull(quarkuuid)
                        return if quark.nil?
                        Quarks::quarkDive(quark)
                    }
                )
            end

            if asteroid["payload"]["type"] == "clique" then
                menuitems.item(
                    "clique (dive)",
                    lambda {
                        cliqueuuid = asteroid["payload"]["cliqueuuid"]
                        clique = Cliques::getOrNull(cliqueuuid)
                        return if clique.nil?
                        Cliques::cliqueDive(clique)
                    }
                )
            end

            menuitems.item(
                "destroy",
                lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this asteroid ? ") then
                        Asteroids::asteroidStopSequence(asteroid)
                        Asteroids::asteroidDestroySequence(asteroid)
                    end
                }
            )

            CatalystCommon::horizontalRule(true)

            status = menuitems.prompt()
            break if !status

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

        if orbital["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            return 0.72 - 0.01*Asteroids::shiftNX71(asteroid["unixtime"])
        end

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            return 0.70 - 0.1*Ping::bestTimeRatioOverPeriod7Samples(uuid, 86400*7)
        end

        if orbital["type"] == "repeating-daily-time-commitment-8123956c-05" then
            uuid = asteroid["uuid"]
            return Metrics::metricNX1RequiredValueAndThenFall(0.68, Ping::totalToday(uuid), orbital["timeCommitmentInHours"]*3600) - 0.1*Ping::bestTimeRatioOverPeriod7Samples(uuid, 86400*7)
        end

        if orbital["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            uuid = asteroid["uuid"]
            return Metrics::metricNX1RequiredValueAndThenFall(0.66, Ping::totalToday(uuid), 3600) - 0.1*Ping::bestTimeRatioOverPeriod7Samples(uuid, 86400*7)
        end
 
        if orbital["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
            uuid = asteroid["uuid"]
            return Metrics::metricNX1RequiredValueAndThenFall(0.64, Ping::totalToday(uuid), 1800) - 0.1*Ping::bestTimeRatioOverPeriod7Samples(uuid, 86400*7)
        end

        if orbital["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            return 0.60 - 0.01*Asteroids::shiftNX71(asteroid["unixtime"])
        end

        if orbital["type"] == "open-project-in-the-background-b458aa91-6e1" then
            return 0.21 - 0.01*Asteroids::shiftNX71(asteroid["unixtime"])
        end

        if orbital["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            return 0.49 - 0.01*Asteroids::shiftNX71(asteroid["unixtime"])
        end

        puts asteroid
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

    # Asteroids::pingTodayValueLive(asteroid)
    def self.pingTodayValueLive(asteroid)
        uuid = asteroid["uuid"]
        Ping::totalToday(uuid) + Asteroids::runTimeIfAny(asteroid)
    end

    # Asteroids::isRunning?(asteroid)
    def self.isRunning?(asteroid)
        Runner::isRunning?(asteroid["uuid"])
    end

    # Asteroids::isRunningForLong?(asteroid)
    def self.isRunningForLong?(asteroid)
        uuid = asteroid["uuid"]
        orbital = asteroid["orbital"]
        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            if Asteroids::bankValueLive(asteroid) >= orbital["timeCommitmentInHours"]*3600 then
                return true
            end
        end
        if orbital["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            return Asteroids::pingTodayValueLive(asteroid) >= 3600
        end
        if orbital["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
            return Asteroids::pingTodayValueLive(asteroid) >= 1800
        end
        ( Runner::runTimeInSecondsOrNull(asteroid["uuid"]) || 0 ) > 3600
    end

    # Asteroids::asteroidToCalalystObject(asteroid)
    def self.asteroidToCalalystObject(asteroid)
        uuid = asteroid["uuid"]
        {
            "uuid"             => uuid,
            "body"             => Asteroids::asteroidToString(asteroid),
            "metric"           => Asteroids::metric(asteroid),
            "commands"         => [],
            "execute"          => lambda { |input|

                typesThatTerminate = [
                    "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3",
                    "on-going-until-completion-5b26f145-7ebf-498",
                    "float-to-do-today-b0d902a8-3184-45fa-9808-1",
                    "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
                ]

                if input == ".." and Runner::isRunning?(uuid) and typesThatTerminate.include?(asteroid["orbital"]["type"]) then
                    Asteroids::asteroidStopSequence(asteroid)
                    if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ") then
                        Asteroids::asteroidDestroySequence(asteroid)
                    end
                    return
                end

                if input == ".." and Runner::isRunning?(uuid) then
                    Asteroids::asteroidStopSequence(asteroid)
                    return
                end

                if input == ".." and !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" and asteroid["payload"]["type"] == "description" then
                    if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? (if no, then will start): ") then
                        Asteroids::asteroidDestroySequence(asteroid)
                        return
                    end
                    Asteroids::asteroidStartSequence(asteroid)
                    return
                end

                if input == ".." and !Runner::isRunning?(uuid) then
                    Asteroids::asteroidStartSequence(asteroid)
                    return
                end

                Asteroids::asteroidDive(asteroid) 
            },
            "isRunning"        => Asteroids::isRunning?(asteroid),
            "isRunningForLong" => Asteroids::isRunningForLong?(asteroid),
            "x-asteroid"       => asteroid
        }
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()
        Asteroids::asteroids()
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
    end

    # Asteroids::asteroidStartSequence(asteroid)
    def self.asteroidStartSequence(asteroid)

        BTreeSets::set(nil, "d015bfdd-deb6-447f-97af-ab9e87875148:#{Time.new.to_s[0, 10]}", asteroid["uuid"], asteroid["uuid"])
        # We cache the value of any asteroid that has started to help with the catalyst objects caching
        # An asteroid that have been started (from diving into it) is not necessarily in the list of 
        # those that the catalyst objects caching will select, and in such a case it would be running
        # wihtout being displayed

        return if Asteroids::isRunning?(asteroid)

        uuid = asteroid["uuid"]
        orbital = asteroid["orbital"]

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            if Bank::value(uuid) >= orbital["timeCommitmentInHours"]*3600 then
                puts "singleton time commitment asteroid is completed, destroying it..."
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

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            if Bank::value(asteroid["uuid"]) >= orbital["timeCommitmentInHours"]*3600 then
                puts "time commitment asteroid is completed, destroying it..."
                LucilleCore::pressEnterToContinue()
                Asteroids::asteroidDestroySequence(asteroid)
            end
        end
    end

    # Asteroids::asteroidDestructionQuarkHandling(quark)
    def self.asteroidDestructionQuarkHandling(quark)
        return if Bosons::getLinkedObjects(quark).size>0
        if LucilleCore::askQuestionAnswerAsBoolean("Retain quark ? ") then
            quark = Quarks::ensureQuarkDescription(quark)
            Quarks::ensureAtLeastOneQuarkQuarkTags(quark)
            Quarks::ensureAtLeastOneQuarkCliques(quark)
        else
            Quarks::destroyQuarkByUUID(quark["uuid"])
        end
    end

    # Asteroids::asteroidDestroySequence(asteroid)
    def self.asteroidDestroySequence(asteroid)
        Asteroids::asteroidStopSequence(asteroid)
        if asteroid["payload"]["type"] == "quark" then
            quark = Quarks::getOrNull(asteroid["payload"]["quarkuuid"])
            if !quark.nil? then
                Asteroids::asteroidDestructionQuarkHandling(quark)
            end
        end
        NyxSets::destroyObject(asteroid["uuid"])
    end

    # Asteroids::openPayload(asteroid)
    def self.openPayload(asteroid)
        if asteroid["payload"]["type"] == "quark" then
            quark = Quarks::getOrNull(asteroid["payload"]["quarkuuid"])
            return if quark.nil?
            Quarks::openQuark(quark)
        end
    end
end

class CatalystObjectsManager
    def initialize()

    end
    def computeAndCacheSubsetOfUUIDs()
        uuids = Asteroids::catalystObjects()
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse
                    .first(50)
                    .map{|object| object["x-asteroid"]["uuid"] }
        KeyValueStore::set(nil, "2d3981a9-faad-4854-83be-4fc73ac973f2", JSON.generate(uuids))
    end
    def getCachedUUIDs()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "2d3981a9-faad-4854-83be-4fc73ac973f2", "[]"))
    end
    def catalystObjects()
        getCachedUUIDs()
            .map{|uuid| Asteroids::getOrNull(uuid) }
            .compact
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
    end
    def incomingAsteroid(asteroid)
        uuids = (getCachedUUIDs() + [asteroid["uuid"]]).uniq
        KeyValueStore::set(nil, "2d3981a9-faad-4854-83be-4fc73ac973f2", JSON.generate(uuids))
    end
end

if !defined?($charlotte) then
    $charlotte = CatalystObjectsManager.new()
end

Thread.new {
    loop {
        sleep 60
        if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("f0e7adf3-0138-4234-a0e6-f7f50f45fbb1", 3600) then
            $charlotte.computeAndCacheSubsetOfUUIDs()
        end
    }
}
