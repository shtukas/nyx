
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

require_relative "../Catalyst-Common/Catalyst-Common.rb"

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = JSON.parse(IO.read("#{CATALYST_COMMON_CATALYST_FOLDERPATH}/TheBridge/sources.json"))
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
                puts o1
                puts o2
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


        # Make sure that running ifcs Wave is not first
        loop {
            break if objects.size < 2
            break if objects[0]["uuid"] != "8D80531C-E98F-4553-A815-6D3284DE0FF8"
            break if !objects[0]["isRunning"]
            objects[0]["metric"] = objects[0]["metric"] - 0.001
            objects = objects
                .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                .reverse
        }

        objects
    end
end
