
# encoding: UTF-8

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

require_relative "Common.rb"

require_relative "Anniversaries.rb"
require_relative "BackupsMonitor.rb"
require_relative "Calendar.rb"
require_relative "Asteroids.rb"
require_relative "VideoStream.rb"
require_relative "Waves.rb"

class NSXCatalystObjectsOperator


    # NSXCatalystObjectsOperator::getMonitoringObjectOrNull()
    def self.getMonitoringObjectOrNull()

        if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("0f5e54c4-14d2-469c-9569-d7a5eaeaa46c", 3600) then
            uuids = Asteroids::asteroids()
                            .select{|asteroid| asteroid["unixtime"] > 1593460928 }
                            .select{|asteroid| asteroid["X02394e74c407"].nil? }
                            .sort{|a1, a2| a1["unixtime"]<=>a2["unixtime"] }
                            .map{|asteroid| asteroid["uuid"] }
            KeyValueStore::set(nil, "a41dd15c-3c7d-4294-a282-d00b8a9db7e1", JSON.generate(uuids))
        end

        uuids = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "a41dd15c-3c7d-4294-a282-d00b8a9db7e1", "[]"))

        return nil if uuids.size == 0

        object = {
            "uuid"             => SecureRandom.hex,
            "body"             => "asteroids monitoring (X02394e74c407)",
            "metric"           => 0.99,
            "commands"         => [],
            "execute"          => lambda { |input|

                uuids
                    .each_with_index{|uuid, indx|
                        system ("clear")

                        puts "#{indx}/#{uuids.count}"

                        asteroid = Asteroids::getOrNull(uuid)

                        next if asteroid.nil?

                        next if asteroid["X02394e74c407"]

                        if asteroid["orbital"]["type"] != "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
                            asteroid["X02394e74c407"] = true
                            Asteroids::commitToDisk(asteroid)
                            next
                        end

                        if asteroid["payload"]["type"] == "quark" then
                            quarkuuid = asteroid["payload"]["quarkuuid"]
                            quark = Quarks::getOrNull(quarkuuid)
                            if quark.nil? then
                                Asteroids::asteroidDestroySequence(asteroid)
                                next
                            end
                        end

                        puts Asteroids::asteroidToString(asteroid)

                        if LucilleCore::askQuestionAnswerAsBoolean("mark as reviewed ? ", true) then
                            asteroid["X02394e74c407"] = true
                            Asteroids::commitToDisk(asteroid)
                            next
                        end

                        if LucilleCore::askQuestionAnswerAsBoolean("open ? ", true) then
                            Asteroids::openPayload(asteroid)
                        end
                        
                        loop {
                            asteroid = Asteroids::getOrNull(asteroid["uuid"])
                            break if asteroid.nil? # could have been destroyed in a previous run
                            break if asteroid["X02394e74c407"] # have been marked as reviewed

                            if asteroid["payload"]["type"] == "quark" then
                                quarkuuid = asteroid["payload"]["quarkuuid"]
                                quark = Quarks::getOrNull(quarkuuid)
                                if quark.nil? then # could have been destroyed in a previous run
                                    Asteroids::asteroidDestroySequence(asteroid)
                                    break
                                end
                            end

                            ms = LCoreMenuItemsNX1.new()
                            ms.item(
                                "mark as reviewed",
                                lambda { 
                                    asteroid["X02394e74c407"] = true
                                    Asteroids::commitToDisk(asteroid)
                                }
                            )
                            ms.item(
                                "dive",
                                lambda { Asteroids::asteroidDive(asteroid) }
                            )
                            ms.item(
                                "destroy asteroid",
                                lambda { Asteroids::asteroidDestroySequence(asteroid) }
                            )
                            ms.item(
                                "destroy asteroid and quark",
                                lambda { 
                                    return if asteroid["payload"]["type"] != "quark"
                                    quarkuuid = asteroid["payload"]["quarkuuid"]
                                    quark = Quarks::getOrNull(quarkuuid)
                                    if quark.nil? then # could have been destroyed in a previous run
                                        Asteroids::asteroidDestroySequence(asteroid)
                                        next
                                    end
                                    NyxObjects::destroy(quark["uuid"])
                                    Asteroids::asteroidDestroySequence(asteroid) 
                                }
                            )
                            status = ms.prompt()
                            break if !status
                        }
                    }
                uuids = Asteroids::asteroids()
                                .select{|asteroid| asteroid["unixtime"] > 1593460928 }
                                .select{|asteroid| asteroid["X02394e74c407"].nil? }
                                .sort{|a1, a2| a1["unixtime"]<=>a2["unixtime"] }
                                .map{|asteroid| asteroid["uuid"] }
                KeyValueStore::set(nil, "a41dd15c-3c7d-4294-a282-d00b8a9db7e1", JSON.generate(uuids))
            },
            "x-asteroid-review" => true
        }

    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = [
            Anniversaries::catalystObjects(),
            Asteroids::catalystObjects(),
            BackupsMonitor::catalystObjects(),
            Calendar::catalystObjects(),
            VideoStream::catalystObjects(),
            Waves::catalystObjects(),
            [ NSXCatalystObjectsOperator::getMonitoringObjectOrNull() ]
        ].flatten.compact
        objects = objects
                    .select{|object| object['metric'] >= 0.2 }
        objects
            .select{|object| DoNotShowUntil::isVisible(object["uuid"]) or object["isRunning"] }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

    # NSXCatalystObjectsOperator::generationSpeedReport()
    def self.generationSpeedReport()
        generators = [
            {
                "name" => "Anniversaries",
                "exec" => lambda{ Anniversaries::catalystObjects() }
            },
            {
                "name" => "BackupsMonitor",
                "exec" => lambda{ BackupsMonitor::catalystObjects() }
            },
            {
                "name" => "Calendar",
                "exec" => lambda{ Calendar::catalystObjects() }
            },
            {
                "name" => "Asteroids",
                "exec" => lambda{ Asteroids::catalystObjects() }
            },
            {
                "name" => "VideoStream",
                "exec" => lambda{ VideoStream::catalystObjects() }
            },
            {
                "name" => "Waves",
                "exec" => lambda{ Waves::catalystObjects() }
            }
        ]

        generators = generators
                        .map{|item|
                            time1 = Time.new.to_f
                            item["exec"].call()
                            item["runtime"] = Time.new.to_f - time1
                            item
                        }
        generators = generators.sort{|item1, item2| item1["runtime"] <=> item2["runtime"] }
        generators.each{|item|
            puts "#{item["name"].ljust(20)} : #{item["runtime"].round(2)}"
        }
        LucilleCore::pressEnterToContinue()
    end
end
