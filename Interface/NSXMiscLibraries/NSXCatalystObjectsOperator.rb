
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

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = JSON.parse(IO.read("#{CATALYST_FOLDERPATH}/TheBridge/sources.json"))
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

        # Some of those objects might have been pushed to the future (something that happens outside the jurisdiction of the agents)
        # We remove those but we keep those that are running
        # Objects in the future which may be running have either
        # 1. Been incorrectly sent to the future while running
        # 2. Might have been started while being in the future after a search.
        objects = objects
            .select{|object|
                b1 = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']).nil?
                b2 = object["isRunning"]
                b1 or b2
            }

        objects = objects
            .select{|object|
                b1 = object['metric'] >= 0.2
                b2 = object["isRunning"]
                b1 or b2
            }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        loop {
            break if objects.empty?
            break if objects.size == 1
            break if objects[0]["contentItem"]["line"].nil?
            break if !objects[0]["contentItem"]["line"].include?('running: Wave')
            objects[0]["metric"] = objects[0]["metric"] - 0.01
            objects = objects
                .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                .reverse
        }

        objects
    end
end
