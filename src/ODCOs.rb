
# encoding: UTF-8

class ODCOs

    # ODCOs::repositoryPath()
    def self.repositoryPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/ODCOs"
    end

    # ODCOs::getRepositoryObjectByUuid(uuid)
    def self.getRepositoryObjectByUuid(uuid)
        filepath = "#{ODCOs::repositoryPath()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # ODCOs::repositoryUuids()
    def self.repositoryUuids()
        Dir.entries(ODCOs::repositoryPath())
            .select{|filepath|
                filepath[-5, 5] == ".json"
            }
            .map{|filepath|
                filepath[0, filepath.size-5]
            }
    end

    # ODCOs::ordinalToMetric(ordinal)
    def self.ordinalToMetric(ordinal)
        # 0.69  -> 0.66 
        0.66 + 0.03 * Math.exp(-ordinal) # We should probably keep the ordinals positive
    end

    # ODCOs::repositoryObjectToCatalystObject(object)
    def self.repositoryObjectToCatalystObject(object)
        uuid = object["uuid"]
        ordinal = object["ordinal"]
        body = KeyValueStore::getOrNull(nil, "67cbd2ac-657a-45f0-b866-e157f76d6d49:#{uuid}") || "no body found"
        {
            "uuid"             => uuid,
            "body"             => "(ordinal: #{object["ordinal"]}) #{body}",
            "metric"           => ODCOs::ordinalToMetric(ordinal),
            "landing"          => lambda {},
            "nextNaturalStep"  => lambda {},
            "isRunning"        => false,
            "isRunningForLong" => false
        }
    end

    # ODCOs::getCatalystObjects()
    def self.getCatalystObjects()
        ODCOs::repositoryUuids()
            .map{|uuid| ODCOs::getRepositoryObjectByUuid(uuid) }
            .map{|object| ODCOs::repositoryObjectToCatalystObject(object) }
    end
end
