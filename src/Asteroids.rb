# encoding: UTF-8

class Asteroids

    # -------------------------------------------------------------------
    # Building

    # Asteroids::asteroidOrbitalTypes()
    def self.asteroidOrbitalTypes()
        [
            "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860",
            "burner-5d333e86-230d-4fab-aaee-a5548ec4b955",
            "daily-time-commitment-e1180643-fc7e-42bb-a2",
            "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c",
            "project-2d6ad423-4159-4091-a1c8-c8904996e43",
        ]
    end

    # Asteroids::makeOrbitalInteractivelyOrNull()
    def self.makeOrbitalInteractivelyOrNull()
        orbitalTypes = Asteroids::asteroidOrbitalTypes()
        orbitalType = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital type", orbitalTypes)
        return nil if orbitalType.nil?
        if orbitalType == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return {
                "type" => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
            }
        end
        if orbitalType == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            return {
                "type" => "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
            }
        end
        if orbitalType == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            return {
                "type" => "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c",
                "time-commitment-in-hours" => LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            }
        end
        if orbitalType == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            return {
                "type" => "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
            }
        end
        if orbitalType == "project-2d6ad423-4159-4091-a1c8-c8904996e43" then
            return {
                "type" => "project-2d6ad423-4159-4091-a1c8-c8904996e43"
            }
        end
        raise "ef349b18-55ed-4fdb-abb0-1014f752416a"
    end

    # Asteroids::issuePlainAsteroidInteractivelyOrNull()
    def self.issuePlainAsteroidInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("asteroid description: ")
        return nil if (description == "")
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return nil if orbital.nil?
        asteroid = {
            "uuid"        => SecureRandom.hex,
            "nyxNxSet"    => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"    => Time.new.to_f,
            "orbital"     => orbital,
            "description" => description
        }
        NyxObjects2::put(asteroid)
        asteroid
    end

    # Asteroids::issueDatapointAndAsteroidInteractivelyOrNull()
    def self.issueDatapointAndAsteroidInteractivelyOrNull()
        datapoint = Datapoints::makeNewDatapointOrNull()
        return if datapoint.nil?
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return nil if orbital.nil?
        asteroid = {
            "uuid"       => SecureRandom.hex,
            "nyxNxSet"   => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"   => Time.new.to_f,
            "orbital"    => orbital,
        }
        NyxObjects2::put(asteroid)
        Arrows::issueOrException(asteroid, datapoint)
        asteroid
    end

    # Asteroids::issueAsteroidInboxFromQuark(quark)
    def self.issueAsteroidInboxFromQuark(quark)
        orbital = {
            "type" => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        }
        asteroid = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "orbital"  => orbital,
        }
        NyxObjects2::put(asteroid)
        Arrows::issueOrException(asteroid, quark)
        asteroid
    end

    # Asteroids::issueAsteroidBurnerFromQuark(quark)
    def self.issueAsteroidBurnerFromQuark(quark)
        orbital = {
            "type" => "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
        }
        asteroid = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"   => Time.new.to_f,
            "orbital"    => orbital,
        }
        NyxObjects2::put(asteroid)
        Arrows::issueOrException(asteroid, quark)
        asteroid
    end

    # -------------------------------------------------------------------
    # Data Extraction

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

    # Asteroids::asteroidOrbitalAsUserFriendlyString(orbital)
    def self.asteroidOrbitalAsUserFriendlyString(orbital)
        return "📥" if orbital["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        return "🔥" if orbital["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
        return "👩‍💻" if orbital["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
        return "💫" if orbital["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2"
        return "🧘‍♂️" if orbital["type"] == "project-2d6ad423-4159-4091-a1c8-c8904996e43"
    end

    # Asteroids::asteroidDescription(asteroid)
    def self.asteroidDescription(asteroid)
        if asteroid["description"] then
            return "asteroid description: #{asteroid["description"]} (#{Arrows::getTargetsForSource(asteroid).size} targets)"
        end
        Arrows::getTargetsForSource(asteroid).each{|target|
            return GenericNyxObject::toString(target)
        }
        "no description / no target"
    end

    # Asteroids::toString(asteroid)
    def self.toString(asteroid)
        uuid = asteroid["uuid"]
        isRunning = Runner::isRunning?(uuid)
        p1 = "[asteroid]"
        p2 = " #{Asteroids::asteroidOrbitalAsUserFriendlyString(asteroid["orbital"])}"
        p3 = " #{Asteroids::asteroidDescription(asteroid)}"
        p4 =
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        p5 = (lambda {|asteroid|
            return "" if asteroid["orbital"]["type"] != "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
            return "" if asteroid["x-stream-index"].nil?
            targetHours = 1.to_f/(2**asteroid["x-stream-index"]) # For index 0 that's 1 hour, so total two hours commitment per day
            ratio = BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/targetHours
            return " (#{(100*ratio).round(2)} % completed)"
        }).call(asteroid)

        p6 = (lambda {|asteroid|
            return "" if asteroid["orbital"]["type"] != "daily-time-commitment-e1180643-fc7e-42bb-a2"
            commitmentInHours = asteroid["orbital"]["time-commitment-in-hours"]
            ratio = BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/commitmentInHours
            return " (#{asteroid["orbital"]["time-commitment-in-hours"]} hours, #{(100*ratio).round(2)} % completed)"
        }).call(asteroid)

        p7 = " (metric: #{Asteroids::metric(asteroid).round(3)})"

        "#{p1}#{p2}#{p3}#{p4}#{p5}#{p6}#{p7}"
    end

    # Asteroids::opsNodesMetadata(asteroid)
    def self.opsNodesMetadata(asteroid)
        return "" if asteroid["orbital"]["type"] != "daily-time-commitment-e1180643-fc7e-42bb-a2"
        commitmentInHours = asteroid["orbital"]["time-commitment-in-hours"]
        ratio = BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/commitmentInHours
        return "(#{asteroid["orbital"]["time-commitment-in-hours"]} hours, #{(100*ratio).round(2)} % completed)"
    end

    # Asteroids::naturalOrdinalShift(asteroid)
    def self.naturalOrdinalShift(asteroid)
        bounds = JSON.parse(KeyValueStore::getOrNull(nil, "af59dd5d-135d-46c1-ab9a-65f54582266d"))
        ( asteroid["unixtime"]-bounds["lower"] ).to_f/( bounds["upper"] - bounds["lower"] )
    end

    # Asteroids::isRunning?(asteroid)
    def self.isRunning?(asteroid)
        Runner::isRunning?(asteroid["uuid"])
    end

    # Asteroids::isRunningForLong?(asteroid)
    def self.isRunningForLong?(asteroid)
        return false if !Asteroids::isRunning?(asteroid)
        ( Runner::runTimeInSecondsOrNull(asteroid["uuid"]) || 0 ) > 3600
    end

    # Asteroids::metric(asteroid)
    def self.metric(asteroid)
        uuid = asteroid["uuid"]

        return 1 if Asteroids::isRunning?(asteroid)

        if asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return 0.70 - 0.01*Asteroids::naturalOrdinalShift(asteroid)
        end

        if asteroid["orbital"]["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            if BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f < asteroid["orbital"]["time-commitment-in-hours"] then
                return 0.65 - 0.05*BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/asteroid["orbital"]["time-commitment-in-hours"]
            end
            return 0
        end

        if asteroid["orbital"]["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            return 0.6 - 0.01*Asteroids::naturalOrdinalShift(asteroid)
        end

        if asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            if asteroid["x-stream-index"].nil? then
                # This never happens during a regular Asteroids::catalystObjects() call, but can happen if this function is manually called on an asteroid
                return 0
            end
            targetHours = 1.to_f/(2**asteroid["x-stream-index"]) # For index 0 that's 1 hour, so total two hours commitment per day
            if BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f < 1.to_f/(2**asteroid["x-stream-index"]) then
                return 0.50 - 0.001*asteroid["x-stream-index"] # smaller indices first
            end
            return 0
        end

        if asteroid["orbital"]["type"] == "project-2d6ad423-4159-4091-a1c8-c8904996e43" then
            return 0
        end

        puts asteroid
        raise "[Asteroids] error: 46b84bdb"
    end

    # Asteroids::asteroidToCalalystObjects(asteroid)
    def self.asteroidToCalalystObjects(asteroid)
        uuid = asteroid["uuid"]
        isRunning = Asteroids::isRunning?(asteroid)

        metric = Asteroids::metric(asteroid)

        object = {
            "uuid"             => uuid,
            "body"             => Asteroids::toString(asteroid),
            "metric"           => metric,
            "landing"          => lambda { Asteroids::landing(asteroid) },
            "nextNaturalStep"  => lambda { Asteroids::naturalNextOperation(asteroid) },
            "isRunning"        => isRunning,
            "isRunningForLong" => Asteroids::isRunningForLong?(asteroid),
            "x-asteroid"       => asteroid,
        }

        targetsOpsNodes = Arrows::getTargetsForSource(asteroid)
                              .select{|target| GenericNyxObject::isOpsNode(target) }

        object["metric"] = 0 if !targetsOpsNodes.empty?

        secondaryObjects = targetsOpsNodes
                                .map{|target|
                                    if GenericNyxObject::isOpsNode(target) then
                                        OpsNodes::nodeToCatalystObjects(target, metric, uuid, Asteroids::opsNodesMetadata(asteroid))
                                    else
                                        []
                                    end
                                }
                                .flatten

        [object] + secondaryObjects
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()

        asteroids = Asteroids::asteroids()

        return [] if asteroids.empty?

        bounds = {
            "lower" => asteroids.map{|asteroid| asteroid["unixtime"] }.min,
            "upper" => asteroids.map{|asteroid| asteroid["unixtime"] }.max
        }

        KeyValueStore::set(nil, "af59dd5d-135d-46c1-ab9a-65f54582266d", JSON.generate(bounds))

        if !KeyValueStore::flagIsTrue(nil, "a3bd01f1-5366-4543-83aa-04477ec5f068:#{Miscellaneous::today()}") then

            # Removing the x-stream-index marks from the day before
            asteroids
                .select{|asteroid| asteroid["x-stream-index"] }
                .each{|asteroid|
                    asteroid.delete("x-stream-index")
                    NyxObjects2::put(asteroid)
                }

            # Marking 100 objects for today
            asteroids
                .select{|asteroid| asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" }
                .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
                .first(100)
                .each_with_index{|asteroid, indx|
                    asteroid["x-stream-index"] = indx
                    NyxObjects2::put(asteroid)
                }

            KeyValueStore::setFlagTrue(nil, "a3bd01f1-5366-4543-83aa-04477ec5f068:#{Miscellaneous::today()}")

        end

        asteroids = asteroids
                        .select{|asteroid| 
                            b1 = (asteroid["orbital"]["type"] != "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c")
                            b2 = asteroid["x-stream-index"]
                            b1 or b2
                        }

        catalystObjects = asteroids
                            .map{|asteroid| Asteroids::asteroidToCalalystObjects(asteroid) }
                            .flatten
                            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                            .reverse

        # Removing any first asteroid with no target
        if catalystObjects.size > 0 then
            if asteroid = catalystObjects[0]["x-asteroid"] then
                if Arrows::getTargetsForSource(asteroid).size == 0 then
                    NyxObjects2::destroy(asteroid)
                    return Asteroids::catalystObjects()
                end
            end
        end

        catalystObjects
    end

    # -------------------------------------------------------------------
    # Operations

    # Asteroids::reOrbitalOrNothing(asteroid)
    def self.reOrbitalOrNothing(asteroid)
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        asteroid["orbital"] = orbital
        puts JSON.pretty_generate(asteroid)
        NyxObjects2::put(asteroid)
    end

    # Asteroids::asteroidReceivesTime(asteroid, timespanInSeconds)
    def self.asteroidReceivesTime(asteroid, timespanInSeconds)
        puts "Adding #{timespanInSeconds} seconds to #{Asteroids::toString(asteroid)}"
        Bank::put(asteroid["uuid"], timespanInSeconds)
        puts "Adding #{timespanInSeconds} seconds to #{asteroid["orbital"]["type"]}"
        Bank::put(asteroid["orbital"]["type"], timespanInSeconds)
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

    # Asteroids::access(asteroid)
    def self.access(asteroid)
        targets = Arrows::getTargetsForSource(asteroid)
        if targets.size == 0 then
            return
        end
        if targets.size == 1 then
            GenericNyxObject::access(targets[0])
            return
        end
        loop {
            system("clear")
            puts Asteroids::toString(asteroid)
            puts ""
            targets = Arrows::getTargetsForSource(asteroid)
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda{ |object| GenericNyxObject::toString(object) })
            return if target.nil?
            GenericNyxObject::access(target)
        }
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

    # Asteroids::runAsteroidForPossibleDeletion(asteroid)
    def self.runAsteroidForPossibleDeletion(asteroid)
        Asteroids::startAsteroidIfNotRunning(asteroid)
        Asteroids::access(asteroid)
        loop {

            menuitems = LCoreMenuItemsNX1.new()

            menuitems.item(
                "destroy asteroid and targets".yellow,
                lambda { 
                    Arrows::getTargetsForSource(asteroid).each{|target|
                        next if Arrows::getSourcesForTarget(target).size > 1
                        if GenericNyxObject::isNGX15(target) then
                            status = NGX15::ngx15TerminationProtocolReturnBoolean(target)
                            return if !status
                            next
                        end
                        if GenericNyxObject::isQuark(target) then
                            Quarks::destroyQuarkAndLepton(target)
                            next
                        end
                        puts target
                        raise "exception: 2f64e981-a5cb-401d-8532-7eca19e82adc"
                    }
                    NyxObjects2::destroy(asteroid)
                }
            )

            menuitems.item(
                "move targets ; destroy asteroid".yellow,
                lambda {
                    Arrows::getTargetsForSource(asteroid).each{|target|
                        xnode = XNodes::selectExistingXNodeOrMakeANewXNodeOrNull()
                        return if xnode.nil?
                        Arrows::issueOrException(xnode, target)
                        Arrows::unlink(asteroid, target)
                    }
                    NyxObjects2::destroy(asteroid)
                }
            )

            status = menuitems.promptAndRunSandbox()
            break if !status

            break if Asteroids::getAsteroidOrNull(asteroid["uuid"]).nil?
        }
        Asteroids::stopAsteroidIfRunning(asteroid)
    end

    # Asteroids::naturalNextOperation(asteroid)
    def self.naturalNextOperation(asteroid)

        uuid = asteroid["uuid"]

        if asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            Asteroids::runAsteroidForPossibleDeletion(asteroid)
            return
        end

        if asteroid["orbital"]["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            Asteroids::runAsteroidForPossibleDeletion(asteroid)
            return
        end

        if asteroid["orbital"]["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            if Asteroids::isRunning?(asteroid) then
                Asteroids::stopAsteroidIfRunning(asteroid)
            else
                Asteroids::startAsteroidIfNotRunning(asteroid)
                Asteroids::access(asteroid)
                if !LucilleCore::askQuestionAnswerAsBoolean("keep running ? ", true) then
                    Asteroids::stopAsteroidIfRunning(asteroid)
                end
            end
            return
        end

        if asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            Asteroids::runAsteroidForPossibleDeletion(asteroid)
        end
    end

    # Asteroids::selectAsteroidTargetsMoveThemToListingsPossiblyDestroyAsteroid(asteroid)
    def self.selectAsteroidTargetsMoveThemToListingsPossiblyDestroyAsteroid(asteroid)
        Arrows::getTargetsForSource(asteroid).each{|target|
            puts "Moving target: #{GenericNyxObject::toString(target)}"
            xnode = XNodes::selectExistingXNodeOrMakeANewXNodeOrNull()
            next if xnode.nil?
            Arrows::issueOrException(xnode, target)
            Arrows::unlink(asteroid, target)
        }
        return if Arrows::getTargetsForSource(asteroid).size > 0
        if Arrows::getTargetsForSource(asteroid).size == 0 then
            NyxObjects2::destroy(asteroid)
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
            puts "bank value: #{Bank::value(asteroid["uuid"])}".yellow
            puts "metric: #{Asteroids::metric(asteroid)}".yellow
            puts "x-stream-index: #{asteroid["x-stream-index"]}".yellow

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

            menuitems.item("hide for one hour".yellow, lambda {
                Asteroids::stopAsteroidIfRunning(asteroid)
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+3600)
            })

            menuitems.item("hide until tomorrow".yellow, lambda {
                Asteroids::stopAsteroidIfRunning(asteroid)
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+3600*(24-Time.new.hour))
            })

            menuitems.item("hide for n days".yellow, lambda {
                Asteroids::stopAsteroidIfRunning(asteroid)
                timespanInDays = LucilleCore::askQuestionAnswerAsString("timespan in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+86400*timespanInDays)
            })

            menuitems.item("to orbital burner".yellow, lambda {
                Asteroids::stopAsteroidIfRunning(asteroid)
                asteroid["orbital"] = {
                    "type" => "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
                }
                NyxObjects2::put(asteroid)
            })

            menuitems.item("to orbital stream".yellow, lambda {
                Asteroids::stopAsteroidIfRunning(asteroid)
                asteroid["orbital"] = {
                    "type" => "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
                }
                NyxObjects2::put(asteroid)
            })

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
                "destroy".yellow,
                lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this asteroid ? ") then
                        Asteroids::stopAsteroidIfRunning(asteroid)
                        Asteroids::asteroidTerminationProtocol(asteroid)
                    end
                }
            )

            puts ""

            menuitems.item(
                "add new target".yellow,
                lambda { 
                    datapoint = Datapoints::makeNewDatapointOrNull()
                    return if datapoint.nil?
                    Arrows::issueOrException(asteroid, datapoint)
                }
            )

            menuitems.item(
                "select targets ; move them to listing ; destroy asteroid".yellow,
                lambda {
                    Asteroids::selectAsteroidTargetsMoveThemToListingsPossiblyDestroyAsteroid(asteroid)
                }
            )

            menuitems.item(
                "select and destroy target".yellow,
                lambda {
                    target = GenericNyxObject::selectOneTargetOrNullDefaultToSingletonWithConfirmation(asteroid)
                    return if target.nil?
                    GenericNyxObject::destroy(target)
                }
            )

            puts ""

            Arrows::getTargetsForSource(asteroid).each{|target|
                menuitems.item(
                    "target: #{GenericNyxObject::toString(target)}",
                    lambda { GenericNyxObject::landing(target) }
                )
            }

            puts ""

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

    # Asteroids::asteroidTerminationProtocol(asteroid)
    def self.asteroidTerminationProtocol(asteroid)
        Asteroids::stopAsteroidIfRunning(asteroid)
        puts "destroying asteroid: #{Asteroids::toString(asteroid)}"
        Arrows::getTargetsForSource(asteroid).each{|target|
            next if Arrows::getSourcesForTarget(target).size > 1
            puts "target: '#{GenericNyxObject::toString(target)}'"
            if !LucilleCore::askQuestionAnswerAsBoolean("    -> destroy ? ") then
                if LucilleCore::askQuestionAnswerAsBoolean("    -> landing ? ") then
                    GenericNyxObject::landing(target)
                end
                next
            end
            if GenericNyxObject::isNGX15(target) then
                status = NGX15::ngx15TerminationProtocolReturnBoolean(target)
                return if !status
                next
            end
            if GenericNyxObject::isQuark(target) then
                Quarks::destroyQuarkAndLepton(target)
                next
            end
            puts target
            raise "exception: 5e7c6b48-c920-4474-bb81-25146307bd35"
        }
        NyxObjects2::destroy(asteroid)
    end

    # ------------------------------------------------------------------
end
