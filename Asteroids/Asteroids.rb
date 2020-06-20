
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/ProgrammableBooleans.rb"
=begin
    ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds(uuid, n)
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

# -----------------------------------------------------------------------

class Asteroids

    # Asteroids::issueNew(orbitalname, orbitaluuid, quark)
    def self.issueNew(orbitalname, orbitaluuid, quark)
        item = {
            "nyxType"          => "asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37",
            "uuid"             => SecureRandom.uuid,
            "creationUnixtime" => Time.new.to_f,
            "orbitalname"      => orbitalname,
            "orbitaluuid"      => orbitaluuid,
            "quarkuuid"        => quark["uuid"]
        }
        NyxIO::commitToDisk(item)
        Asteroids::getAsteroidsByQuarkUUIDRegisterAsteroid(item)
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
        return "[could not find quark]" if quark.nil?
        Quarks::quarkToString(quark)
    end

    # Asteroids::asteroidOpen(item)
    def self.asteroidOpen(item)
        quark = NyxIO::getOrNull(item["quarkuuid"])
        return if quark.nil?
        Quarks::openQuark(quark)
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

    # Asteroids::asteroidReceivesRunTimespan(asteroid, timespan, verbose = false)
    def self.asteroidReceivesRunTimespan(asteroid, timespan, verbose = false)
        asteroiduuid = asteroid["uuid"]
        orbitaluuid = asteroid["orbitaluuid"]

        if verbose then
            puts "Bank: putting #{timespan.round(2)} secs into asteroiduuid: #{asteroiduuid}"
        end
        Bank::put(asteroiduuid, timespan)

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

    # Asteroids::recastAsteroidUnderlyingQuarkOnTheDataNetwork(item) # Boolean # Indicates whether a promotion was acheived
    def self.recastAsteroidUnderlyingQuarkOnTheDataNetwork(item) # Boolean # Indicates whether a promotion was acheived
        quark = NyxIO::getOrNull(item["quarkuuid"])
        return false if quark.nil?

        if quark["description"].nil? then
            quark["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
            NyxIO::commitToDisk(quark)
        end

        Quarks::issueZeroOrMoreTagsForQuark(quark)

        clique = Cliques::selectCliqueOrMakeNewOneOrNull()
        return false if clique.nil?

        puts JSON.pretty_generate(clique)
        claim = Bosons::issueLink(clique, quark)
        puts JSON.pretty_generate(claim)

        return true
    end

    # Asteroids::recastAsOpenCycle(asteroid)
    def self.recastAsOpenCycle(asteroid)
        quark = NyxIO::getOrNull(item["quarkuuid"])
        return if quark.nil?
        OpenCycles::issueFromQuark(quark)
        NyxIO::destroy(asteroid["uuid"])
    end

    # Asteroids::asteroids()
    def self.asteroids()
        NyxIO::objects("asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37")
    end

    # Asteroids::getAsteroidByUUIDOrNull(uuid)
    def self.getAsteroidByUUIDOrNull(uuid)
        NyxIO::getOrNullAtType(uuid, "asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37")
    end

    # Asteroids::getAsteroidsByQuarkUUIDUseTheForce(quarkuuid)
    def self.getAsteroidsByQuarkUUIDUseTheForce(quarkuuid)
        Asteroids::asteroids()
            .select{|asteroid| asteroid["quarkuuid"] == quarkuuid }
    end

    # Asteroids::getAsteroidsByQuarkUUIDUseDerivation(quarkuuid)
    def self.getAsteroidsByQuarkUUIDUseDerivation(quarkuuid)
        derivationFolderpath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nxy-Repository/cache/derivation-quarkuuid-asteroiduuids-dcf7d0c5-b3cd-4e03-ba4f-bc598fdf1d73"
        BTreeSets::values(derivationFolderpath, quarkuuid) # a set for each quarkuuid
            .map{|asteroiduuid| Asteroids::getAsteroidByUUIDOrNull(asteroiduuid) }
            .compact
            .select{|asteroid| asteroid["quarkuuid"] == quarkuuid } 
        # The set contains any asteroiduuid that have had that target at somepoint
        # By the time we call it again, the asteroid could have gotten a new target
        # ... and is why we check the target of the asteroid.
    end

    # Asteroids::getAsteroidsByQuarkUUIDRegisterAsteroid(asteroid)
    def self.getAsteroidsByQuarkUUIDRegisterAsteroid(asteroid)
        derivationFolderpath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nxy-Repository/cache/derivation-quarkuuid-asteroiduuids-dcf7d0c5-b3cd-4e03-ba4f-bc598fdf1d73"
        BTreeSets::set(derivationFolderpath, asteroid["quarkuuid"], asteroid["uuid"], asteroid["uuid"])
    end

    # Asteroids::updateAsteroidByQuarkUUIDIndex()
    def self.updateAsteroidByQuarkUUIDIndex()
        Asteroids::asteroids()
            .each{|asteroid|
                Asteroids::getAsteroidsByQuarkUUIDRegisterAsteroid(asteroid) }
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
            "execute"          => lambda{ Asteroids::asteroidDive(item) },
            "x-asteroid"      => item
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
            Asteroids::issueNew("Inbox", "44caf74675ceb79ba5cc13bafa102509369c2b53", quark)
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

        objects = objects.sort{|i1, i2| i1["metric"] <=> i2["metric"] }

        objects
    end

    # Asteroids::catalystObjectsFast()
    def self.catalystObjectsFast()

        if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("02b4b32c-58b7-49bc-983c-8117c1c3e326", 1200) then
            uuids = Asteroids::catalystObjects().reverse.first(100).map{|obj| obj["x-asteroid"]["uuid"] }.uniq
            KeyValueStore::set(nil, "b4998815-40af-4c34-b08d-e301cdcc4475", JSON.generate(uuids))
        end

        uuids = KeyValueStore::getOrNull(nil, "b4998815-40af-4c34-b08d-e301cdcc4475")
        return [] if uuids.nil?

        uuids = JSON.parse(uuids)

        timeInPingInHours = Ping::totalOverTimespan("ed4a67ee-c205-4ea4-a135-f10ea7782a7f", 86400).to_f/3600
        basemetric = 
            if timeInPingInHours < 1 then
                0.66 - 0.10*timeInPingInHours # 0.66 -> 0.56 after one hour
            else
                timeInPingInHours = timeInPingInHours - 1
                0.2 + 0.36*Math.exp(-timeInPingInHours) # 0.56 -> 0.20 landing
            end

        objects = []

        uuids
            .map{|uuid|
                Asteroids::getAsteroidByUUIDOrNull(uuid)
            }
            .compact
            .each_with_index {|item, indx|
                objects << Asteroids::itemToCatalystObject(item, basemetric, indx)
            }

        objects
    end

    # Asteroids::stop(uuid)
    def self.stop(uuid)
        timespan = Runner::stop(uuid)
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        asteroid = NyxIO::getOrNull(uuid)
        return if asteroid.nil?
        Asteroids::asteroidReceivesRunTimespan(asteroid, timespan, true)
    end

    # Asteroids::destroyAsteroid(asteroiduuid)
    def self.destroyAsteroid(asteroiduuid)
        NyxIO::destroyAtType(asteroiduuid, "asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37")
    end

    # Asteroids::startProcedure(asteroid)
    def self.startProcedure(asteroid)
        uuid = asteroid["uuid"]
        Runner::start(uuid)
        quark = NyxIO::getOrNull(asteroid["quarkuuid"])
        return if quark.nil?
        Quarks::openQuark(quark)

        if LucilleCore::askQuestionAnswerAsBoolean("-> done ? (#{"if yes will ask to recast the underlying Quark on Nyx Data Network and remove the Asteroid role".green}) ", false) then
            Asteroids::stop(uuid)
            if LucilleCore::askQuestionAnswerAsBoolean("Recast underlying Quark on the Nyx Data Network ? ") then
                status = Asteroids::recastAsteroidUnderlyingQuarkOnTheDataNetwork(asteroid)
                if !status then
                    puts "You choose to put the Quark on the Nyx Data Network, but the operation didn't finish. Aborting done operation"
                    return
                end
            end
            NyxIO::destroy(asteroid["uuid"])
            return
        end
    end

    # Asteroids::stopProcedure(asteroid)
    def self.stopProcedure(asteroid)
        uuid = asteroid["uuid"]
        Asteroids::stop(uuid)
        if LucilleCore::askQuestionAnswerAsBoolean("done ? ", false) then
            Asteroids::destroyProcedure(asteroid)
            return
        end
        if asteroid["orbitaluuid"] == "44caf74675ceb79ba5cc13bafa102509369c2b53" then
            puts "Item was not immediately done, we need to recast it to another orbital"
            Asteroids::updateAsteroidOrbitalname(asteroid)
        end
    end

    # Asteroids::destroyProcedure(asteroid)
    def self.destroyProcedure(asteroid)
        puts "-> stopping asteroid"
        Asteroids::stop(asteroid["uuid"])
        puts "-> destroying asteroid"
        Asteroids::destroyAsteroid(asteroid["uuid"])
        puts "-> extracting quark"
        quark = NyxIO::getOrNull(asteroid["quarkuuid"])
        return if quark.nil?
        puts "-> testing quark connections"
        if !Quarks::quarkHasConnections(quark) and LucilleCore::askQuestionAnswerAsBoolean("-> Recast underlying Quark on the Nyx Data Network ? ") then
            status = Asteroids::recastAsteroidUnderlyingQuarkOnTheDataNetwork(asteroid)
            if !status then
                NyxIO::commitToDisk(asteroid) # putting it back as it was removed to properly test quarkHasConnections
                puts "-> You choose to put the Quark on the Nyx Data Network, but the operation didn't finish. Aborting done operation"
                LucilleCore::pressEnterToContinue()
                return
            end
        end
    end

    # Asteroids::asteroidDive(asteroid)
    def self.asteroidDive(asteroid)
        loop {
            puts "uuid: #{asteroid["uuid"]}"
            puts Asteroids::asteroidToString(asteroid).green
            puts "project time: #{Bank::value(asteroid["orbitaluuid"].to_f/3600)} hours".green
            options = [
                "start",
                "open",
                "stop",
                "destroy",
                "update orbital",
                "push",
                "relocate target Quark to Cube content",
                "register as opencycle",
                "reset-reference-time"
            ]
            if Runner::isRunning?(asteroid["uuid"]) then
                options.delete("start")
            else
                options.delete("stop")
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "start" then
                Asteroids::startProcedure(asteroid)
            end
            if option == "open" then
                quark = NyxIO::getOrNull(asteroid["quarkuuid"])
                next if quark.nil?
                Quarks::openQuark(quark)
            end
            if option == "stop" then
                Asteroids::stopProcedure(asteroid)
            end
            if option == "destroy" then
                Asteroids::destroyProcedure(asteroid)
                return
            end
            if option == "update orbital" then
                Asteroids::stop(asteroid["uuid"])
                Asteroids::updateAsteroidOrbitalname(asteroid)
            end
            if option == "push" then
                asteroid["creationUnixtime"] = Time.new.to_f
                NyxIO::commitToDisk(asteroid)
            end
            if option == "relocate target Quark to Cube content" then
                status = Asteroids::recastAsteroidUnderlyingQuarkOnTheDataNetwork(asteroid)
                next if !status
                NyxIO::destroy(asteroid["uuid"])
                return
            end
            if option == "register as opencycle" then
                Asteroids::recastAsOpenCycle(asteroid)
                return
            end
            if option == "reset-reference-time" then
                Asteroids::stop(asteroid["uuid"])
                asteroid["creationUnixtime"] = Time.new.to_f
                NyxIO::commitToDisk(asteroid)
            end
        }
    end

    # Asteroids::createNewAsteroidInteractivelyOrNull()
    def self.createNewAsteroidInteractivelyOrNull()
        target = Quarks::issueNewQuarkInteractivelyOrNull()
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
        Asteroids::issueNew(orbitalname, orbitaluuid, target)
    end

    # Asteroids::createNewAsteroidWithGivenExistingOrbitalnameInteractivelyOrNull(orbitalname)
    def self.createNewAsteroidWithGivenExistingOrbitalnameInteractivelyOrNull(orbitalname)
        orbitaluuid = Asteroids::orbitalname2orbitaluuidOrNull(orbitalname)
        return nil if orbitaluuid.nil?
        target = Quarks::issueNewQuarkInteractivelyOrNull()
        return nil if target.nil?
        Asteroids::issueNew(orbitalname, orbitaluuid, target)
    end

    # Asteroids::orbitalDive(orbitalname)
    def self.orbitalDive(orbitalname)
        loop {
            system("clear")
            puts "-> Visiting orbital '#{orbitalname}'"

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
                "asteroid (create new)",
                "orbitals dive",
                "time report"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "asteroid (create new)" then
                asteroid = Asteroids::createNewAsteroidInteractivelyOrNull()
                next if asteroid.nil?
                puts JSON.pretty_generate(asteroid)
            end
            if option == "orbitals dive" then
                loop {
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
