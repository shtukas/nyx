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
        orbitals = Asteroids::asteroidOrbitalTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", orbitals)
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

        if asteroid["orbital"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            asteroid["special-5e28447a-daily-time-commitment-in-hours"] = LucilleCore::askQuestionAnswerAsString("commitment in hours: ").to_f
        end

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
            "uuid"          => SecureRandom.hex,
            "nyxNxSet"      => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"      => Time.new.to_f,
            "orbital"       => orbital,
            "targetuuid" => datapoint["uuid"]
        }
        Asteroids::commitToDisk(asteroid)
        asteroid
    end

    # Asteroids::issueAsteroidInboxFromDatapoint(datapoint)
    def self.issueAsteroidInboxFromDatapoint(datapoint)
        asteroid = {
            "uuid"          => SecureRandom.uuid,
            "nyxNxSet"      => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"      => Time.new.to_f,
            "orbital"       => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860",
            "targetuuid" => datapoint["uuid"]
        }
        Asteroids::commitToDisk(asteroid)
        asteroid
    end

    # Asteroids::issueAsteroidAgainstExistigCubeInteractivelyOrNull()
    def self.issueAsteroidAgainstExistigCubeInteractivelyOrNull()
        cube = Cubes::selectCubeOrNull()
        return nil if cube.nil?
        asteroid = {
            "uuid"          => SecureRandom.uuid,
            "nyxNxSet"      => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"      => Time.new.to_f,
            "orbital"    => "daily-time-commitment-e1180643-fc7e-42bb-a2",
            "targetuuid" => cube["uuid"]
        }
        Asteroids::commitToDisk(asteroid)
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

    # Asteroids::getAsteroidTargetOrNull(asteroid)
    def self.getAsteroidTargetOrNull(asteroid)
        return nil if asteroid["targetuuid"].nil?
        NyxObjects2::getOrNull(asteroid["targetuuid"])
    end

    # Asteroids::asteroidOrbitalAsUserFriendlyString(orbital)
    def self.asteroidOrbitalAsUserFriendlyString(orbital)
        return "📥" if orbital == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        return "🔥" if orbital == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
        return "👩‍💻" if orbital == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
        return "💫" if orbital == "daily-time-commitment-e1180643-fc7e-42bb-a2"
    end

    # Asteroids::asteroidDescription(asteroid)
    def self.asteroidDescription(asteroid)
        target = Asteroids::getAsteroidTargetOrNull(asteroid)
        if asteroid["description"] and target.nil? then
            return asteroid["description"]
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
            return "" if asteroid["orbital"] != "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
            return "" if asteroid["x-stream-index"].nil?
            targetHours = 1.to_f/(2**asteroid["x-stream-index"]) # For index 0 that's 1 hour, so total two hours commitment per day
            ratio = BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/targetHours
            return " (index: #{asteroid["x-stream-index"]}, target: #{targetHours} hours, #{(100*ratio).round(2)} % completed)"
        }).call(asteroid)

        p6 = (lambda {|asteroid|
            return "" if asteroid["orbital"] != "daily-time-commitment-e1180643-fc7e-42bb-a2"
            commitmentInHours = asteroid["special-5e28447a-daily-time-commitment-in-hours"]
            ratio = BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/commitmentInHours
            return " (commitment: #{commitmentInHours} hours, #{(100*ratio).round(2)} % completed)"
        }).call(asteroid)

        "#{p1}#{p2}#{p3}#{p4}#{p6}"
    end

    # Asteroids::unixtimedrift(unixtime)
    def self.unixtimedrift(unixtime)
        # Unixtime To Decreasing Metric Shift Normalised To Interval Zero One
        # The older the bigger
        referenceTime = (Time.new.to_f / 86400).to_i * 86400
        0.00000000001*(referenceTime-unixtime).to_f
    end

    # Asteroids::isRunning?(asteroid)
    def self.isRunning?(asteroid)
        Runner::isRunning?(asteroid["uuid"])
    end

    # Asteroids::isRunningForLong?(asteroid)
    def self.isRunningForLong?(asteroid)
        return false if !Asteroids::isRunning?(asteroid)
        uuid = asteroid["uuid"]
        orbital = asteroid["orbital"]
        ( Runner::runTimeInSecondsOrNull(asteroid["uuid"]) || 0 ) > 3600
    end

    # Asteroids::metric(asteroid)
    def self.metric(asteroid)
        uuid = asteroid["uuid"]

        return 1 if Asteroids::isRunning?(asteroid)

        if asteroid["orbital"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return 0.70 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if asteroid["orbital"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            return 0.65
        end

        if asteroid["orbital"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            return 0.6 + Asteroids::unixtimedrift(asteroid["unixtime"])
        end

        if asteroid["orbital"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            if asteroid["x-stream-index"].nil? then
                # This never happens during a regular Asteroids::catalystObjects() call, but can happen if this function is manually called on an asteroid
                return 0
            end
            targetHours = 1.to_f/(2**asteroid["x-stream-index"]) # For index 0 that's 1 hour, so total two hours commitment per day
            ratio = BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/targetHours
            if ratio then
                return 0.50 + Asteroids::unixtimedrift(asteroid["unixtime"])
            end
            return 0.2 + 0.2*Math.exp(-(ratio-1))
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

        if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("6347a941-2907-44fc-8eb3-1f85adb8436c", 3600*12) then
            Asteroids::asteroids()
                .select{|asteroid| asteroid["orbital"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" }
                .sort{|a1, a2| a1["unixtime"]<=>a2["unixtime"] }
                .first(10)
                .each_with_index{|asteroid, indx|
                    asteroid["x-stream-index"] = indx
                    Asteroids::commitToDisk(asteroid)
                }
        end

        Asteroids::asteroids()
            .select{|asteroid| 
                b1 = (asteroid["orbital"] != "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c")
                b2 = asteroid["x-stream-index"]
                b1 or b2
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
            Cubes::cubeLanding(target)
            return
        end
    end

    # Asteroids::transmuteAsteroidToNode(asteroid)
    def self.transmuteAsteroidToNode(asteroid)

        target = Asteroids::getAsteroidTargetOrNull(asteroid)
        return if target.nil?
        return if NyxObjectInterface::isCube(target)

        puts "Transmuting asteroid to "

        Asteroids::stopAsteroidIfRunning(asteroid)

        if asteroid["targetuuid"].nil? then
            NyxObjects2::destroy(asteroid)
            return
        end

        datapoint = NyxObjects2::getOrNull(asteroid["targetuuid"])

        if datapoint.nil? then
            NyxObjects2::destroy(asteroid)
            return
        end

        description = LucilleCore::askQuestionAnswerAsString("datapoint description (empty to skip): ")
        if description != "" then
            datapoint["description"] = description
            NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(datapoint)
        end

        if datapoint["type"] == "NyxDirectory" then
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
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
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-Items" then
                # Ne need to move that thing somewhere else.
                newEnvelopFolderPath = "/Users/pascal/Galaxy/Timeline/#{Time.new.strftime("%Y")}/Catalyst-Elements/#{Time.new.strftime("%Y-%m")}/#{Miscellaneous::l22()}"
                FileUtils.mkpath(newEnvelopFolderPath)
                LucilleCore::copyContents(File.dirname(location), newEnvelopFolderPath)
                LucilleCore::removeFileSystemLocation(File.dirname(location))
                GalaxyFinder::registerFilenameAtLocation(datapoint["name"], "#{newEnvelopFolderPath}/#{datapoint["name"]}")
            end
        end

        tags = (lambda {
            ts = []
            loop {
                payload = LucilleCore::askQuestionAnswerAsString("tag (empty to end process): ")
                break if payload == ""
                ts << Tags::issue(payload)
            }
            ts
        }).call()

        vectors = (lambda {
            xs = []
            loop {
                x = Taxonomy::selectOneExistingTaxonomyItemOrNull()
                break if x.nil?
                xs << x
            }
            if xs.empty? then
                str = LucilleCore::askQuestionAnswerAsString("vector (empty for null): ")
                item = Taxonomy::issueTaxonomyItemFromStringOrNull(str)
                if item then
                    xs << item
                end
            end
            xs
        }).call()

        tags.each{|tag| 
            puts "issue tag: #{tag}"
            Arrows::issueOrException(tag, datapoint) 
        }

        vectors.each{|vector| 
            puts "issue vecor: #{vector}"
            Arrows::issueOrException(vector, datapoint) 
        }

        NyxObjects2::destroy(asteroid)
        NSNode1638::landing(datapoint)
    end

    # Asteroids::diveAsteroidOrbitalType(orbitalType)
    def self.diveAsteroidOrbitalType(orbitalType)
        loop {
            system("clear")
            asteroids = Asteroids::asteroids().select{|asteroid| asteroid["orbital"] == orbitalType }
            asteroid = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", asteroids, lambda{|asteroid| Asteroids::toString(asteroid) })
            break if asteroid.nil?
            Asteroids::landing(asteroid)
        }
    end

    # Asteroids::naturalNextOperation(asteroid)
    def self.naturalNextOperation(asteroid)
        inboxProcessor = lambda {|asteroid|
            Asteroids::accessTarget(asteroid)

            mx = LCoreMenuItemsNX1.new()

            mx.item("landing".yellow, lambda {
                Asteroids::landing(asteroid)
            })

            mx.item("hide for one hour".yellow, lambda {
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+3600)
            })

            mx.item("hide until tomorrow".yellow, lambda {
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+3600*(12-Time.new.hour))
            })

            mx.item("hide for n days".yellow, lambda {
                timespanInDays = LucilleCore::askQuestionAnswerAsString("timespan in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+86400*timespanInDays)
            })

            mx.item("to burner".yellow, lambda {
                asteroid["orbital"] = "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
                Asteroids::commitToDisk(asteroid)
            })

            mx.item("to stream".yellow, lambda {
                asteroid["orbital"] = "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
                Asteroids::commitToDisk(asteroid)
            })

            mx.item("re orbital".yellow, lambda {
                Asteroids::reOrbitalOrNothing(asteroid)
            })

            mx.item("transmute to node".yellow, lambda {
                Asteroids::transmuteAsteroidToNode(asteroid)
            })

            if Asteroids::getAsteroidTargetOrNull(asteroid).nil? and asteroid["description"] then
                mx.item("send asteroid description to cube system".yellow, lambda {
                    status = CubeTransformers::sendLineToCubeSystem(asteroid["description"])
                    if status then
                        NyxObjects2::destroy(asteroid)
                    end
                })
            end

            target = Asteroids::getAsteroidTargetOrNull(asteroid)
            if target and NyxObjectInterface::isDataPoint(target) then
                datapoint = target
                mx.item("send datapoint to cube system".yellow, lambda {
                    status = CubeTransformers::sendDatapointToCubeSystem(datapoint)
                    if status then
                        NyxObjects2::destroy(asteroid)
                    end
                })
            end

            mx.item("destroy".yellow, lambda {
                NyxObjects2::destroy(asteroid)
            })

            status = mx.promptAndRunSandbox()
            #break if !status

        }

        burnerProcessor = lambda {|asteroid|
            Asteroids::accessTarget(asteroid)

            mx = LCoreMenuItemsNX1.new()

            mx.item("landing".yellow, lambda {
                Asteroids::landing(asteroid)
            })

            mx.item("hide for one hour".yellow, lambda {
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+3600)
            })

            mx.item("hide until tomorrow".yellow, lambda {
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+3600*(12-Time.new.hour))
            })

            mx.item("hide for n days".yellow, lambda {
                timespanInDays = LucilleCore::askQuestionAnswerAsString("timespan in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i+86400*timespanInDays)
            })

            mx.item("to stream".yellow, lambda {
                asteroid["orbital"] = "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
                Asteroids::commitToDisk(asteroid)
            })

            mx.item("re orbital".yellow, lambda {
                Asteroids::reOrbitalOrNothing(asteroid)
            })

            mx.item("transmute to node".yellow, lambda {
                Asteroids::transmuteAsteroidToNode(asteroid)
            })

            if Asteroids::getAsteroidTargetOrNull(asteroid).nil? and asteroid["description"] then
                mx.item("send asteroid description to cube system".yellow, lambda {
                    status = CubeTransformers::sendLineToCubeSystem(asteroid["description"])
                    if status then
                        NyxObjects2::destroy(asteroid)
                    end
                })
            end

            target = Asteroids::getAsteroidTargetOrNull(asteroid)
            if target and NyxObjectInterface::isDataPoint(target) then
                datapoint = target
                mx.item("send datapoint to cube system".yellow, lambda {
                    status = CubeTransformers::sendDatapointToCubeSystem(datapoint)
                    if status then
                        NyxObjects2::destroy(asteroid)
                    end
                })
            end

            mx.item("destroy".yellow, lambda {
                NyxObjects2::destroy(asteroid)
            })

            status = mx.promptAndRunSandbox()
            #break if !status
        }

        uuid = asteroid["uuid"]

        # ----------------------------------------
        # Not Running

        if !Runner::isRunning?(uuid) and asteroid["orbital"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            inboxProcessor.call(asteroid)
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            Asteroids::accessTarget(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            burnerProcessor.call(asteroid)
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if !Runner::isRunning?(uuid) and asteroid["orbital"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            Asteroids::startAsteroidIfNotRunning(asteroid)
            openContent.call(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("destroy asteroid? : ") then
                Asteroids::stopAsteroidIfRunning(asteroid)
                NyxObjects2::destroy(asteroid)
            end
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        # ----------------------------------------
        # Running

        if Runner::isRunning?(uuid) and asteroid["orbital"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            # This case should not happen because we are not starting inbox items.
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                NyxObjects2::destroy(asteroid)
            end
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                NyxObjects2::destroy(asteroid)
            end
            return
        end

        if Runner::isRunning?(uuid) and asteroid["orbital"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            Asteroids::stopAsteroidIfRunning(asteroid)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                NyxObjects2::destroy(asteroid)
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
                        Asteroids::stopAsteroidIfRunning(asteroid)
                        NyxObjectInterface::destroy(asteroid)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            targets = Arrows::getTargetsForSource(asteroid)
            targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
            targets.each{|object|
                    menuitems.item(
                        NyxObjectInterface::toString(object),
                        lambda { NyxObjectInterface::landing(object) }
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

    # ------------------------------------------------------------------
end
