
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

        # Wave has its own implementation of NSXDoNotShowUntilDatetime because
        # that's how it controls its own elements
        # Catalyst also needs one because it itself sends some elements to the future 
        # with command ++

        objects = objects
            .select{|object|
                b1 = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object["uuid"]).nil?
                b2 = object["isRunning"]
                b1 or b2
            }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        objects = objects
            .select{|object|
                b1 = object['metric'] >= 0.2
                b2 = object["isRunning"]
                b1 or b2
            }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse


        objectIsContentItemLineAndInclude = lambda {|object, str|
            return false if object["contentItem"]["line"].nil?
            object["contentItem"]["line"].include?(str)
        }

        # Make sure that ifcs 'running: Wave' is not first
        loop {
            break if objects.size < 2
            break if !objectIsContentItemLineAndInclude.call(objects[0], 'running: Wave')
            objects[0]["metric"] = objects[0]["metric"] - 0.001
            objects = objects
                .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                .reverse
        }

        # Make sure that ifcs 'start:' is not first if there are [Inbox] elements
        loop {
            break if objects.size < 2
            break if !objectIsContentItemLineAndInclude.call(objects[0], 'start:')
            break if !objectIsContentItemLineAndInclude.call(objects[1], '[Inbox]')
            objects[0]["metric"] = objects[0]["metric"] - 0.001
            objects = objects
                .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                .reverse
        }

        objects
    end
end
