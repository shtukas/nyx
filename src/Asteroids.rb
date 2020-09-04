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
            return {
                "type"                  => "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3"
            }
        end
        if option == opt390 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "repeating-daily-time-commitment-8123956c-05",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt450 then
            return {
                "type"                  => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
            }
        end
        if option == opt420 then
            return {
                "type"                  => "the-burner-07f24c2a-75da-4323-81bb-8c0e80a0"
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

    # Asteroids::issuePlainAsteroidInteractivelyOrNull()
    def self.issuePlainAsteroidInteractivelyOrNull()
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

    # Asteroids::issueDatapointAndAsteroidInteractivelyOrNull()
    def self.issueDatapointAndAsteroidInteractivelyOrNull()
        datapoint = NSDataPoint::issueNewPointInteractivelyOrNull()
        return if datapoint.nil?
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return nil if orbital.nil?
        asteroid = {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "orbital"  => orbital
        }
        Asteroids::commitToDisk(asteroid)
        Arrows::issueOrException(asteroid, datapoint)
        asteroid
    end

    # Asteroids::issueAsteroidInboxFromDatapoint(datapoint)
    def self.issueAsteroidInboxFromDatapoint(datapoint)
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
        Arrows::issueOrException(asteroid, datapoint)
        asteroid
    end

    # -------------------------------------------------------------------
    # Data Extraction

    # Asteroids::asteroidOrbitalTypes()
    def self.asteroidOrbitalTypes()
        [
            "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3",
            "repeating-daily-time-commitment-8123956c-05",
            "the-burner-07f24c2a-75da-4323-81bb-8c0e80a0",
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
        return "📥"  if type == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        return "💫"  if type == "repeating-daily-time-commitment-8123956c-05"
        return "☀️ " if type == "the-burner-07f24c2a-75da-4323-81bb-8c0e80a0"
        return "👩‍💻"  if type == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        return "😴"  if type == "open-project-in-the-background-b458aa91-6e1"
    end

    # Asteroids::orbitalToString(asteroid)
    def self.orbitalToString(asteroid)
        uuid = asteroid["uuid"]
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
            return 0.75 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return 0.70 + Asteroids::unixtimedrift(asteroid["unixtime"])
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
            return 0.65 - 0.01*BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/orbital["timeCommitmentInHours"]
        end

        if orbital["type"] == "the-burner-07f24c2a-75da-4323-81bb-8c0e80a0" then
            return 0.60 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if orbital["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            return 0.30 + Asteroids::unixtimedrift(asteroid["unixtime"])
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
        ( Runner::runTimeInSecondsOrNull(asteroid["uuid"]) || 0 ) > 3600
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
                    Asteroids::naturalNextOperation(asteroid) 
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

        if asteroid["orbital"]["type"] == "the-burner-07f24c2a-75da-4323-81bb-8c0e80a0" then
            cycleTimeInSeconds = KeyValueStore::getOrDefaultValue(nil, "BurnerCycleTime-F8E4-49A5-87E3-99EADB61EF64-#{asteroid["uuid"]}", "0").to_i
            cycleTimeInSeconds = cycleTimeInSeconds + timespanInSeconds
            KeyValueStore::set(nil, "BurnerCycleTime-F8E4-49A5-87E3-99EADB61EF64-#{asteroid["uuid"]}", cycleTimeInSeconds)
            if cycleTimeInSeconds > 3600 then
                KeyValueStore::set(nil, "BurnerCycleTime-F8E4-49A5-87E3-99EADB61EF64-#{asteroid["uuid"]}", 0)
                asteroid["unixtime"] = Time.new.to_i
                NyxObjects2::put(asteroid)
            end
        end
    end

    # Asteroids::startAsteroidIfNotRunning(asteroid)
    def self.startAsteroidIfNotRunning(asteroid)
        return if Asteroids::isRunning?(asteroid)
        puts "start asteroid: #{Asteroids::toString(asteroid)}"
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
            if GenericObjectInterface::isDataPoint(target) then
                NSDataPoint::accessopen(target)
                return
            end
        end
       if targets.size > 1 then
            Asteroids::landing(asteroid)
        end
    end

    # Asteroids::transmuteAsteroidToNode(asteroid)
    def self.transmuteAsteroidToNode(asteroid)
        Asteroids::stopAsteroidIfRunning(asteroid)
        description = LucilleCore::askQuestionAnswerAsString("node description: ")
        return if description == ""
        node = NSDataType1::issue()
        NSDataTypeXExtended::issueDescriptionForTarget(node, description)
        Arrows::getTargetsForSource(asteroid)
            .each{|target| 

                # There is a tiny thing we are going to do here:
                # If the target is a data point that is a NybHub and if that NyxHub is pointing at "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-NyxHubs"
                # Then we move it to a DataNetwork location

                if GenericObjectInterface::isDataPoint(target) then
                    if target["type"] == "NyxHub" then
                        location = DatapointNyxElementLocation::getLocationByAllMeansOrNull(target)
                        if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-NyxHubs" then
                            # Ne need to move that thing somewhere else.
                            newEnvelopFolderPath = "/Users/pascal/Galaxy/Timeline/#{Time.new.strftime("%Y")}/DataNetwork/#{Time.new.strftime("%Y-%m")}/#{Miscellaneous::l22()}"
                            if !File.exists?(newEnvelopFolderPath) then
                                FileUtils.mkpath(newEnvelopFolderPath)
                            end
                            LucilleCore::copyFileSystemLocation(File.dirname(location), newEnvelopFolderPath)
                            LucilleCore::removeFileSystemLocation(File.dirname(location))
                            GalaxyFinder::registerElementNameAtLocation(target["name"], "#{newEnvelopFolderPath}/#{target["name"]}")
                        end
                    end
                end

                Arrows::issueOrException(node, target) 
            }
        SelectionLookupDataset::updateLookupForNode(node)
        NSDataType1::landing(node)
        NyxObjects2::destroy(asteroid) # We destroy the asteroid itself and not doing Asteroids::destroy(asteroid) because we are keeping the children by default.
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

    # Asteroids::naturalNextOperation(asteroid)
    def self.naturalNextOperation(asteroid)

        uuid = asteroid["uuid"]

        # ----------------------------------------
        # Not Running

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
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

                if GenericObjectInterface::isDataPoint(target) then
                    NSDataPoint::accessopen(target)
                end

                Asteroids::stopAsteroidIfRunning(asteroid)

                # recasting

                modes = [
                    "landing",
                    "DoNotDisplay for a time",
                    "todo today",
                    "to queue",
                    "re orbital",
                    "transmute to node",
                    "destroy"
                ]
                mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", modes)
                return if mode.nil?
                if mode == "landing" then
                    Asteroids::landing(asteroid)
                    return
                end
                if mode == "DoNotDisplay for a time" then
                    timespanInDays = LucilleCore::askQuestionAnswerAsString("timespan in days: ").to_f
                    DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+86400*timespanInDays)
                    return
                end
                if mode == "todo today" then
                    asteroid["orbital"] = {
                        "type" => "the-burner-07f24c2a-75da-4323-81bb-8c0e80a0"
                    }
                    Asteroids::commitToDisk(asteroid)
                    return
                end
                if mode == "to queue" then
                    asteroid["orbital"] = {
                        "type" => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
                    }
                    Asteroids::commitToDisk(asteroid)
                    return
                end
                if mode == "re orbital" then
                    Asteroids::reOrbitalOrNothing(asteroid)
                    return
                end
                if mode == "transmute to node" then
                    Asteroids::transmuteAsteroidToNode(asteroid)
                    return
                end
                if mode == "destroy" then
                    Asteroids::destroy(asteroid)
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
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::stopAsteroidIfRunning(asteroid)
                Asteroids::destroy(asteroid)
            end
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "the-burner-07f24c2a-75da-4323-81bb-8c0e80a0" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            modes = [
                "done/destroy",
                "just start",
                "stop/push/rotate"
            ]
            mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", modes)
            return if mode.nil?
            if mode == "done/destroy" then
                Asteroids::stopAsteroidIfRunning(asteroid)
                Asteroids::destroy(asteroid)
                return
            end
            if mode == "just start" then
                return
            end
            if mode == "stop/push/rotate" then
                Asteroids::stopAsteroidIfRunning(asteroid)
                asteroid["unixtime"] = Time.new.to_i
                NyxObjects2::put(asteroid)
                KeyValueStore::set(nil, "BurnerCycleTime-F8E4-49A5-87E3-99EADB61EF64-#{asteroid["uuid"]}", 0)
                return
            end
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::stopAsteroidIfRunning(asteroid)
                Asteroids::destroy(asteroid)
            end
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

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::destroy(asteroid)
            end
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "the-burner-07f24c2a-75da-4323-81bb-8c0e80a0" then
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

            puts "uuid: #{asteroid["uuid"]}".yellow
            puts "orbital: #{JSON.generate(asteroid["orbital"])}".yellow
            if asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
                if asteroid["orbital"]["days"] then
                    puts "on days: #{asteroid["orbital"]["days"].join(", ")}".yellow
                end
            end
            puts "BankExtended::recoveredDailyTimeInHours(bankuuid): #{BankExtended::recoveredDailyTimeInHours(asteroid["uuid"])}".yellow
            puts "metric: #{Asteroids::metric(asteroid)}".yellow

            unixtime = DoNotShowUntil::getUnixtimeOrNull(asteroid["uuid"])
            if unixtime and (Time.new.to_i < unixtime) then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}".yellow
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
                "update asteroid description".yellow,
                lambda { 
                    description = LucilleCore::askQuestionAnswerAsString("description: ")
                    return if description == ""
                    NSDataTypeXExtended::issueDescriptionForTarget(asteroid, description)
                    KeyValueStore::destroy(nil, "f16f78bd-c5a1-490e-8f28-9df73f43733d:#{asteroid["uuid"]}")
                }
            )

            menuitems.item(
                "start".yellow,
                lambda { Asteroids::startAsteroidIfNotRunning(asteroid) }
            )

            menuitems.item(
                "stop".yellow,
                lambda { Asteroids::stopAsteroidIfRunning(asteroid) }
            )

            menuitems.item(
                "re-orbital".yellow,
                lambda { Asteroids::reOrbitalOrNothing(asteroid) }
            )

            menuitems.item(
                "edit note".yellow,
                lambda{ 
                    text = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(asteroid) || ""
                    text = Miscellaneous::editTextSynchronously(text).strip
                    NSDataTypeXExtended::issueNoteForTarget(asteroid, text)
                }
            )

            menuitems.item(
                "show json".yellow,
                lambda {
                    puts JSON.pretty_generate(asteroid)
                    LucilleCore::pressEnterToContinue()
                }
            )

            menuitems.item(
                "add time".yellow,
                lambda {
                    timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                    Asteroids::asteroidReceivesTime(asteroid, timeInHours*3600)
                }
            )

            menuitems.item(
                "transmute to node".yellow,
                lambda {
                    Asteroids::transmuteAsteroidToNode(asteroid)
                }
            )

            menuitems.item(
                "destroy".yellow,
                lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this asteroid ? ") then
                        Asteroids::stopAsteroidIfRunningAndDestroy(asteroid)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            targets = Arrows::getTargetsForSource(asteroid)
            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
            targets.each{|object|
                    menuitems.item(
                        GenericObjectInterface::toString(object),
                        lambda { GenericObjectInterface::landing(object) }
                    )
                }

            puts ""

            menuitems.item(
                "add new target".yellow,
                lambda { 
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", ["new node", "existing node", "datapoint"])
                    return if option.nil?
                    if option == "new node" then
                        node = NSDataType1::issueNewNodeInteractivelyOrNull()
                        return if node.nil?
                        Arrows::issueOrException(asteroid, node)
                    end
                    if option == "existing node" then
                        node = NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                        return if node.nil?
                        Arrows::issueOrException(asteroid, node)
                    end
                    if option == "datapoint" then
                        datapoint = NSDataPoint::issueNewPointInteractivelyOrNull()
                        return if datapoint.nil?
                        Arrows::issueOrException(asteroid, datapoint)
                    end
                }
            )

            menuitems.item(
                "select target ; destroy".yellow,
                lambda {

                    targets = Arrows::getTargetsForSource(asteroid)
                    targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)

                    target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda{|target| GenericObjectInterface::toString(target) })
                    return if target.nil?
                    GenericObjectInterface::destroy(target)
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.promptAndRunSandbox()
            break if !status

        }

        SelectionLookupDataset::updateLookupForAsteroid(asteroid)
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
                asteroid = Asteroids::issuePlainAsteroidInteractivelyOrNull()
                next if asteroid.nil?
                puts JSON.pretty_generate(asteroid)
                Asteroids::landing(asteroid)
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
        targets = Arrows::getTargetsForSource(asteroid)
        if targets.size > 0 then
            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
            targets.each{|target|
                if Arrows::getSourcesForTarget(target).size == 1 then
                    GenericObjectInterface::destroy(target) # The only source is the asteroid itself.
                else
                    puts "A child of this asteroid has more than one parent:"
                    puts "   -> child: '#{GenericObjectInterface::toString(target)}'"
                    Arrows::getSourcesForTarget(target).each{|source|
                        puts "   -> parent: '#{GenericObjectInterface::toString(source)}'"
                    }
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{GenericObjectInterface::toString(target)}' ? ") then
                        GenericObjectInterface::destroy(target)
                    end
                end
            }
        end
        NyxObjects2::destroy(asteroid)
    end

    # ------------------------------------------------------------------
end
