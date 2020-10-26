# encoding: UTF-8

class Asteroids

    # -------------------------------------------------------------------
    # Building

    # Asteroids::asteroidOrbitalTypes()
    def self.asteroidOrbitalTypes()
        [
            "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860",
            "burner-5d333e86-230d-4fab-aaee-a5548ec4b955",
            "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c",
            "daily-time-commitment-e1180643-fc7e-42bb-a2",
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
            "ordinal"     => Asteroids::ordinalMax()+1,
            "description" => description
        }
        NyxObjects2::put(asteroid)
        asteroid
    end

    # Asteroids::issueDatapointAndAsteroidInteractivelyOrNull()
    def self.issueDatapointAndAsteroidInteractivelyOrNull()
        datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
        return if datapoint.nil?
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return nil if orbital.nil?
        asteroid = {
            "uuid"       => SecureRandom.hex,
            "nyxNxSet"   => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"   => Time.new.to_f,
            "orbital"    => orbital,
            "ordinal"    => Asteroids::ordinalMax()+1,
            "targetuuid" => datapoint["uuid"]
        }
        NyxObjects2::put(asteroid)
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
            "orbital"  => orbital,
            "ordinal"  => Asteroids::ordinalMax()+1,
            "targetuuid" => datapoint["uuid"]
        }
        NyxObjects2::put(asteroid)
        asteroid
    end

    # Asteroids::issueAsteroidAgainstExistigCubeInteractivelyOrNull()
    def self.issueAsteroidAgainstExistigCubeInteractivelyOrNull()
        cube = Cubes::selectCubeOrNull()
        return nil if cube.nil?
        orbital = {
            "type" => "daily-time-commitment-e1180643-fc7e-42bb-a2",
            "time-commitment-in-hours" => LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
        }
        asteroid = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "orbital"  => orbital,
            "ordinal"  => Asteroids::ordinalMax()+1,
            "targetuuid" => cube["uuid"]
        }
        NyxObjects2::put(asteroid)
        asteroid
    end

    # Asteroids::ordinalMax()
    def self.ordinalMax()
        ([0] + Asteroids::asteroids().map{|asteroid| asteroid["ordinal"] }).max
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

    # Asteroids::getAsteroidTargetOrNull(asteroid)
    def self.getAsteroidTargetOrNull(asteroid)
        return nil if asteroid["targetuuid"].nil?
        NyxObjects2::getOrNull(asteroid["targetuuid"])
    end

    # Asteroids::asteroidOrbitalAsUserFriendlyString(orbital)
    def self.asteroidOrbitalAsUserFriendlyString(orbital)
        return "📥" if orbital["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        return "🔥" if orbital["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
        return "👩‍💻" if orbital["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
        return "💫" if orbital["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2"
    end

    # Asteroids::asteroidDescription(asteroid)
    def self.asteroidDescription(asteroid)
        target = Asteroids::getAsteroidTargetOrNull(asteroid)
        if asteroid["description"] and target.nil? then
            return "line: #{asteroid["description"]}"
        end
        return "no target" if target.nil?
        NyxObjectInterface::toString(target)
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

        "#{p1}#{p2}#{p3}#{p4}#{p5}#{p6}"
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
                return 0.65 - 0.01*Asteroids::naturalOrdinalShift(asteroid)
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

        puts asteroid
        raise "[Asteroids] error: 46b84bdb"
    end

    # Asteroids::asteroidToCalalystObject(asteroid)
    def self.asteroidToCalalystObject(asteroid)
        executor = lambda { |command|
            if command == "c2c799b1-bcb9-4963-98d5-494a5a76e2e6" then
                Asteroids::naturalNextOperation(asteroid) 
            end
            if command == "ec23a3a3-bfa0-45db-a162-fdd92da87f64" then
                Asteroids::landing(asteroid) 
            end
        }

        uuid = asteroid["uuid"]
        isRunning = Asteroids::isRunning?(asteroid)

        {
            "uuid"             => uuid,
            "body"             => Asteroids::toString(asteroid),
            "metric"           => Asteroids::metric(asteroid),
            "execute"          => executor,
            "isRunning"        => isRunning,
            "isRunningForLong" => Asteroids::isRunningForLong?(asteroid),
            "x-asteroid"       => asteroid,
        }
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

            asteroids
                .select{|asteroid| asteroid["x-stream-index"] }
                .each{|asteroid|
                    asteroid.delete("x-stream-index")
                    NyxObjects2::put(asteroid)
                }

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

        asteroids
            .select{|asteroid| 
                b1 = (asteroid["orbital"]["type"] != "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c")
                b2 = asteroid["x-stream-index"]
                b1 or b2
            }
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
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

    # Asteroids::accessTarget(asteroid)
    def self.accessTarget(asteroid)
        target = Asteroids::getAsteroidTargetOrNull(asteroid)
        return if target.nil?
        if NyxObjectInterface::isDataPoint(target) then
            NSNode1638::opendatapoint(target)
            return
        end
        if NyxObjectInterface::isCube(target) then
            Cubes::landing(target)
            return
        end
    end

    # Asteroids::transmuteAsteroidToDatapoint(asteroid)
    def self.transmuteAsteroidToDatapoint(asteroid)

        target = Asteroids::getAsteroidTargetOrNull(asteroid)
        return if target.nil?
        return if NyxObjectInterface::isCube(target)

        puts "Transmuting asteroid to "

        Asteroids::stopAsteroidIfRunning(asteroid)

        if asteroid["targetuuid"].nil? then
            Asteroids::asteroidTerminationProtocol(asteroid)
            return
        end

        datapoint = NyxObjects2::getOrNull(asteroid["targetuuid"])

        if datapoint.nil? then
            Asteroids::asteroidTerminationProtocol(asteroid)
            return
        end

        description = LucilleCore::askQuestionAnswerAsString("datapoint description (empty to skip): ")
        if description != "" then
            datapoint["description"] = description
            NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(datapoint)
        end

        if datapoint["type"] == "NyxDirectory" then
            location = NSNode1638_FileSystemElements::getLocationByAllMeansOrNull(datapoint)
            if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-Items" then
                # Ne need to move that thing somewhere else.
                newEnvelopFolderPath = "/Users/pascal/Galaxy/Timeline/#{Time.new.strftime("%Y")}/Catalyst-Elements/#{Time.new.strftime("%Y-%m")}/#{Miscellaneous::l22()}"
                FileUtils.mkpath(newEnvelopFolderPath)
                LucilleCore::copyFileSystemLocation(location, newEnvelopFolderPath)
                LucilleCore::removeFileSystemLocation(File.dirname(location))
                GalaxyFinder::registerFilenameAtLocation(datapoint["name"], "#{newEnvelopFolderPath}/#{datapoint["name"]}")
            end
        end

        if datapoint["type"] == "NyxFSPoint001" then
            location = NSNode1638_FileSystemElements::getLocationByAllMeansOrNull(datapoint)
            if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-Items" then
                # Ne need to move that thing somewhere else.
                newEnvelopFolderPath = "/Users/pascal/Galaxy/Timeline/#{Time.new.strftime("%Y")}/Catalyst-Elements/#{Time.new.strftime("%Y-%m")}/#{Miscellaneous::l22()}"
                FileUtils.mkpath(newEnvelopFolderPath)
                LucilleCore::copyContents(File.dirname(location), newEnvelopFolderPath)
                LucilleCore::removeFileSystemLocation(File.dirname(location))
                GalaxyFinder::registerFilenameAtLocation(datapoint["name"], "#{newEnvelopFolderPath}/#{datapoint["name"]}")
            end
        end

        loop {
            set = Sets::selectExistingSetOrMakeNewOneOrNull()
            if set then
                Arrows::issueOrException(set, datapoint)
                next
            end
            break
        }

        NyxObjects2::destroy(asteroid) # Do not use Asteroids::asteroidTerminationProtocol here !
        NSNode1638::landing(datapoint)
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

        processor = lambda {|asteroid|

            mx = LCoreMenuItemsNX1.new()

            mx.item("landing".yellow, lambda {
                Asteroids::landing(asteroid)
            })

            mx.item("hide for one hour".yellow, lambda {
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+3600)
            })

            mx.item("hide until tomorrow".yellow, lambda {
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+3600*(24-Time.new.hour))
            })

            mx.item("hide for n days".yellow, lambda {
                timespanInDays = LucilleCore::askQuestionAnswerAsString("timespan in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+86400*timespanInDays)
            })

            mx.item("to burner".yellow, lambda {
                asteroid["orbital"] = {
                    "type" => "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
                }
                NyxObjects2::put(asteroid)
            })

            mx.item("to stream".yellow, lambda {
                asteroid["orbital"] = {
                    "type" => "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
                }
                NyxObjects2::put(asteroid)
            })

            mx.item("re orbital".yellow, lambda {
                Asteroids::reOrbitalOrNothing(asteroid)
            })

            mx.item("transmute to datapoint".yellow, lambda {
                Asteroids::transmuteAsteroidToDatapoint(asteroid)
            })

            if Asteroids::getAsteroidTargetOrNull(asteroid).nil? and asteroid["description"] then
                mx.item("send asteroid description to cube system".yellow, lambda {
                    status = CubeTransformers::sendLineToCubeSystem(asteroid["description"])
                    if status then
                        Asteroids::asteroidTerminationProtocol(asteroid)
                    end
                })
            end

            target = Asteroids::getAsteroidTargetOrNull(asteroid)
            if target and NyxObjectInterface::isDataPoint(target) then
                datapoint = target
                mx.item("to cube system".yellow, lambda {
                    status = CubeTransformers::sendDatapointToCubeSystem(datapoint)
                    if status then
                        Asteroids::asteroidTerminationProtocol(asteroid)
                    end
                })
            end

            mx.item("destroy".yellow, lambda {
                Asteroids::asteroidTerminationProtocol(asteroid)
            })

            status = mx.promptAndRunSandbox()
            #break if !status

        }

        uuid = asteroid["uuid"]

        # ----------------------------------------
        # Not Running

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::accessTarget(asteroid)
            processor.call(asteroid)
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::accessTarget(asteroid)
            processor.call(asteroid)
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::accessTarget(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::accessTarget(asteroid)
            processor.call(asteroid)
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        # ----------------------------------------
        # Running

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            # This case should not happen because we are not starting inbox items.
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidTerminationProtocol(asteroid)
            end
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidTerminationProtocol(asteroid)
            end
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                Asteroids::asteroidTerminationProtocol(asteroid)
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
            puts "bank value: #{Bank::value(asteroid["uuid"])}".yellow
            puts "metric: #{Asteroids::metric(asteroid)}".yellow
            puts "x-stream-index: #{asteroid["x-stream-index"]}".yellow

            unixtime = DoNotShowUntil::getUnixtimeOrNull(asteroid["uuid"])
            if unixtime and (Time.new.to_i < unixtime) then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}".yellow
            end

            puts ""

            target = Asteroids::getAsteroidTargetOrNull(asteroid)
            if target then
                menuitems.item(
                    "target: #{NyxObjectInterface::toString(target)}",
                    lambda { NyxObjectInterface::landing(target) }
                )
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
                "transmute to datapoint".yellow,
                lambda {
                    Asteroids::transmuteAsteroidToDatapoint(asteroid)
                }
            )

            if Asteroids::getAsteroidTargetOrNull(asteroid).nil? and asteroid["description"] then
                menuitems.item("send asteroid description to cube system".yellow, lambda {
                    status = CubeTransformers::sendLineToCubeSystem(asteroid["description"])
                    if status then
                        Asteroids::asteroidTerminationProtocol(asteroid)
                    end
                })
            end

            target = Asteroids::getAsteroidTargetOrNull(asteroid)
            if target and NyxObjectInterface::isDataPoint(target) then
                datapoint = target
                menuitems.item("to cube system".yellow, lambda {
                    status = CubeTransformers::sendDatapointToCubeSystem(datapoint)
                    if status then
                        Asteroids::asteroidTerminationProtocol(asteroid)
                    end
                })
            end

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
                    datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
                    return if datapoint.nil?
                    Arrows::issueOrException(asteroid, datapoint)
                }
            )

            menuitems.item(
                "select target ; destroy".yellow,
                lambda {
                    targets = Arrows::getTargetsForSource(asteroid)
                    targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
                    target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda{|target| NyxObjectInterface::toString(target) })
                    return if target.nil?
                    NyxObjectInterface::destroy(target)
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

    # Asteroids::asteroidTerminationProtocol(asteroid)
    def self.asteroidTerminationProtocol(asteroid)
        Asteroids::stopAsteroidIfRunning(asteroid)
        target = Asteroids::getAsteroidTargetOrNull(asteroid)
        if target and NyxObjectInterface::isDataPoint(target) then
            datapoint = target
            status = NSNode1638::datapointTerminationProtocolReturnBoolean(datapoint)
            return if !status
        end
        NyxObjects2::destroy(asteroid)
    end

    # ------------------------------------------------------------------
end
