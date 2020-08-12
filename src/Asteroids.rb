# encoding: UTF-8

class Asteroids

    # Asteroids::getOrNull(uuid)
    def self.getOrNull(uuid)
        object = NyxObjects::getOrNull(uuid)
        return nil if object.nil?
        return nil if (object["nyxNxSet"] != "b66318f4-2662-4621-a991-a6b966fb4398")
        object
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

    # Asteroids::toString(asteroid)
    def self.toString(asteroid)
        orbitalNSDataPoint = lambda{|asteroid|
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
        "[asteroid] #{Asteroids::asteroidOrbitalTypeAsUserFriendlyString(asteroid["orbital"]["type"])} #{NSDataTypeXExtended::getLastDescriptionForTargetOrNull(asteroid)} #{orbitalNSDataPoint.call(asteroid)}#{runningString}"
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
            return 0.65 + 0.05*Miscellaneous::metricCircle(asteroid["unixtime"])
        end

        if orbital["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return 0.65 + 0.05*Miscellaneous::metricCircle(asteroid["unixtime"]) - 0.40*Math.exp(-BankExtended::recoveredDailyTimeInHours(asteroid["orbital"]["type"]))
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
            return 0.65 + 0.05*Miscellaneous::metricCircle(asteroid["unixtime"])
        end

        if orbital["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            return 0.65 + 0.05*Miscellaneous::metricCircle(asteroid["unixtime"])
        end

        if orbital["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            uuid = asteroid["uuid"]
            return 0 if BankExtended::hasReachedDailyTimeTargetInHours(uuid, Asteroids::onGoingUnilCompletionDailyExpectationInHours())
            return 0.65 + 0.05*Miscellaneous::metricCircle(asteroid["unixtime"])
        end

        if orbital["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
            uuid = asteroid["uuid"]
            return 0 if BankExtended::hasReachedDailyTimeTargetInHours(uuid, Asteroids::onGoingUnilCompletionDailyExpectationInHours())
            return 0.65 + 0.05*Miscellaneous::metricCircle(asteroid["unixtime"])
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

        Asteroids::asteroidStopSequence(asteroid)

        if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
            Asteroids::asteroidDestroySequence(asteroid)
            return
        end

        ms = LCoreMenuItemsNX1.new()

        ms.item(
            "ReOrbital", 
            lambda { Asteroids::reOrbitalOrNothing(asteroid) }
        )

        ms.item(
            "Hide for a time", 
            lambda {
                timespanInDays = LucilleCore::askQuestionAnswerAsString("timespan in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+86400*timespanInDays)
            }
        )

        status = ms.prompt()
        #break if !status
    end

    # Asteroids::access(asteroid)
    def self.access(asteroid)

        uuid = asteroid["uuid"]

        # ----------------------------------------
        # Not Running

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            Asteroids::tryAndMoveThisInboxItem(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            Asteroids::asteroidStartSequence(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        # ----------------------------------------
        # Running

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
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

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
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
            "body"             => Asteroids::toString(asteroid),
            "metric"           => Asteroids::metric(asteroid),
            "execute"          => lambda { |command| 
                if command == "access-c2c799b1-bcb9-4963-98d5-494a5a76e2e6" then
                    Asteroids::access(asteroid) 
                end
                if command == "landing-ec23a3a3-bfa0-45db-a162-fdd92da87f64" then
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
        puts "Adding #{timespanInSeconds} seconds to #{Asteroids::toString(asteroid)}"
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

        if LucilleCore::askQuestionAnswerAsBoolean("keep target(s) ? ") then
            puts Asteroids::toString(asteroid)
            puts "Ok, you want to keep them, I am going to make them target of a new node"
            LucilleCore::pressEnterToContinue()
            # For this we are going to make a node with the same uuid as the asteroid and give into it
            node = {
                "uuid"     => asteroid["uuid"],
                "nyxNxSet" => "c18e8093-63d6-4072-8827-14f238975d04", # node
                "unixtime" => Time.new.to_f
            }
            NyxObjects::reput(node)
            NSDataType1::landing(node)
        else
            Arrows::getTargetsForSource(asteroid).each{|target|
                GenericObjectInterface::destroyProcedure(target)
            }
        end

        NyxObjects::destroy(asteroid)
    end

    # Asteroids::openTargetOrTargets(asteroid)
    def self.openTargetOrTargets(asteroid)
        targets = Arrows::getTargetsForSource(asteroid)
        if targets.size == 0 then
            return
        end
        if targets.size == 1 then
            target = targets.first
            GenericObjectInterface::access(target)
        end
       if targets.size > 1 then
            Asteroids::landing(asteroid)
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

    # Asteroids::landing(asteroid)
    def self.landing(asteroid)
        loop {

            asteroid = Asteroids::getOrNull(asteroid["uuid"])
            return if asteroid.nil?

            AsteroidsOfInterest::register(asteroid["uuid"])

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
                lambda { Asteroids::asteroidStartSequence(asteroid) }
            )

            menuitems.item(
                "stop",
                lambda { Asteroids::asteroidStopSequence(asteroid) }
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
                        Asteroids::asteroidStopAndDestroySequence(asteroid)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            targets = Arrows::getTargetsForSource(asteroid)
            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
            targets.each{|target|
                menuitems.item(
                    GenericObjectInterface::toString(target),
                    lambda { GenericObjectInterface::access(target) }
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
                        node = NSDT1Extended::selectExistingType1InteractivelyOrNull()
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
                    node = NSDT1Extended::selectExistingType1InteractivelyOrNull()
                    return if node.nil?
                    Arrows::issueOrException(asteroid, node)
                }
            )

            menuitems.item(
                "select target ; destroy",
                lambda {
                    target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", Arrows::getTargetsForSource(asteroid), lambda{|target| GenericObjectInterface::toString(target) })
                    return if target.nil?
                    GenericObjectInterface::destroyProcedure(target)
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
        AsteroidsOfInterest::getCollection()
            .values
            .map{|item|  item["uuid"] }
    end
end
