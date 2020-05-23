
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/InFlightControlSystem.rb"

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::applicationNames()
    def self.applicationNames()
        ["Anniversaries", "BackupsMonitor", "Calendar", "Gwork", "InFlightControlSystem", "LucilleTxt", "TimePods", "Todo", "Vienna", "Wave", "YouTubeVideoStream"]
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = NSXCatalystObjectsOperator::applicationNames()
                    .map{|appname| "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/#{appname}/x-catalyst-objects" }
                    .map{|source|
                        begin
                            JSON.parse(`#{source}`)
                        rescue
                            [
                                {
                                    "uuid"            => SecureRandom.hex,
                                    "contentItem"     => {
                                        "type" => "line",
                                        "line" => "Problems extracting catalyst objects at '#{source}'"
                                    },
                                    "metric"          => 1.1,
                                    "commands"        => []
                                }
                            ]
                        end
                    }
                    .flatten

        objects = objects
                    .select{|object| object['metric'] >= 0.2 }

        objects = objects
                    .select{|object| DoNotShowUntil::isVisible(object["uuid"]) or object["isRunning"] }
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse

        while objects[0]["uuid"] == "39909ff4-e102-45c2-ace9-21be21572772" and objects[0]["isRunning"] and objects.any?{|object| object["x-interface:isWave"] } do
            objects[0]["metric"] = objects[0]["metric"] - 0.0001
            objects = objects
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse
        end

        objects
    end
end
