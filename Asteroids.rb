# encoding: UTF-8

class Asteroids

    # Asteroids::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Asteroids::commitToDisk(asteroid)
    def self.commitToDisk(asteroid)
        NyxObjects::put(asteroid)
    end

    # Asteroids::reCommitToDisk(asteroid)
    def self.reCommitToDisk(asteroid)
        NyxObjects::destroy(asteroid)
        NyxObjects::put(asteroid)
    end

    # Asteroids::makePayloadInteractivelyOrNull(asteroiduuid)
    def self.makePayloadInteractivelyOrNull(asteroiduuid)
        options = [
            "description",
            "metal"
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
        if option == "metal" then
            ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
            return nil if ns0.nil?
            ns1 = NSDataType1::issue()
            Arrows::issueOrException(ns1, ns0)
            Arrows::issueOrException({ "uuid" => asteroiduuid }, ns1) # clever idea ^^
            return {
                "type"        => "metal",
                "description" => nil
            }
        end
        nil
    end

    # Asteroids::makeOrbitalInteractivelyOrNull()
    def self.makeOrbitalInteractivelyOrNull()

        opt100 = "top priority"
        opt380 = "singleton time commitment"
        opt410 = "inbox"
        opt390 = "repeating daily time commitment"
        opt400 = "on going until completion"
        opt420 = "todo today"
        opt430 = "indefinite"
        opt440 = "open project in the background"
        opt450 = "todo"

        options = [
            opt100,
            opt380,
            opt390,
            opt400,
            opt410,
            opt420,
            opt430,
            opt440,
            opt450,
        ]

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", options)
        return nil if option.nil?
        if option == opt100 then
            ordinal = Asteroids::determineOrdinalForNewTopPriority()
            return {
                "type"                  => "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3",
                "ordinal"               => ordinal
            }
        end
        if option == opt380 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "singleton-time-commitment-7c67cb4f-77e0-4fd",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt390 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "repeating-daily-time-commitment-8123956c-05",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt400 then
            return {
                "type"                  => "on-going-until-completion-5b26f145-7ebf-498"
            }
        end
        if option == opt430 then
            return {
                "type"                  => "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2"
            }
        end
        if option == opt450 then
            return {
                "type"                  => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
            }
        end
        if option == opt420 then
            return {
                "type"                  => "float-to-do-today-b0d902a8-3184-45fa-9808-1"
            }
        end
        if option == opt440 then
            return {
                "type"                  => "open-project-in-the-background-b458aa91-6e1"
            }
        end
        if option == opt410 then
            return {
                "type"                  => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
            }
        end
        
        nil
    end

    # Asteroids::issueAsteroidInteractivelyOrNull()
    def self.issueAsteroidInteractivelyOrNull()
        uuid = SecureRandom.uuid
        payload = Asteroids::makePayloadInteractivelyOrNull(uuid)
        return if payload.nil?
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        asteroid = Asteroids::issueWithUUID(uuid, payload, orbital)
        AsteroidsOfInterest::register(asteroid["uuid"])
    end

    # Asteroids::issueWithUUID(uuid, payload, orbital)
    def self.issueWithUUID(uuid, payload, orbital)
        asteroid = {
            "uuid"     => uuid,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "payload"  => payload,
            "orbital"  => orbital
        }
        Asteroids::commitToDisk(asteroid)
        asteroid
    end

    # Asteroids::issueAsteroidInboxFromNSDataType1(ns1)
    def self.issueAsteroidInboxFromNSDataType1(ns1)
        payload = {
            "type"         => "metal",
            "description"  => nil
        }
        orbital = {
            "type" => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        }
        asteroid = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "payload"  => payload,
            "orbital"  => orbital
        }
        Asteroids::commitToDisk(asteroid)
        Arrows::issueOrException(asteroid, ns1)
        asteroid
    end

    # Asteroids::getNSDataType1ForAsteroid(asteroid)
    def self.getNSDataType1ForAsteroid(asteroid)
        Arrows::getTargetsOfGivenSetsForSource(asteroid, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # Asteroids::asteroidOrbitalTypeAsUserFriendlyString(type)
    def self.asteroidOrbitalTypeAsUserFriendlyString(type)
        return "‼️ " if type == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3"
        return "⏱️ " if type == "singleton-time-commitment-7c67cb4f-77e0-4fd"
        return "📥"  if type == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        return "💫"  if type == "repeating-daily-time-commitment-8123956c-05"
        return "⛵"  if type == "on-going-until-completion-5b26f145-7ebf-498"
        return "⛲"  if type == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2"
        return "👩‍💻"  if type == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        return "☀️ " if type == "float-to-do-today-b0d902a8-3184-45fa-9808-1"
        return "😴"  if type == "open-project-in-the-background-b458aa91-6e1"
    end

    # Asteroids::asteroidToString(asteroid)
    def self.asteroidToString(asteroid)
        payloadNSDataType0 = lambda{|asteroid|
            payload = asteroid["payload"]
            if payload["type"] == "description" then
                return " " + payload["description"]
            end
            if payload["type"] == "metal" then
                if payload["description"] then
                    return " #{payload["description"]}"
                else
                    ns1s = Asteroids::getNSDataType1ForAsteroid(asteroid)
                    if ns1s.size == 0 then
                        return " (no ns1 found)"
                    end
                    return " #{NSDataType1::cubeToString(ns1s[0])}"
                end
            end
            puts JSON.pretty_generate(asteroid)
            raise "[Asteroids] error: CE8497BB"
        }
        orbitalNSDataType0 = lambda{|asteroid|
            uuid = asteroid["uuid"]
            if asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
                return " (ordinal: #{asteroid["orbital"]["ordinal"]})"
            end
            if asteroid["orbital"]["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
                return " (singleton: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, done: #{(Asteroids::bankValueLive(asteroid).to_f/3600).round(2)} hours)"
            end
            if asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
                return " (daily commitment: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, recovered daily time: #{BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).round(2)} hours)"
            end
            ""
        }
        uuid = asteroid["uuid"]
        isRunning = Runner::isRunning?(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[asteroid] #{Asteroids::asteroidOrbitalTypeAsUserFriendlyString(asteroid["orbital"]["type"])}#{payloadNSDataType0.call(asteroid)}#{orbitalNSDataType0.call(asteroid)}#{runningString}"
    end

    # Asteroids::asteroids()
    def self.asteroids()
        NyxObjects::getSet("b66318f4-2662-4621-a991-a6b966fb4398")
    end

    # Asteroids::reOrbitalOrNothing(asteroid)
    def self.reOrbitalOrNothing(asteroid)
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        asteroid["orbital"] = orbital
        puts JSON.pretty_generate(asteroid)
        Asteroids::reCommitToDisk(asteroid)
    end

    # Asteroids::getOrdinalsWithCubesPairsForAsteroidInOrdinalOrder(asteroid)
    def self.getOrdinalsWithCubesPairsForAsteroidInOrdinalOrder(asteroid)
        Asteroids::getNSDataType1ForAsteroid(asteroid)
            .map{|cube| [ Asteroids::getPositionOrdinalForCubeAtAsteroid(asteroid, cube), cube] }
            .sort{|p1, p2| p1[0] <=> p2[0] }
    end

    # Asteroids::selectOneCubeOfAsteroidOrNull(asteroid)
    def self.selectOneCubeOfAsteroidOrNull(asteroid)
        ps = Asteroids::getOrdinalsWithCubesPairsForAsteroidInOrdinalOrder(asteroid)
        toStringLambda = lambda{|p| 
            ordinal = p[0]
            cube    = p[1]
            "(#{"%.5f" % ordinal}) #{NSDataType1::cubeToString(cube)}"
        }
        p = LucilleCore::selectEntityFromListOfEntitiesOrNull("cube", ps, toStringLambda)
        return nil if p.nil?
        p[1]
    end

    # Asteroids::unixtimedrift(unixtime)
    def self.unixtimedrift(unixtime)
        # "Unixtime To Decreasing Metric Shift Normalised To Interval Zero One"
        0.00000000001*(Time.new.to_f-unixtime).to_f
    end

    # Asteroids::metric(asteroid)
    def self.metric(asteroid)
        uuid = asteroid["uuid"]

        orbital = asteroid["orbital"]

        return 1 if Asteroids::isRunning?(asteroid)

        if orbital["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            return 0.72 - 0.001*Math.atan(asteroid["orbital"]["ordinal"])
            # We want the most recent one to come first
            # LIFO queue
        end

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            return 0.70 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return 0.68 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            return 0.66 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "repeating-daily-time-commitment-8123956c-05" then
            uuid = asteroid["uuid"]
            if orbital["days"] then
                if !orbital["days"].include?(Miscellaneous::todayAsLowercaseEnglishWeekDayName()) then
                    if Asteroids::isRunning?(asteroid) then
                        # This happens if we started before midnight and it's now after midnight
                        Asteroids::asteroidStopSequence(asteroid)
                    end
                    return 0
                end
            end
            return 0 if BankExtended::hasReachedDailyTimeTargetInHours(uuid, orbital["timeCommitmentInHours"])
            return 0.64 - 0.001*BankExtended::recoveredDailyTimeInHours(uuid)
        end

        if orbital["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            uuid = asteroid["uuid"]
            return 0 if BankExtended::hasReachedDailyTimeTargetInHours(uuid, Asteroids::onGoingUnilCompletionDailyExpectationInSeconds())
            return 0.62 - 0.001*BankExtended::recoveredDailyTimeInHours(uuid)
        end

        if orbital["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
            uuid = asteroid["uuid"]
            return 0 if BankExtended::hasReachedDailyTimeTargetInHours(uuid, Asteroids::onGoingUnilCompletionDailyExpectationInSeconds())
            return 0.60 - 0.001*BankExtended::recoveredDailyTimeInHours(uuid)
        end

        if orbital["type"] == "open-project-in-the-background-b458aa91-6e1" then
            return 0.21 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            return 0.49 + Asteroids::unixtimedrift(asteroid["unixtime"])
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

    # Asteroids::isRunning?(asteroid)
    def self.isRunning?(asteroid)
        Runner::isRunning?(asteroid["uuid"])
    end

    # Asteroids::onGoingUnilCompletionDailyExpectationInSeconds()
    def self.onGoingUnilCompletionDailyExpectationInSeconds()
        0.5*3600
    end

    # Asteroids::isRunningForLong?(asteroid)
    def self.isRunningForLong?(asteroid)
        return false if !Asteroids::isRunning?(asteroid)
        uuid = asteroid["uuid"]
        orbital = asteroid["orbital"]
        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            if Asteroids::bankValueLive(asteroid) >= orbital["timeCommitmentInHours"]*3600 then
                return true
            end
        end
        ( Runner::runTimeInSecondsOrNull(asteroid["uuid"]) || 0 ) > 3600
    end

    # Asteroids::asteroidOrbitalTypes()
    def self.asteroidOrbitalTypes()
        [
            "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3",
            "singleton-time-commitment-7c67cb4f-77e0-4fd",
            "repeating-daily-time-commitment-8123956c-05",
            "on-going-until-completion-5b26f145-7ebf-498",
            "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2",
            "float-to-do-today-b0d902a8-3184-45fa-9808-1",
            "open-project-in-the-background-b458aa91-6e1",
            "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        ]
    end

    # Asteroids::tryAndMoveThisInboxItem(asteroid)
    def self.tryAndMoveThisInboxItem(asteroid)
        return if asteroid["orbital"]["type"] != "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"

        if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
            Asteroids::asteroidStopAndDestroySequence(asteroid)
            return
        end

        if LucilleCore::askQuestionAnswerAsBoolean("move to todo today ? (if no, will propose to move to queue) : ") then
            Asteroids::asteroidStopSequence(asteroid)
            asteroid["orbital"] = {
                "type" => "float-to-do-today-b0d902a8-3184-45fa-9808-1"
            }
            Asteroids::reCommitToDisk(asteroid)
            return
        end

        if LucilleCore::askQuestionAnswerAsBoolean("move to queue ? (if no, will give you all orbital options) : ") then
            Asteroids::asteroidStopSequence(asteroid)
            asteroid["orbital"] = {
                "type" => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
            }
            Asteroids::reCommitToDisk(asteroid)
            return
        end

        Asteroids::reOrbitalOrNothing(asteroid)
    end

    # Asteroids::asteroidDoubleDotProcessing(asteroid)
    def self.asteroidDoubleDotProcessing(asteroid)

        uuid = asteroid["uuid"]

        # ----------------------------------------
        # Not Running

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openPayload(asteroid)
            Asteroids::tryAndMoveThisInboxItem(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openPayload(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidStopAndDestroySequence(asteroid)
            end
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openPayload(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidStopAndDestroySequence(asteroid)
            end
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openPayload(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidStopAndDestroySequence(asteroid)
            end
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["payload"]["type"] == "description" then
            Asteroids::asteroidStartSequence(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidStopAndDestroySequence(asteroid)
            end
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["payload"]["type"] == "metal" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openPayload(asteroid)
            return
        end

        # ----------------------------------------
        # Running

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidStopAndDestroySequence(asteroid)
                return
            end
            Asteroids::asteroidStopSequence(asteroid)
            Asteroids::tryAndMoveThisInboxItem(asteroid)
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
            Asteroids::asteroidStopSequence(asteroid)
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            Asteroids::asteroidStopSequence(asteroid)
            return
        end

        typesThatAreMeantToTerminate = [
            "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3",
            "float-to-do-today-b0d902a8-3184-45fa-9808-1",
            "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        ]

        if Runner::isRunning?(uuid) and typesThatAreMeantToTerminate.include?(asteroid["orbital"]["type"]) then
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidStopAndDestroySequence(asteroid)
                return
            end
            Asteroids::asteroidStopSequence(asteroid)
            return
        end
    end

    # Asteroids::asteroidToCalalystObject(asteroid)
    def self.asteroidToCalalystObject(asteroid)
        uuid = asteroid["uuid"]
        {
            "uuid"             => uuid,
            "body"             => Asteroids::asteroidToString(asteroid),
            "metric"           => Asteroids::metric(asteroid),
            "execute"          => lambda { |input|
                if input == ".." then
                    Asteroids::asteroidDoubleDotProcessing(asteroid)
                    return
                end
                Asteroids::landing(asteroid) 
            },
            "isRunning"        => Asteroids::isRunning?(asteroid),
            "isRunningForLong" => Asteroids::isRunningForLong?(asteroid),
            "x-asteroid"       => asteroid
        }
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()

        # Asteroids::asteroids()
        #    .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }

        AsteroidsOfInterest::getUUIDs()
            .map{|uuid| Asteroids::getOrNull(uuid) }
            .compact
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
        Runner::start(asteroid["uuid"])
    end

    # Asteroids::asteroidReceivesTime(asteroid, timespanInSeconds)
    def self.asteroidReceivesTime(asteroid, timespanInSeconds)
        puts "Adding #{timespanInSeconds} seconds to #{Asteroids::asteroidToString(asteroid)}"
        Bank::put(asteroid["uuid"], timespanInSeconds)
        Bank::put(asteroid["orbital"]["type"], timespanInSeconds)
    end

    # Asteroids::asteroidStopSequence(asteroid)
    def self.asteroidStopSequence(asteroid)
        return if !Asteroids::isRunning?(asteroid)
        timespan = Runner::stop(asteroid["uuid"])
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running

        Asteroids::asteroidReceivesTime(asteroid, timespan)

        payload = asteroid["payload"]
        orbital = asteroid["orbital"]

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            if Bank::value(asteroid["uuid"]) >= orbital["timeCommitmentInHours"]*3600 then
                puts "time commitment asteroid is completed, destroying it..."
                LucilleCore::pressEnterToContinue()
                Asteroids::asteroidStopAndDestroySequence(asteroid)
            end
        end
    end

    # Asteroids::asteroidStopAndDestroySequence(asteroid)
    def self.asteroidStopAndDestroySequence(asteroid)
        Asteroids::asteroidStopSequence(asteroid)
        Asteroids::asteroidDestroySequence(asteroid)
    end

    # Asteroids::asteroidDestroySequence(asteroid)
    def self.asteroidDestroySequence(asteroid)
        # The main purpose of the destroy sequence is a try and preserve data which might be useful
        if asteroid["payload"]["type"] == "description" then
            # nothing
        end

        if asteroid["payload"]["type"] == "metal" then
            Asteroids::getNSDataType1ForAsteroid(asteroid).each{|ns1|
                next if NavigationPoint::getUpstreamNavigationPoints(ns1).size > 0
                puts "destroying ns1: #{ns1}"
                NyxObjects::destroy(ns1)
            }
        end

        NyxObjects::destroy(asteroid)
    end

    # Asteroids::openPayload(asteroid)
    def self.openPayload(asteroid)
        if asteroid["payload"]["type"] == "metal" then
            ns1s = Asteroids::getNSDataType1ForAsteroid(asteroid)
            if ns1s.size == 0 then
                return
            end
            if ns1s.size == 1 then
                NSDataType1::openLastCubeFrame(ns1s[0])
                return
            end
            ns1 = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns1", ns1s, lambda{ |ns1| NSDataType1::cubeToString(ns1) })
            return if ns1.nil?
            NSDataType1::openLastCubeFrame(ns1)
        end
    end

    # Asteroids::diveAsteroidOrbitalType(orbitalType)
    def self.diveAsteroidOrbitalType(orbitalType)
        loop {
            system("clear")
            asteroids = Asteroids::asteroids().select{|asteroid| asteroid["orbital"]["type"] == orbitalType }
            asteroid = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", asteroids, lambda{|asteroid| Asteroids::asteroidToString(asteroid) })
            break if asteroid.nil?
            Asteroids::landing(asteroid)
        }
    end

    # Asteroids::getNSDataType0sForAsteroid(asteroid)
    def self.getNSDataType0sForAsteroid(asteroid)
        Arrows::getTargetsOfGivenSetsForSource(asteroid, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
    end

    # Asteroids::getTopPriorityAsteroidsInPriorityOrder()
    def self.getTopPriorityAsteroidsInPriorityOrder()
        Asteroids::asteroids()
            .select{|asteroid| asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" }
            .sort{|a1, a2| a1["orbital"]["ordinal"] <=> a2["orbital"]["ordinal"] }
    end

    # Asteroids::determineOrdinalForNewTopPriority()
    def self.determineOrdinalForNewTopPriority()
        topPriorities = Asteroids::getTopPriorityAsteroidsInPriorityOrder()
        if topPriorities.empty? then
            return 0
        else
            puts ""
            Asteroids::getTopPriorityAsteroidsInPriorityOrder()
                .each{|asteroid| puts Asteroids::asteroidToString(asteroid) }
            puts ""
            return LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        end
    end

    # Asteroids::setPositionOrdinalForCubeAtAsteroid(asteroid, cube, ordinal)
    def self.setPositionOrdinalForCubeAtAsteroid(asteroid, cube, ordinal)
        key = "491d8eec-27ae-4860-96d8-95d3fce2fb3c:#{asteroid["uuid"]}:#{cube["uuid"]}"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(key, ordinal)
    end

    # Asteroids::getPositionOrdinalForCubeAtAsteroid(asteroid, cube)
    def self.getPositionOrdinalForCubeAtAsteroid(asteroid, cube)
        key = "491d8eec-27ae-4860-96d8-95d3fce2fb3c:#{asteroid["uuid"]}:#{cube["uuid"]}"
        ordinal = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(key)
        if ordinal.nil? then
            ordinal = rand
            Asteroids::setPositionOrdinalForCubeAtAsteroid(asteroid, cube, ordinal)
        end
        ordinal
    end

    # Asteroids::landing(asteroid)
    def self.landing(asteroid)
        loop {

            asteroid = Asteroids::getOrNull(asteroid["uuid"])
            return if asteroid.nil?

            AsteroidsOfInterest::register(asteroid["uuid"])

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts Asteroids::asteroidToString(asteroid)

            puts "uuid: #{asteroid["uuid"]}"
            puts "payload: #{JSON.generate(asteroid["payload"])}"
            puts "orbital: #{JSON.generate(asteroid["orbital"])}"
            puts "metric: #{Asteroids::metric(asteroid)}"

            unixtime = DoNotShowUntil::getUnixtimeOrNull(asteroid["uuid"])
            if unixtime and (Time.new.to_i < unixtime) then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}"
            end

            if asteroid["payload"]["type"] == "description" then
                menuitems.item(
                    "set asteroid description",
                    lambda { 
                        description = LucilleCore::askQuestionAnswerAsString("asteroid description: ")
                        return if description == ""
                        asteroid["payload"]["description"] = description
                        Asteroids::reCommitToDisk(asteroid)
                    }
                )
            end

            menuitems.item(
                "set asteroid description",
                lambda { 
                    description = LucilleCore::askQuestionAnswerAsString("asteroid description: ")
                    return if description == ""
                    asteroid["payload"]["description"] = description
                    Asteroids::reCommitToDisk(asteroid)
                }
            )

            if asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
                if asteroid["orbital"]["days"] then
                    puts "on days: #{asteroid["orbital"]["days"].join(", ")}"
                end
            end

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
                        asteroid["payload"]["description"] = Miscellaneous::editTextUsingTextmate(asteroid["payload"]["description"]).strip
                        Asteroids::reCommitToDisk(asteroid)
                    }
                )
            end

            menuitems.item(
                "re-orbital",
                lambda { Asteroids::reOrbitalOrNothing(asteroid) }
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
                    Asteroids::asteroidReceivesTime(asteroid, timeInHours*3600)
                }
            )

            menuitems.item(
                "destroy",
                lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this asteroid ? ") then
                        Asteroids::asteroidStopAndDestroySequence(asteroid)
                    end
                }
            )

            if asteroid["payload"]["type"] == "metal" then

                Miscellaneous::horizontalRule()

                Asteroids::getOrdinalsWithCubesPairsForAsteroidInOrdinalOrder(asteroid).each{|packet|
                    ordinal, cube = packet
                    menuitems.item(
                        "(#{"%.5f" % ordinal}) #{NSDataType1::cubeToString(cube)}",
                        lambda { NSDataType1::landing(cube) }
                    )
                }

                menuitems.item(
                    "add new #{NavigationPoint::ufn("Type1")}",
                    lambda { 
                        cube = NSDataType1::issueNewCubeAndItsFirstFrameInteractivelyOrNull()
                        return if cube.nil?
                        Arrows::issueOrException(asteroid, cube)
                        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                        Asteroids::setPositionOrdinalForCubeAtAsteroid(asteroid, cube, ordinal)
                    }
                )

                menuitems.item(
                    "select #{NavigationPoint::ufn("Type1")} ; set ordinal",
                    lambda { 
                        cube = Asteroids::selectOneCubeOfAsteroidOrNull(asteroid)
                        return if cube.nil?
                        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                        Asteroids::setPositionOrdinalForCubeAtAsteroid(asteroid, cube, ordinal)
                    }
                )

            end

            Miscellaneous::horizontalRule()

            puts "Bank          : #{Bank::value(asteroid["uuid"]).to_f/3600} hours"
            puts "Bank 7 days   : #{Bank::valueOverTimespan(asteroid["uuid"], 86400*7).to_f/3600} hours"
            puts "Bank 24 hours : #{Bank::valueOverTimespan(asteroid["uuid"], 86400).to_f/3600} hours"

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status

        }
    end

    # Asteroids::main()
    def self.main()
        loop {
            system("clear")
            options = [
                "make new asteroid",
                "dive asteroids"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "make new asteroid" then
                asteroid = Asteroids::issueAsteroidInteractivelyOrNull()
                next if asteroid.nil?
                puts JSON.pretty_generate(asteroid)
            end
            if option == "dive asteroids" then
                loop {
                    orbitalType = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", Asteroids::asteroidOrbitalTypes())
                    break if orbitalType.nil?
                    Asteroids::diveAsteroidOrbitalType(orbitalType)
                }
            end
        }
    end
end

class AsteroidsOfInterest

    # AsteroidsOfInterest::getCollection()
    def self.getCollection()
        collection = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("5d114a38-f86a-46db-a33b-747c8d7ec22f:#{Miscellaneous::today()}")
        if collection.nil? then
            collection = {}
        end
        collection
    end

    # AsteroidsOfInterest::register(uuid)
    def self.register(uuid)
        collection = AsteroidsOfInterest::getCollection()
        collection[uuid] = { "uuid" => uuid, "unixtime" => Time.new.to_i }
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("5d114a38-f86a-46db-a33b-747c8d7ec22f:#{Miscellaneous::today()}", collection)
    end

    # AsteroidsOfInterest::getUUIDs()
    def self.getUUIDs()
        AsteroidsOfInterest::getCollection().values.map{|item|  item["uuid"] }
    end
end
