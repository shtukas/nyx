
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Anniversaries/Anniversaries.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/BackupsMonitor/BackupsMonitor.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/Calendar.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/VideoStream/VideoStream.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Waves/Waves.rb"

class NSXCatalystObjectsOperator


    # NSXCatalystObjectsOperator::getMonitoringObjectOrNull()
    def self.getMonitoringObjectOrNull()

        asteroids = Asteroids::asteroids()
                        .select{|asteroid| asteroid["X02394e74c407"].nil? }

        startingTime  = DateTime.parse("2020-06-28T18:00:25Z").to_time.to_f
        endingTime    = DateTime.parse("2020-07-30T10:44:25Z").to_time.to_f
        startingCount = 6175
        endingCount   = 0
        timeRatio     = (Time.new.to_f - startingTime).to_f/(endingTime-startingTime)
        doneRatio     = (startingCount - asteroids.count).to_f/(startingCount-endingCount)

        return nil if doneRatio > timeRatio

        object = {
            "uuid"             => SecureRandom.hex,
            "body"             => "asteroids monitoring ( doneRatio: #{doneRatio} < timeRatio: #{timeRatio} )",
            "metric"           => 0.99,

            "execute"          => lambda {

                Asteroids::asteroids()
                    .select{|asteroid| asteroid["X02394e74c407"].nil? }
                    .sort{|a1, a2| a1["unixtime"]<=>a2["unixtime"] }
                    .reverse
                    .take(20)
                    .each{|asteroid|
                        system ("clear")

                        if asteroid["orbital"]["type"] != "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
                            asteroid["X02394e74c407"] = true
                            NyxSets::putObject(asteroid)
                            next
                        end

                        if asteroid["payload"]["type"] == "quark" then
                            quarkuuid = asteroid["payload"]["quarkuuid"]
                            quark = Quarks::getOrNull(quarkuuid)
                            if quark.nil? then
                                Asteroids::asteroidDestroySequence(asteroid)
                                next
                            end
                            if quark["type"] == "file" then
                                filename = quark["filename"]
                                if !LibrarianFile::exists?(filename) then
                                    NyxSets::destroy(quark["uuid"])
                                    Asteroids::asteroidDestroySequence(asteroid)
                                    next
                                end
                            end
                        end

                        puts Asteroids::asteroidToString(asteroid)

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
                                    NyxSets::putObject(asteroid)
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
                                    NyxSets::destroy(quark["uuid"])
                                    Asteroids::asteroidDestroySequence(asteroid) 
                                }
                            )
                            status = ms.prompt()
                            break if !status
                        }
                    }
            }
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
