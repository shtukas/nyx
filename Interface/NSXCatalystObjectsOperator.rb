
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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/BackupsMonitor/BackupsMonitor.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/Calendar.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Spaceships/Spaceships.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/VideoStream/VideoStream.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Waves/Waves.rb"

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::applyOrdering(objects)
    def self.applyOrdering(objects)
        objects = objects
                    .select{|object| object['metric'] >= 0.2 }

        objects = objects
                    .select{|object| DoNotShowUntil::isVisible(object["uuid"]) or object["isRunning"] }
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse

        return objects if objects.size < 2

        objects
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = [
            Anniversaries::catalystObjects(),
            Asteroids::catalystObjects(),
            BackupsMonitor::catalystObjects(),
            Calendar::catalystObjects(),
            Spaceships::catalystObjects(),
            VideoStream::catalystObjects(),
            Waves::catalystObjects()
        ].flatten
        NSXCatalystObjectsOperator::applyOrdering(objects)
    end

    # NSXCatalystObjectsOperator::generationSpeedReport()
    def self.generationSpeedReport()
        generators = [
            {
                "name" => "Anniversaries",
                "exec" => lambda{ Anniversaries::catalystObjects() }
            },
            {
                "name" => "Asteroids",
                "exec" => lambda{ Asteroids::catalystObjects() }
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
                "name" => "Spaceships",
                "exec" => lambda{ Spaceships::catalystObjects() }
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
