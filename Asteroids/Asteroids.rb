
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation, key)
    KeyValueStore::setFlagFalse(repositorylocation, key)
    KeyValueStore::flagIsTrue(repositorylocation, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Runner.rb"
=begin 
    Runner::isRunning?(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Bank.rb"
=begin 
    Bank::put(uuid, weight)
    Bank::value(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Links.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"

# -----------------------------------------------------------------------

class Asteroids

    # Asteroids::issueNew(orbitalname, orbitaluuid, description, quark)
    def self.issueNew(orbitalname, orbitaluuid, description, quark)
        item = {
            "nyxType"          => "asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37",
            "uuid"             => SecureRandom.uuid,
            "creationUnixtime" => Time.new.to_f,
            "orbitalname"      => orbitalname,
            "orbitaluuid"      => orbitaluuid,
            "description"      => description,
            "quarkuuid"        => quark["uuid"]
        }
        NyxIO::commitToDisk(item)
        item
    end

    # Asteroids::selectProjectNameUuidPair()
    def self.selectProjectNameUuidPair()
        orbitalname = Asteroids::selectOrbitalnameInteractivelyOrNull()
        orbitaluuid = nil
        if orbitalname.nil? then
            orbitalname = LucilleCore::askQuestionAnswerAsString("orbital name : ")
            orbitaluuid = SecureRandom.uuid
        else
            orbitaluuid = Asteroids::orbitalname2orbitaluuidOrNull(orbitalname)
            # We are not considering the case null
        end
        [orbitalname, orbitaluuid]
    end

    # Asteroids::asteroidBestDescription(item)
    def self.asteroidBestDescription(item)
        quark = NyxIO::getOrNull(item["quarkuuid"])
        return "#{JSON.generate(item)} -> null quark" if quark.nil?
        item["description"] || Quark::quarkToString(quark)
    end

    # Asteroids::asteroidOpen(item)
    def self.asteroidOpen(item)
        quark = NyxIO::getOrNull(item["quarkuuid"])
        return if quark.nil?
        Quark::openQuark(quark)
    end

    # Asteroids::asteroidToString(item)
    def self.asteroidToString(item)
        itemuuid = item["uuid"]
        quark = NyxIO::getOrNull(item["quarkuuid"])
        quarkType = quark ? quark["type"] : "[null]"
        isRunning = Runner::isRunning?(itemuuid)
        runningSuffix = isRunning ? "(running for #{(Runner::runTimeInSecondsOrNull(itemuuid).to_f/3600).round(2)} hour)" : ""
        "[asteroid] [#{item["orbitalname"]}] [#{quarkType}] #{Asteroids::asteroidBestDescription(item)} (bank: #{(Bank::value(itemuuid).to_f/3600).round(2)} hours) #{runningSuffix}"
    end

    # Asteroids::asteroidReceivesRunTimespan(item, timespan, verbose = false)
    def self.asteroidReceivesRunTimespan(item, timespan, verbose = false)
        itemuuid = item["uuid"]
        orbitaluuid = item["orbitaluuid"]

        if verbose then
            puts "Bank: putting #{timespan.round(2)} secs into itemuuid: #{itemuuid}"
        end
        Bank::put(itemuuid, timespan)

        if verbose then
            puts "Bank: putting #{timespan.round(2)} secs into orbitaluuid: #{orbitaluuid}"
        end
        Bank::put(orbitaluuid, timespan)

        if verbose then
            puts "Ping: putting #{timespan.round(2)} secs into Asteroids [uuid: ed4a67ee-c205-4ea4-a135-f10ea7782a7f]"
        end
        Ping::put("ed4a67ee-c205-4ea4-a135-f10ea7782a7f", timespan)
    end

    # Asteroids::orbitalnames()
    def self.orbitalnames()
        Asteroids::asteroids()
            .map{|item| item["orbitalname"] }
            .uniq
            .sort
    end

    # Asteroids::orbitalname2orbitaluuidOrNull(orbitalname)
    def self.orbitalname2orbitaluuidOrNull(orbitalname)
        orbitaluuid = KeyValueStore::getOrNull(nil, "440e3a2b-043c-4835-a59b-96deffb72f01:#{orbitalname}")
        return orbitaluuid if !orbitaluuid.nil?
        orbitaluuid = Asteroids::asteroids().select{|item| item["orbitalname"] == orbitalname }.first["orbitaluuid"]
        if !orbitaluuid.nil? then
            KeyValueStore::set(nil, "440e3a2b-043c-4835-a59b-96deffb72f01:#{orbitalname}", orbitaluuid)
        end
        orbitaluuid
    end

    # Asteroids::selectOrbitalnameInteractivelyOrNull()
    def self.selectOrbitalnameInteractivelyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", Asteroids::orbitalnames().sort)
    end

    # Asteroids::asteroidsForOrbitalname(orbitalname)
    def self.asteroidsForOrbitalname(orbitalname)
        orbitaluuid = Asteroids::orbitalname2orbitaluuidOrNull(orbitalname)
        return [] if orbitaluuid.nil?
        Asteroids::asteroids()
            .select{|item| item["orbitaluuid"] == orbitaluuid }
            .sort{|i1, i2| i1["creationUnixtime"]<=>i2["creationUnixtime"] }
    end

    # Asteroids::orbitalsTimeDistribution()
    def self.orbitalsTimeDistribution()
        Asteroids::orbitalnames().map{|orbitalname|
            orbitaluuid = Asteroids::orbitalname2orbitaluuidOrNull(orbitalname)
            {
                "orbitalname" => orbitalname,
                "orbitaluuid" => orbitaluuid,
                "timeInHours" => Bank::value(orbitaluuid).to_f/3600
            }
        }
    end

    # Asteroids::updateAsteroidOrbitalname(item)
    def self.updateAsteroidOrbitalname(item)
        orbitalname = Asteroids::selectOrbitalnameInteractivelyOrNull()
        orbitaluuid = nil
        if orbitalname.nil? then
            orbitalname = LucilleCore::askQuestionAnswerAsString("orbital name ? ")
            return if orbitalname == ""
            orbitaluuid = SecureRandom.uuid
        else
            orbitaluuid = Asteroids::orbitalname2orbitaluuidOrNull(orbitalname)
            return if orbitaluuid.nil?
        end
        item["orbitalname"] = orbitalname
        item["orbitaluuid"] = orbitaluuid
        NyxIO::commitToDisk(item)
    end

    # Asteroids::recastAsCubeContentInteractive(item) # Boolean # Indicates whether a promotion was acheived
    def self.recastAsCubeContentInteractive(item) # Boolean # Indicates whether a promotion was acheived
        quark = NyxIO::getOrNull(item["quarkuuid"])
        return false if quark.nil?
        description = LucilleCore::askQuestionAnswerAsString("cube description: ")
        cube = Cubes::issueCubeWithDescriptionAndQuark(description, quark)
        puts JSON.pretty_generate(cube)
        clique = Cliques::selectCliqueOrMakeNewOneOrNull()
        if clique then
            puts JSON.pretty_generate(clique)
            claim = Links::issueLink(clique, cube)
            puts JSON.pretty_generate(claim)
        end
        LucilleCore::pressEnterToContinue()
        return true
    end

    # Asteroids::recastAsOpenCycle(item) # Boolean # Indicates whether a promotion was acheived
    def self.recastAsOpenCycle(item) # Boolean # Indicates whether a promotion was acheived
        # First we need a cube and opencycle that
        quark = NyxIO::getOrNull(item["quarkuuid"])
        return false if quark.nil?
        description = LucilleCore::askQuestionAnswerAsString("cube description: ")
        cube = Cubes::issueCubeWithDescriptionAndQuark(description, quark)
        puts JSON.pretty_generate(cube)
        clique = Cliques::selectCliqueOrMakeNewOneOrNull()
        if clique then
            puts JSON.pretty_generate(clique)
            claim = Links::issueLink(clique, cube)
            puts JSON.pretty_generate(claim)
        end
        opencycle = OpenCycles::issueFromCube(cube)
        puts JSON.pretty_generate(opencycle)
        LucilleCore::pressEnterToContinue()
        return true
    end

    # Asteroids::asteroidDive(item)
    def self.asteroidDive(item)
        loop {
            puts "uuid: #{item["uuid"]}"
            puts Asteroids::asteroidToString(item).green
            puts "project time: #{Bank::value(item["orbitaluuid"].to_f/3600)} hours".green
            options = [
                "start",
                "open",
                "done",
                "set description",
                "recast",
                "push",
                "promote from Asteroid to Cube",
                "promote from Asteroid to Open Cycle"
            ]
            if Runner::isRunning?(item["uuid"]) then
                options.delete("start")
            else
                options.delete("stop")
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "start" then
                Runner::start(item["uuid"])
            end
            if option == "stop" then
                Runner::stop(item["uuid"])
            end
            if option == "open" then
                quark = NyxIO::getOrNull(item["quarkuuid"])
                next if quark.nil?
                Quark::openQuark(quark)
            end
            if option == "done" then
                NyxIO::destroy(item["uuid"])
                return
            end
            if option == "set description" then
                item["description"] = CatalystCommon::editTextUsingTextmate(item["description"])
                NyxIO::commitToDisk(item)
            end
            if option == "recast" then
                Asteroids::updateAsteroidOrbitalname(item)
            end
            if option == "push" then
                item["creationUnixtime"] = Time.new.to_f
                NyxIO::commitToDisk(item)
            end
            if option == "promote from Asteroid to Cube" then
                status = Asteroids::recastAsCubeContentInteractive(item)
                next if !status
                NyxIO::destroy(item["uuid"])
                return
            end
            if option == "promote from Asteroid to Open Cycle" then
                status = Asteroids::recastAsOpenCycle(item)
                next if !status
                NyxIO::destroy(item["uuid"])
                return
            end
        }
    end

    # Asteroids::asteroids()
    def self.asteroids()
        NyxIO::objects("asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37")
    end

    # Asteroids::getFocus()
    def self.getFocus()
        locationKey = CatalystCommon::getNewValueEveryNSeconds("069aeb21-bce5-4ea2-aa03-230a4c354729", 2.71828*3600) # e hours
        focus = KeyValueStore::getOrNull(nil, locationKey)
        if focus then
            return JSON.parse(focus)
        end
        focus = Asteroids::orbitalsTimeDistribution()
                    .sort{|i1, i2|
                        i1["timeInHours"] <=> i2["timeInHours"]
                    }
                    .first
        KeyValueStore::set(nil, locationKey, JSON.generate(focus))
        focus
    end

    # Asteroids::itemToCatalystObject(item, basemetric, indx)
    def self.itemToCatalystObject(item, basemetric, indx)
        uuid = item["uuid"]
        isRunning = Runner::isRunning?(uuid)
        isRunningForLong = ((Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600)
        metric = basemetric - indx.to_f/1000
        {
            "uuid"             => uuid,
            "body"             => Asteroids::asteroidToString(item),
            "metric"           => metric,
            "isRunning"        => isRunning,
            "isRunningForLong" => isRunningForLong,
            "execute"          => lambda{ Asteroids::execute(item) },
            "x-todo-item"      => item
        }
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()

        while (link = Mercury::getFirstValueOrNull("F771D7FE-1802-409D-B009-5EB95BA89D86")) do
            quark = {
                "uuid"             => SecureRandom.uuid,
                "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "type"             => "url",
                "url"              => link
            }
            NyxIO::commitToDisk(quark)
            Asteroids::issueNew("Inbox", "44caf74675ceb79ba5cc13bafa102509369c2b53", link, quark)
            Mercury::deleteFirstValue("F771D7FE-1802-409D-B009-5EB95BA89D86")
        end

        objects = []

        # -------------------------------------------------------------------------

        # First, we display all the Inbox items in order.

        Asteroids::asteroids()
            .select{|item| item["orbitaluuid"] == "44caf74675ceb79ba5cc13bafa102509369c2b53" } # Inbox
            .sort{|i1, i2| 
                i1["creationUnixtime"] <=> i2["creationUnixtime"] }
            .each_with_index {|item, indx|
                objects << Asteroids::itemToCatalystObject(item, 0.85, indx)
            }

        # -------------------------------------------------------------------------

        # Now we select a project and work with the first 3 items

        focus = Asteroids::getFocus()

        # focus : {
        #     "orbitalname" : String,
        #     "orbitaluuid  : String,
        #     "timeInHours" : Float
        # }

        items1 = Asteroids::asteroids().select{|item| Runner::isRunning?(item["uuid"]) }
        items2 = Asteroids::asteroids()
                    .select{|item| item["orbitaluuid"] == focus["orbitaluuid"] }
                    .select{|item| !Runner::isRunning?(item["uuid"]) } # running object have already been taken in items1
                    .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
                    .first(3)
                    .sort{|i1, i2| Bank::value(i1["uuid"]) <=> Bank::value(i2["uuid"]) }

        timeInPingInHours = Ping::totalOverTimespan("ed4a67ee-c205-4ea4-a135-f10ea7782a7f", 86400).to_f/3600
        basemetric = 
            if timeInPingInHours < 1 then
                0.66 - 0.10*timeInPingInHours # 0.66 -> 0.56 after one hour
            else
                timeInPingInHours = timeInPingInHours - 1
                0.2 + 0.36*Math.exp(-timeInPingInHours) # 0.56 -> 0.20 landing
            end

        (items1+items2)
            .each_with_index {|item, indx|
                objects << Asteroids::itemToCatalystObject(item, basemetric, indx)
            }

        objects
    end

    # Asteroids::stop(uuid, item)
    def self.stop(uuid, item)
        timespan = Runner::stop(uuid)
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        Asteroids::asteroidReceivesRunTimespan(item, timespan, true)
    end

    # Asteroids::startProcedure(item)
    def self.startProcedure(item)
        uuid = item["uuid"]
        Runner::start(uuid)
        quark = NyxIO::getOrNull(item["quarkuuid"])
        return if quark.nil?
        Quark::openQuark(quark)

        if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", false) then
            Asteroids::stop(uuid, item)
            NyxIO::destroy(item["uuid"])
            return
        end

        if item["description"].nil? then
            item["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
            NyxIO::commitToDisk(item)
        end

        if item["orbitaluuid"] == "44caf74675ceb79ba5cc13bafa102509369c2b53" then
            Asteroids::stop(uuid, item)
            puts "Item was not immediately done, we need to recast it in another project or promote it to the data network"
            options = ["update orbital", "recast on knowledge network"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            if option == "recast" then
                Asteroids::updateAsteroidOrbitalname(item)
            end
            if option == "recast on knowledge network" then
                status = Asteroids::recastAsCubeContentInteractive(item)
                return if !status
                NyxIO::destroy(item["uuid"])
            end
        end
    end

    # Asteroids::stopProcedure(item)
    def self.stopProcedure(item)
        uuid = item["uuid"]
        Asteroids::stop(uuid, item)
        if item["orbitaluuid"] == "44caf74675ceb79ba5cc13bafa102509369c2b53" then
            puts "Item was not immediately done, we need to classify it."
            Asteroids::updateAsteroidOrbitalname(item)
        end
    end

    # Asteroids::execute(item)
    def self.execute(item)
        uuid = item["uuid"]
        options = ["start", "open", "stop", "done", "description", "update orbital", "recastAsCubeContentInteractive", "recastAsOpenCycle", "reset-reference-time", "dive"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        if option == "start" then
            Asteroids::startProcedure(item)
        end

        if option == "open" then
            quark = NyxIO::getOrNull(item["quarkuuid"])
            return if quark.nil?
            Quark::openQuark(quark)
        end

        if option == "stop" then
            Asteroids::stopProcedure(item)
        end

        if option == "done" then
            Asteroids::stop(uuid, item)
            NyxIO::destroy(item["uuid"])
        end

        if option == "description" then
            item["description"] = CatalystCommon::editTextUsingTextmate(item["description"])
            NyxIO::commitToDisk(item)
        end

        if option == "update orbital" then
            Asteroids::stop(uuid, item)
            Asteroids::updateAsteroidOrbitalname(item)
        end

        if option == "recastAsCubeContentInteractive" then
            Asteroids::stop(uuid, item)
            status = Asteroids::recastAsCubeContentInteractive(item)
            return if !status
            NyxIO::destroy(item["uuid"])
        end

        if option == "recastAsOpenCycle" then
            Asteroids::stop(uuid, item)
            status = Asteroids::recastAsOpenCycle(item)
            return if !status
            NyxIO::destroy(item["uuid"])
        end

        if option == "reset-reference-time" then
            Asteroids::stop(uuid, item)
            item["creationUnixtime"] = Time.new.to_f
            NyxIO::commitToDisk(item)
        end

        if option == "dive" then
            Asteroids::asteroidDive(item)
        end
    end

    # Asteroids::createNewAsteroidInteractivelyOrNull()
    def self.createNewAsteroidInteractivelyOrNull()
        target = Quark::issueNewQuarkInteractivelyOrNull()
        return nil if target.nil?
        orbitalname = Asteroids::selectOrbitalnameInteractivelyOrNull()
        orbitaluuid = nil
        if orbitalname.nil? then
            orbitalname = LucilleCore::askQuestionAnswerAsString("orbinal name: ")
            orbitaluuid = SecureRandom.uuid
        else
            orbitaluuid = Asteroids::orbitalname2orbitaluuidOrNull(orbitalname)
            return nil if orbitaluuid.nil?
        end
        Asteroids::issueNew(orbitalname, orbitaluuid, nil, target)
    end

    # Asteroids::createNewAsteroidWithGivenExistingOrbitalnameInteractivelyOrNull(orbitalname)
    def self.createNewAsteroidWithGivenExistingOrbitalnameInteractivelyOrNull(orbitalname)
        orbitaluuid = Asteroids::orbitalname2orbitaluuidOrNull(orbitalname)
        return nil if orbitaluuid.nil?
        target = Quark::issueNewQuarkInteractivelyOrNull()
        return nil if target.nil?
        Asteroids::issueNew(orbitalname, orbitaluuid, nil, target)
    end

    # Asteroids::orbitalDive(orbitalname)
    def self.orbitalDive(orbitalname)
        loop {
            system("clear")
            puts "-> Visiting project '#{orbitalname}'"

            items = []

            Asteroids::asteroidsForOrbitalname(orbitalname)
                .each{|asteroid|
                    items << [ Asteroids::asteroidToString(asteroid), lambda{ Asteroids::asteroidDive(asteroid) } ]
                }

            items << [ 
                        "-> Add new asteroid to this orbital", 
                        lambda {
                            asteroid = Asteroids::createNewAsteroidWithGivenExistingOrbitalnameInteractivelyOrNull(orbitalname)
                            return if asteroid.nil?
                            puts JSON.pretty_generate(asteroid)
                        }
                     ]

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # Asteroids::main()
    def self.main()
        loop {
            system("clear")
            puts "Asteroids 👩‍💻"
            options = [
                "create new asteroid",
                "orbitals dive",
                "time report"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "create new asteroid" then
                asteroid = Asteroids::createNewAsteroidInteractivelyOrNull()
                next if asteroid.nil?
                puts JSON.pretty_generate(asteroid)
            end
            if option == "orbitals dive" then
                loop {
                    puts "-> Asteroids dive"
                    orbitalname = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital name ", Asteroids::orbitalnames())
                    break if orbitalname.nil?
                    Asteroids::orbitalDive(orbitalname)
                }
            end
            if option == "time report" then
                items = Asteroids::orbitalsTimeDistribution()
                d = items.map{|item| item["orbitalname"].size }.max
                items
                    .sort{|i1, i2| i1["timeInHours"] <=> i2["timeInHours"] }
                    .each{|item|
                        puts "#{item["orbitalname"].ljust(d+1)} #{"%8.2f" % item["timeInHours"]} hours"
                    }
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end
