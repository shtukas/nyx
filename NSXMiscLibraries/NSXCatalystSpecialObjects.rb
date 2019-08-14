
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

class NSXCatalystSpecialObjects

    # NSXCatalystSpecialObjects::specialObject1OrNull()
    def self.specialObject1OrNull()
        return nil if KeyValueStore::flagIsTrue(nil, "33319c02-f1cd-4296-a772-43bb5b6ba07f:#{NSXMiscUtils::currentDay()}")
        object = {}
        object["uuid"] = "392eb09c-572b-481d-9e8e-894e9fa016d4-so1"
        object["agentuid"] = nil
        object["metric"] = 0.60
        object["announce"] = "Daily Guardian Work"
        object["commands"] = ["done"]
        object["executionLambdas"] = {
            "done" => lambda{|object| 
                KeyValueStore::setFlagTrue(nil, "33319c02-f1cd-4296-a772-43bb5b6ba07f:#{NSXMiscUtils::currentDay()}")
            }
        }
        object
    end

    # NSXCatalystSpecialObjects::objects()
    def self.objects()
        [
            NSXCatalystSpecialObjects::specialObject1OrNull()
        ].compact
    end

end
