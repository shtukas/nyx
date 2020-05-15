
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
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

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = ["Anniversaries", "BackupsMonitor", "Calendar", "Gwork", "LucilleTxt", "Projects", "Vienna", "Wave", "YouTubeVideoStream"]
                    .map{|appname| "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/#{appname}/catalyst-objects" }
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
                                    "metric"          => 1,
                                    "commands"        => []
                                }
                            ]
                        end
                    }
                    .flatten

        objects = objects
            .select{|object| DoNotShowUntil::isVisible(object["uuid"]) or object["isRunning"] }
            .sort{|o1, o2| 
                o1["metric"]<=>o2["metric"] }
            .reverse

        objects = objects
            .select{|object|
                b1 = object['metric'] >= 0.2
                b2 = object["isRunning"]
                b1 or b2
            }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        objects
    end
end
