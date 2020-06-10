
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

        return [] if objects.empty?

        while objects[0]["uuid"] == "39909ff4-e102-45c2-ace9-21be21572772" and objects[0]["isRunning"] and objects.any?{|object| object["x-wave"] } do
            objects[0]["metric"] = objects[0]["metric"] - 0.0001
            objects = objects
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse
        end

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
end
