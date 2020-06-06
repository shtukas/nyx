
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
    Runner::isRunning(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/QuarksCubesAndStarlightNodes.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx.rb"

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
        Nyx::commitToDisk(item)
        item
    end

    # Asteroids::selectProjectNameUuidPair()
    def self.selectProjectNameUuidPair()
        orbitalname = Asteroids::selectOrbitalNameInteractivelyOrNull()
        orbitaluuid = nil
        if orbitalname.nil? then
            orbitalname = LucilleCore::askQuestionAnswerAsString("project name: ")
            orbitaluuid = SecureRandom.uuid
        else
            orbitaluuid = Asteroids::orbitalName2orbitalUuidOrNUll(orbitalname)
            # We are not considering the case null
        end
        [orbitalname, orbitaluuid]
    end

    # Asteroids::asteroidBestDescription(item)
    def self.asteroidBestDescription(item)
        quark = Nyx::getOrNull(item["quarkuuid"])
        return "#{JSON.generate(item)} -> null quark" if quark.nil?
        item["description"] || Quark::quarkToString(quark)
    end

    # Asteroids::asteroidOpen(item)
    def self.asteroidOpen(item)
        quark = Nyx::getOrNull(item["quarkuuid"])
        return if quark.nil?
        Quark::openQuark(quark)
    end

    # Asteroids::asteroidToString(item)
    def self.asteroidToString(item)
        itemuuid = item["uuid"]
        quark = Nyx::getOrNull(item["quarkuuid"])
        isRunning = Runner::isRunning(itemuuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(itemuuid).to_f/3600).round(2)} hour)" : ""
        "[todo item] (bank: #{(Bank::value(itemuuid).to_f/3600).round(2)} hours) [#{item["orbitalname"].yellow}] [#{quark ? quark["type"] : "[null quark]"}] #{Asteroids::asteroidBestDescription(item)}#{runningSuffix}"
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

    # Asteroids::projectNames()
    def self.projectNames()
        Asteroids::asteroids()
            .map{|item| item["orbitalname"] }
            .uniq
            .sort
    end

    # Asteroids::orbitalName2orbitalUuidOrNUll(orbitalname)
    def self.orbitalName2orbitalUuidOrNUll(orbitalname)
        orbitaluuid = KeyValueStore::getOrNull(nil, "440e3a2b-043c-4835-a59b-96deffb72f01:#{orbitalname}")
        return orbitaluuid if !orbitaluuid.nil?
        orbitaluuid = Asteroids::asteroids().select{|item| item["orbitalname"] == orbitalname }.first["orbitaluuid"]
        if !orbitaluuid.nil? then
            KeyValueStore::set(nil, "440e3a2b-043c-4835-a59b-96deffb72f01:#{orbitalname}", orbitaluuid)
        end
        orbitaluuid
    end

    # Asteroids::selectOrbitalNameInteractivelyOrNull()
    def self.selectOrbitalNameInteractivelyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", Asteroids::projectNames().sort)
    end

    # Asteroids::asteroidsForOrbitalName(orbitalname)
    def self.asteroidsForOrbitalName(orbitalname)
        orbitaluuid = Asteroids::orbitalName2orbitalUuidOrNUll(orbitalname)
        return [] if orbitaluuid.nil?
        Asteroids::asteroids()
            .select{|item| item["orbitaluuid"] == orbitaluuid }
            .sort{|i1, i2| i1["creationUnixtime"]<=>i2["creationUnixtime"] }
    end

    # Asteroids::projectsTimeDistribution()
    def self.projectsTimeDistribution()
        Asteroids::projectNames().map{|orbitalname|
            orbitaluuid = Asteroids::orbitalName2orbitalUuidOrNUll(orbitalname)
            {
                "orbitalname" => orbitalname,
                "orbitaluuid" => orbitaluuid,
                "timeInHours" => Bank::value(orbitaluuid).to_f/3600
            }
        }
    end

    # Asteroids::updateAsteroidOrbitalName(item)
    def self.updateAsteroidOrbitalName(item)
        orbitalname = Asteroids::selectOrbitalNameInteractivelyOrNull()
        orbitaluuid = nil
        if orbitalname.nil? then
            orbitalname = LucilleCore::askQuestionAnswerAsString("project name? ")
            return if orbitalname == ""
            orbitaluuid = SecureRandom.uuid
        else
            orbitaluuid = Asteroids::orbitalName2orbitalUuidOrNUll(orbitalname)
            return if orbitaluuid.nil?
        end
        item["orbitalname"] = orbitalname
        item["orbitaluuid"] = orbitaluuid
        Nyx::commitToDisk(item)
    end

    # Asteroids::recastAsCubeContent(item) # Boolean # Indicates whether a promotion was acheived
    def self.recastAsCubeContent(item) # Boolean # Indicates whether a promotion was acheived
        quark = Nyx::getOrNull(item["quarkuuid"])
        return false if quark.nil?
        cube = CubeMakeAndOrSelectQuest::makeAndOrSelectCubeOrNull()
        return false if cube.nil?
        cube["quarksuuids"] << quark["uuid"]
        puts JSON.pretty_generate(cube)
        Nyx::commitToDisk(cube)
        return true
    end

    # Asteroids::asteroidDive(item)
    def self.asteroidDive(item)
        loop {
            puts ""
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
                "promote from Asteroid to Data"
            ]
            if Runner::isRunning(item["uuid"]) then
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
                quark = Nyx::getOrNull(item["quarkuuid"])
                next if quark.nil?
                Quark::openQuark(quark)
            end
            if option == "done" then
                Nyx::destroy(item["uuid"])
                return
            end
            if option == "set description" then
                item["description"] = CatalystCommon::editTextUsingTextmate(item["description"])
                Nyx::commitToDisk(item)
            end
            if option == "recast" then
                Asteroids::updateAsteroidOrbitalName(item)
            end
            if option == "push" then
                item["creationUnixtime"] = Time.new.to_f
                Nyx::commitToDisk(item)
            end
            if option == "promote from Asteroid to Data" then
                status = Asteroids::recastAsCubeContent(item)
                next if !status
                Nyx::destroy(item["uuid"])
                return
            end
        }
    end

    # Asteroids::asteroids()
    def self.asteroids()
        Nyx::objects("asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37")
    end
end
