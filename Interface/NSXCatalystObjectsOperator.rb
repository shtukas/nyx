
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

class NSXCatalystObjectsCommon

    # NSXCatalystObjectsCommon::applicationNames()
    def self.applicationNames()
        ["Anniversaries", "BackupsMonitor", "Calendar", "LucilleTxt1", "LucilleTxt0", "TimePods", "Todo", "Vienna", "Wave", "VideoStream"]
    end

    # NSXCatalystObjectsCommon::processing(objects)
    def self.processing(objects)
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

    # NSXCatalystObjectsCommon::getObjectsFromSource(scriptfilepath)
    def self.getObjectsFromSource(scriptfilepath)
        begin
            JSON.parse(`#{scriptfilepath}`)
        rescue
            [
                {
                    "uuid"            => SecureRandom.hex,
                    "application"     => "Interface",
                    "contentItem"     => {
                        "type" => "line",
                        "line" => "Problems extracting catalyst objects at '#{source}'"
                    },
                    "metric"          => 1.1,
                    "commands"        => []
                }
            ]
        end
    end
end

$CE605907 = {}

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = NSXCatalystObjectsCommon::applicationNames()
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

        NSXCatalystObjectsCommon::processing(objects)
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrderedFast()
    def self.getCatalystListingObjectsOrderedFast()
        NSXCatalystObjectsCommon::applicationNames()
            .select{|appname| $CE605907[appname].nil? or ["LucilleTxt0", "LucilleTxt1"].include?(appname) }
            .each{|appname| 
                scriptfilepath = "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/#{appname}/x-catalyst-objects" 
                $CE605907[appname] = NSXCatalystObjectsCommon::getObjectsFromSource(scriptfilepath)
            }
        objects = $CE605907.values.flatten.map{|object| object.clone }
        NSXCatalystObjectsCommon::processing(objects)
    end
end




