# encoding: UTF-8

class Asteroids

    # -------------------------------------------------------------------
    # Building

    # Asteroids::makePayloadInteractivelyOrNull(asteroiduuid)
    def self.makePayloadInteractivelyOrNull(asteroiduuid)
        options = [
            "description",
            "metal",
            "direct management"
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
            ns0 = NSDataPoint::issueNewPointInteractivelyOrNull()
            return nil if ns0.nil?
            ns1 = NSDataType1::issue()
            Arrows::issueOrException(ns1, ns0)
            Arrows::issueOrException({ "uuid" => asteroiduuid }, ns1) # clever idea ^^
            return {
                "type"        => "metal",
                "description" => nil
            }
        end
        if option == "direct management" then
            basename = LucilleCore::askQuestionAnswerAsString("basename: ")
            return nil if basename.size == 0
            return {
                "type"        => "direct-management-5d44d340-1449-43ff-9864-e1f0526f1e26",
                "description" => basename
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
        description = LucilleCore::askQuestionAnswerAsString("asteroid description: ")
        return nil if (description == "")
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return nil if orbital.nil?
        asteroid = {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "orbital"  => orbital
        }
        Asteroids::commitToDisk(asteroid)
        NSDataTypeXExtended::issueDescriptionForTarget(asteroid, description)
        asteroid
    end

    # Asteroids::issueAsteroidInboxFromDataline(dataline)
    def self.issueAsteroidInboxFromDataline(dataline)
        orbital = {
            "type" => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        }
        asteroid = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "orbital"  => orbital
        }
        Asteroids::commitToDisk(asteroid)
        Arrows::issueOrException(asteroid, dataline)
        asteroid
    end

    # -------------------------------------------------------------------
    # Data Extraction

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

    # Asteroids::asteroids()
    def self.asteroids()
        NyxObjects2::getSet("b66318f4-2662-4621-a991-a6b966fb4398")
    end

    # Asteroids::getAsteroidOrNull(uuid)
    def self.getAsteroidOrNull(uuid)
        object = NyxObjects2::getOrNull(uuid)
        return nil if object.nil?
        return nil if (object["nyxNxSet"] != "b66318f4-2662-4621-a991-a6b966fb4398")
        object
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

    # Asteroids::orbitalToString(asteroid)
    def self.orbitalToString(asteroid)
        uuid = asteroid["uuid"]
        if asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            return "(ordinal: #{asteroid["orbital"]["ordinal"]})"
        end
        if asteroid["orbital"]["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            return "(singleton: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, done: #{(Asteroids::bankValueLive(asteroid).to_f/3600).round(2)} hours)"
        end
        if asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
            return "(daily commitment: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, recovered daily time: #{BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).round(2)} hours)"
        end
        ""
    end

    # Asteroids::asteroidDescriptionUseTheForce(asteroid)
    def self.asteroidDescriptionUseTheForce(asteroid)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(asteroid)
        return description if description
        targets = Arrows::getTargetsForSource(asteroid)
        if targets.empty? then
           return "no target"
        end
        if targets.size == 1 then
            return GenericObjectInterface::toString(targets.first)
        end
        "multiple targets (#{targets.size})"
    end

    # Asteroids::asteroidDescription(asteroid)
    def self.asteroidDescription(asteroid)
        str = KeyValueStore::getOrNull(nil, "f16f78bd-c5a1-490e-8f28-9df73f43733d:#{asteroid["uuid"]}")
        return str if str
        str = Asteroids::asteroidDescriptionUseTheForce(asteroid)
        KeyValueStore::set(nil, "f16f78bd-c5a1-490e-8f28-9df73f43733d:#{asteroid["uuid"]}", str)
        str
    end

    # Asteroids::toString(asteroid)
    def self.toString(asteroid)
        uuid = asteroid["uuid"]
        isRunning = Runner::isRunning?(uuid)
        runningString = 
            if isRunning then
                "(running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[asteroid] #{Asteroids::asteroidOrbitalTypeAsUserFriendlyString(asteroid["orbital"]["type"])} #{Asteroids::asteroidDescription(asteroid)} #{Asteroids::orbitalToString(asteroid)} #{runningString}".strip
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
            return 0.75 - 0.001*Math.atan(asteroid["orbital"]["ordinal"])
            # We want the most recent one to come first
            # LIFO queue
        end

        if orbital["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return 0.73 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            return 0.70 - 0.01*BankExtended::recoveredDailyTimeInHours(asteroid["uuid"])
        end

        if orbital["type"] == "repeating-daily-time-commitment-8123956c-05" then
            if orbital["days"] then
                if !orbital["days"].include?(Miscellaneous::todayAsLowercaseEnglishWeekDayName()) then
                    if Asteroids::isRunning?(asteroid) then
                        # This happens if we started before midnight and it's now after midnight
                        Asteroids::stopAsteroidIfRunning(asteroid)
                    end
                    return 0
                end
            end
            return 0 if BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]) > orbital["timeCommitmentInHours"]
            return 0.70 - 0.01*BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/orbital["timeCommitmentInHours"]
        end

        if orbital["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            return 0.67 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            uuid = asteroid["uuid"]
            return 0 if BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]) > Asteroids::onGoingUnilCompletionDailyExpectationInHours()
            return 0.63 - 0.01*BankExtended::recoveredDailyTimeInHours(asteroid["uuid"])
        end

        if orbital["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
            uuid = asteroid["uuid"]
            return 0 if BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]) > Asteroids::onGoingUnilCompletionDailyExpectationInHours()
            return 0.63 - 0.01*BankExtended::recoveredDailyTimeInHours(asteroid["uuid"])
        end

        if orbital["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            return 0.49 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "open-project-in-the-background-b458aa91-6e1" then
            return 0.21 + Asteroids::unixtimedrift(asteroid["unixtime"])
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

    # Asteroids::onGoingUnilCompletionDailyExpectationInHours()
    def self.onGoingUnilCompletionDailyExpectationInHours()
        0.5
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
                .each{|asteroid| puts Asteroids::toString(asteroid) }
            puts ""
            return LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        end
    end

    # Asteroids::asteroidToCalalystObject(asteroid)
    def self.asteroidToCalalystObject(asteroid)
        uuid = asteroid["uuid"]
        {
            "uuid"             => uuid,
            "body"             => Asteroids::toString(asteroid),
            "metric"           => Asteroids::metric(asteroid),
            "execute"          => lambda { |command| 
                if command == "c2c799b1-bcb9-4963-98d5-494a5a76e2e6" then
                    Asteroids::access(asteroid) 
                end
                if command == "ec23a3a3-bfa0-45db-a162-fdd92da87f64" then
                    Asteroids::landing(asteroid) 
                end
            },
            "isRunning"        => Asteroids::isRunning?(asteroid),
            "isRunningForLong" => Asteroids::isRunningForLong?(asteroid),
            "x-asteroid"       => asteroid
        }
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()
        Asteroids::asteroids().each{|asteroid|
            if asteroid["orbital"]["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
                if Bank::value(asteroid["uuid"]) >= asteroid["orbital"]["timeCommitmentInHours"]*3600 then
                    Asteroids::stopAsteroidIfRunningAndDestroy(asteroid)
                end
            end
        }

        Asteroids::asteroids()
            .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
            .reduce([]) {|asteroids, asteroid|
                if asteroid["orbital"]["type"] != "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
                    asteroids + [ asteroid ]
                else
                    if asteroids.select{|a| a["orbital"]["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" }.size < 100 then
                        asteroids + [ asteroid ]
                    else
                        asteroids
                    end
                end
            }
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
    end

    # -------------------------------------------------------------------
    # Operations

    # Asteroids::commitToDisk(asteroid)
    def self.commitToDisk(asteroid)
        NyxObjects2::put(asteroid)
    end

    # Asteroids::reOrbitalOrNothing(asteroid)
    def self.reOrbitalOrNothing(asteroid)
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        asteroid["orbital"] = orbital
        puts JSON.pretty_generate(asteroid)
        Asteroids::commitToDisk(asteroid)
    end

    # Asteroids::asteroidReceivesTime(asteroid, timespanInSeconds)
    def self.asteroidReceivesTime(asteroid, timespanInSeconds)
        puts "Adding #{timespanInSeconds} seconds to #{Asteroids::toString(asteroid)}"
        Bank::put(asteroid["uuid"], timespanInSeconds)
        Bank::put(asteroid["orbital"]["type"], timespanInSeconds)
    end

    # Asteroids::startAsteroidIfNotRunning(asteroid)
    def self.startAsteroidIfNotRunning(asteroid)
        return if Asteroids::isRunning?(asteroid)
        Runner::start(asteroid["uuid"])
    end

    # Asteroids::stopAsteroidIfRunning(asteroid)
    def self.stopAsteroidIfRunning(asteroid)
        return if !Asteroids::isRunning?(asteroid)
        timespan = Runner::stop(asteroid["uuid"])
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        Asteroids::asteroidReceivesTime(asteroid, timespan)
    end

    # Asteroids::stopAsteroidIfRunningAndDestroy(asteroid)
    def self.stopAsteroidIfRunningAndDestroy(asteroid)
        Asteroids::stopAsteroidIfRunning(asteroid)
        Asteroids::destroy(asteroid)
    end

    # Asteroids::openTargetOrTargets(asteroid)
    def self.openTargetOrTargets(asteroid)
        targets = Arrows::getTargetsForSource(asteroid)
        if targets.size == 0 then
            return
        end
        if targets.size == 1 then
            target = targets.first
            if GenericObjectInterface::isAsteroid(target) then
                Asteroids::landing(target)
                return
            end
            if GenericObjectInterface::isNode(target) then
                NSDataType1::landing(target)
                return
            end
            if GenericObjectInterface::isDataline(target) then
                NSDataLine::enterLastDataPointOrNothing(target)
                return
            end
            if GenericObjectInterface::isDataPoint(target) then
                NSDataPoint::enterDataPoint(target)
                return
            end
        end
       if targets.size > 1 then
            Asteroids::landing(asteroid)
        end
    end

    # Asteroids::processInboxAsteroid(asteroid)
    def self.processInboxAsteroid(asteroid)
        targets = Arrows::getTargetsForSource(asteroid)
        if targets.size == 0 then
            Asteroids::destroy(asteroid)
            return
        end
        if targets.size == 1 then
            target = targets.first

            # default action

            Asteroids::startAsteroidIfNotRunning(asteroid)

            if GenericObjectInterface::isAsteroid(target) then
                Asteroids::landing(target)
            end

            if GenericObjectInterface::isNode(target) then
                NSDataType1::landing(target)
            end

            if GenericObjectInterface::isDataline(target) then
                NSDataLine::enterLastDataPointOrNothing(target)
            end

            if GenericObjectInterface::isDataPoint(target) then
                NSDataPoint::enterDataPoint(target)
            end

            Asteroids::stopAsteroidIfRunning(asteroid)

            # recasting

            modes = [
                "hide for a time",
                "move to todo today",
                "add to queue",
                "general re orbital",
                "destroy"
            ]
            mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", modes)
            return if mode.nil?
            if mode == "hide for a time" then
                timespanInDays = LucilleCore::askQuestionAnswerAsString("timespan in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+86400*timespanInDays)
                return
            end
            if mode == "move to todo today" then
                asteroid["orbital"] = {
                    "type" => "float-to-do-today-b0d902a8-3184-45fa-9808-1"
                }
                Asteroids::commitToDisk(asteroid)
                return
            end
            if mode == "add to queue" then
                asteroid["orbital"] = {
                    "type" => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
                }
                Asteroids::commitToDisk(asteroid)
                return
            end
            if mode == "general re orbital" then
                Asteroids::reOrbitalOrNothing(asteroid)
                return
            end
            if mode == "destroy" then
                GenericObjectInterface::destroy(asteroid)
                return
            end
        end
       if targets.size > 1 then
            Asteroids::landing(asteroid)
            return if Asteroids::getAsteroidOrNull(asteroid["uuid"]).nil?
            if LucilleCore::askQuestionAnswerAsBoolean("destroy asteroid? : ") then
                Asteroids::destroy(asteroid)
                return
            end
        end
    end

    # Asteroids::diveAsteroidOrbitalType(orbitalType)
    def self.diveAsteroidOrbitalType(orbitalType)
        loop {
            system("clear")
            asteroids = Asteroids::asteroids().select{|asteroid| asteroid["orbital"]["type"] == orbitalType }
            asteroid = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", asteroids, lambda{|asteroid| Asteroids::toString(asteroid) })
            break if asteroid.nil?
            Asteroids::landing(asteroid)
        }
    end

    # Asteroids::access(asteroid)
    def self.access(asteroid)

        uuid = asteroid["uuid"]

        # ----------------------------------------
        # Not Running

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            Asteroids::processInboxAsteroid(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        # ----------------------------------------
        # Running

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::destroy(asteroid)
            end
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::destroy(asteroid)
            end
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::destroy(asteroid)
            end
            return
        end
    end

    # Asteroids::landing(asteroid)
    def self.landing(asteroid)
        loop {

            asteroid = Asteroids::getAsteroidOrNull(asteroid["uuid"])
            return if asteroid.nil?

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts Asteroids::toString(asteroid)

            puts "uuid: #{asteroid["uuid"]}"
            puts "orbital: #{JSON.generate(asteroid["orbital"])}"
            if asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
                if asteroid["orbital"]["days"] then
                    puts "on days: #{asteroid["orbital"]["days"].join(", ")}"
                end
            end
            puts "BankExtended::recoveredDailyTimeInHours(bankuuid): #{BankExtended::recoveredDailyTimeInHours(asteroid["uuid"])}"
            puts "metric: #{Asteroids::metric(asteroid)}"

            unixtime = DoNotShowUntil::getUnixtimeOrNull(asteroid["uuid"])
            if unixtime and (Time.new.to_i < unixtime) then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}"
            end

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(asteroid)
            if notetext and notetext.strip.size > 0 then
                Miscellaneous::horizontalRule()
                puts "Note:"
                puts notetext.strip.lines.map{|line| "    #{line}" }.join()
                Miscellaneous::horizontalRule()
            end

            puts ""

            menuitems.item(
                "update asteroid description",
                lambda { 
                    puts "Not yet implemented"
                    LucilleCore::pressEnterToContinue()
                }
            )

            menuitems.item(
                "start",
                lambda { Asteroids::startAsteroidIfNotRunning(asteroid) }
            )

            menuitems.item(
                "stop",
                lambda { Asteroids::stopAsteroidIfRunning(asteroid) }
            )

            menuitems.item(
                "re-orbital",
                lambda { Asteroids::reOrbitalOrNothing(asteroid) }
            )

            menuitems.item(
                "edit note",
                lambda{ 
                    text = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(asteroid) || ""
                    text = Miscellaneous::editTextSynchronously(text).strip
                    NSDataTypeXExtended::issueNoteForTarget(asteroid, text)
                }
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
                        Asteroids::stopAsteroidIfRunningAndDestroy(asteroid)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            targets = Arrows::getTargetsForSource(asteroid)
            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
            targets.each{|target|
                GenericObjectInterface::decacheObjectMetadata(target)
                menuitems.item(
                    GenericObjectInterface::toString(target),
                    lambda {
                        GenericObjectInterface::envelop(target)
                    }
                )
            }

            puts ""

            menuitems.item(
                "add new target",
                lambda { 
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", ["new node", "existing node", "dataline"])
                    return if option.nil?
                    if option == "new node" then
                        node = NSDataType1::issueNewNodeInteractivelyOrNull()
                        return if node.nil?
                        Arrows::issueOrException(asteroid, node)
                    end
                    if option == "existing node" then
                        node = NSDT1ExtendedUserInterface::selectExistingType1InteractivelyOrNull()
                        return if node.nil?
                        Arrows::issueOrException(asteroid, node)
                    end
                    if option == "dataline" then
                        dataline = NSDataLine::interactiveIssueNewDatalineWithItsFirstPointOrNull()
                        return if dataline.nil?
                        Arrows::issueOrException(asteroid, dataline)
                    end
                }
            )

            menuitems.item(
                "add node (chosen from existing nodes)",
                lambda {
                    node = NSDT1ExtendedUserInterface::selectExistingType1InteractivelyOrNull()
                    return if node.nil?
                    Arrows::issueOrException(asteroid, node)
                }
            )

            menuitems.item(
                "select target ; destroy",
                lambda {
                    target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", Arrows::getTargetsForSource(asteroid), lambda{|target| GenericObjectInterface::toString(target) })
                    return if target.nil?
                    GenericObjectInterface::destroy(target)
                }
            )

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
                    system("clear")
                    orbitalType = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", Asteroids::asteroidOrbitalTypes())
                    break if orbitalType.nil?
                    Asteroids::diveAsteroidOrbitalType(orbitalType)
                }
            end
        }
    end

    # Asteroids::destroy(asteroid)
    def self.destroy(asteroid)
        NyxObjects2::destroy(asteroid)
    end

    # ------------------------------------------------------------------
end
