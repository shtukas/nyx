# encoding: UTF-8

class Asteroids

    # -------------------------------------------------------------------
    # Building

    # Asteroids::makeOrbitalInteractivelyOrNull()
    def self.makeOrbitalInteractivelyOrNull()

        options = [
            "inbox",
            "repeating daily time commitment",
            "burner",
            "stream",
        ]

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", options)
        return nil if option.nil?
        if option == "inbox" then
            return {
                "type"                  => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
            }
        end
        if option == "repeating daily time commitment" then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "repeating-daily-time-commitment-8123956c-05",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == "burner" then
            return {
                "type"                  => "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
            }
        end
        if option == "stream" then
            return {
                "type"                  => "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
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
            "orbital"  => orbital,
            "description" => description
        }
        Asteroids::commitToDisk(asteroid)
        asteroid
    end

    # Asteroids::issueDatapointAndAsteroidInteractivelyOrNull()
    def self.issueDatapointAndAsteroidInteractivelyOrNull()
        datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
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
            "repeating-daily-time-commitment-8123956c-05",
            "burner-5d333e86-230d-4fab-aaee-a5548ec4b955",
            "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
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
        return "📥"  if type == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        return "💫"  if type == "repeating-daily-time-commitment-8123956c-05"
        return "☀️ " if type == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
        return "😴"  if type == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
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
        return asteroid["description"] if asteroid["description"]
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

    # Asteroids::runTimeIfAny(asteroid)
    def self.runTimeIfAny(asteroid)
        uuid = asteroid["uuid"]
        Runner::runTimeInSecondsOrNull(uuid) || 0
    end

    # Asteroids::bankValueLive(asteroid)
    def self.bankValueLive(asteroid)
        Bank::value(asteroid["uuid"]) + Asteroids::runTimeIfAny(asteroid)
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
            "x-asteroid"       => asteroid,
            "x-burner-domain"  => Asteroids::getBurnerDomainForAsteroidOrNull(asteroid)
        }
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()
        Asteroids::asteroids()
            .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
            .reduce([]) {|asteroids, asteroid|
                if asteroid["orbital"]["type"] != "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
                    asteroids + [ asteroid ]
                else
                    if asteroids.select{|a| a["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" }.size < 100 then
                        asteroids + [ asteroid ]
                    else
                        asteroids
                    end
                end
            }
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
    end

    # -------------------------------------------------------------------
    # Burner Domains and Metric

    # Asteroids::burnerDomains()
    def self.burnerDomains()
        [
            {
                "uuid" => "d153fabc-c630-48e9-b2a2-9a41e7e16cbb", # time in hours
                "membershipTimeMinInHours" => 0.00,
                "description" => "less than one hour"
            },
            {
                "uuid" => "974e342c-d59c-418f-b7c5-2d226741e1d7", # time in hours
                "membershipTimeMinInHours" => 1.00,
                "description" => "one hour to two hours"
            },
            {
                "uuid" => "a7181b61-2947-48d4-9406-8cf03829d3e6", # time in hours
                "membershipTimeMinInHours" => 2.00,
                "description" => "two hours to five hours"
            },
            {
                "uuid" => "5ade4a92-9ea2-4c54-b7a1-a2419f27fea8", # time in hours
                "membershipTimeMinInHours" => 5.00,
                "description" => "five hours to fifty hours"
            },
            {
                "uuid" => "dc94dd04-f0bb-47b7-8c4e-131a7d10c594", # time in hours
                "membershipTimeMinInHours" => 50.0,
                "description" => "fifty hours to infinity"
            }
        ]
    end

    # Asteroids::burnerDomainsWithExtraDataInRecoveredDailyTimeInHoursOrder()
    def self.burnerDomainsWithExtraDataInRecoveredDailyTimeInHoursOrder()
        Asteroids::burnerDomains()
            .map{|domain|
                domain["recoveredDailyTimeInHours"] = BankExtended::recoveredDailyTimeInHours(domain["uuid"])
                domain
            }
            .sort{|d1, d2| d1["recoveredDailyTimeInHours"] <=> d2["recoveredDailyTimeInHours"] }
            .zip([0.6, 0.5, 0.4, 0.3, 0.35])
            .map{|pair| 
                domain = pair[0]
                domain["basemetric"] = pair[1]
                domain
            }
    end

    # Asteroids::getBurnerDomainForAsteroidOrNull(asteroid)
    def self.getBurnerDomainForAsteroidOrNull(asteroid)
        return nil if asteroid["orbital"]["type"] != "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
        Asteroids::burnerDomains()
            .select{|domain| domain["membershipTimeMinInHours"] <= Bank::value(asteroid["uuid"]).to_f/3600 }
            .first
    end

    # Asteroids::burnerMetric(asteroid)
    def self.burnerMetric(asteroid)
        asteroidDomain = Asteroids::getBurnerDomainForAsteroidOrNull(asteroid)
        if asteroidDomain.nil? then
            puts asteroid
            raise "error: 2c2a9f88-d7f9-4ba4-8a27-f2b93b491e64"
        end
        basemetric = Asteroids::burnerDomainsWithExtraDataInRecoveredDailyTimeInHoursOrder().select{|domain| domain["uuid"] == asteroidDomain["uuid"] }.first["basemetric"]
        basemetric - 0.01 * BankExtended::recoveredDailyTimeInHours(asteroid["uuid"])
    end

    # Asteroids::metric(asteroid)
    def self.metric(asteroid)
        uuid = asteroid["uuid"]

        orbital = asteroid["orbital"]

        return 1 if Asteroids::isRunning?(asteroid)

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

        if orbital["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            return Asteroids::burnerMetric(asteroid)
        end

        if orbital["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            return 0.00 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        puts asteroid
        raise "[Asteroids] error: 46b84bdb"
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

        # It's important to update the current domain before we add the time to the asteroid
        burnerDomain = Asteroids::getBurnerDomainForAsteroidOrNull(asteroid)
        if burnerDomain then
            Bank::put(burnerDomain["uuid"], timespanInSeconds.to_f/3600) # Time in hours
        end

        Bank::put(asteroid["uuid"], timespanInSeconds)
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
            if GenericObjectInterface::isDataPoint(target) then
                NSNode1638::nsopen(target)
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
        node = NSNode1638::issueNavigation(description)
        Arrows::getTargetsForSource(asteroid)
            .each{|target| 

                # There is a tiny thing we are going to do here:
                # If the target is a data point that is a NybHub and if that NyxDirectory is pointing at "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-NyxDirectories"
                # Then we move it to a CatalystElements location

                if GenericObjectInterface::isDataPoint(target) then
                    if target["type"] == "NyxDirectory" then
                        location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(target)
                        if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-NyxDirectories" then
                            # Ne need to move that thing somewhere else.
                            newEnvelopFolderPath = "/Users/pascal/Galaxy/Timeline/#{Time.new.strftime("%Y")}/CatalystElements/#{Time.new.strftime("%Y-%m")}/#{Miscellaneous::l22()}"
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
        NyxObjects2::destroy(asteroid) # We destroy the asteroid itself and not doing Asteroids::destroy(asteroid) because we are keeping the children by default.
        SelectionLookupDataset::updateLookupForNode(node)
        NSNode1638::access(node)
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

                if GenericObjectInterface::isDataPoint(target) then
                    NSNode1638::nsopen(target)
                end

                Asteroids::stopAsteroidIfRunning(asteroid)

                # recasting

                modes = [
                    "landing",
                    "DoNotDisplay for a time",
                    "to burner",
                    "to stream",
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
                if mode == "to burner" then
                    asteroid["orbital"]["type"] = "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
                    Asteroids::commitToDisk(asteroid)
                    return
                end
                if mode == "to stream" then
                    asteroid["orbital"]["type"] = "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
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

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::openTargetOrTargets(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
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

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::destroy(asteroid)
            end
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            return
        end
    end

    # Asteroids::accessAsteroidTarget(object)
    def self.accessAsteroidTarget(object)
        menuitems = LCoreMenuItemsNX1.new()
        menuitems.item(
            "open",
            lambda { GenericObjectInterface::access(object) }
        )
        menuitems.item(
            "landing",
            lambda { GenericObjectInterface::access(object) }
        )
        menuitems.promptAndRunSandbox()
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
            puts "metric: #{Asteroids::metric(asteroid)}".yellow

            unixtime = DoNotShowUntil::getUnixtimeOrNull(asteroid["uuid"])
            if unixtime and (Time.new.to_i < unixtime) then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}".yellow
            end

            puts ""

            menuitems.item(
                "update asteroid description".yellow,
                lambda { 
                    description = LucilleCore::askQuestionAnswerAsString("description: ")
                    return if description == ""
                    asteroid["description"] = description
                    NyxObjects2::put(asteroid)
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
                        lambda { Asteroids::accessAsteroidTarget(object) }
                    )
                }

            puts ""

            menuitems.item(
                "add new target".yellow,
                lambda { 
                    datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
                    return if datapoint.nil?
                    Arrows::issueOrException(asteroid, datapoint)
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
