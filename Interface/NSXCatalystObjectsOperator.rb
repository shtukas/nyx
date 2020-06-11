
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

        # Making sure that a running asap-managed-killer is not the first element
        loop {
            break if ( objects[0]["uuid"] != "1da6ff24-e81b-4257-b533-0a9e6a5bd1e9" or !objects[0]["isRunning"] )
            objects[0]["metric"] = objects[0]["metric"] - 0.0001
            objects = objects
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse
        }

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
