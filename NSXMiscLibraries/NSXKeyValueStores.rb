#!/usr/bin/ruby

# encoding: UTF-8

# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------

CATALYST_IPHETRA_AGENT_DATA_SETUUID_PREFIX = "d0b1f843-324d-469e-80e6-b0f330491287"

=begin
{
    "uuid"  => key,
    "value" => value
}
=end

class NSXAgentsDataKeyValueStore

    # NSXAgentsDataKeyValueStore::agentuuidToSetUUID(agentuuid)
    def self.agentuuidToSetUUID(agentuuid)
        "#{CATALYST_IPHETRA_AGENT_DATA_SETUUID_PREFIX}:#{agentuuid}"
    end

    # NSXAgentsDataKeyValueStore::set(agentuuid, key, value)
    def self.set(agentuuid, key, value)
        object = {
            "uuid"  => key,
            "value" => value
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, NSXAgentsDataKeyValueStore::agentuuidToSetUUID(agentuuid), object)        
    end

    # NSXAgentsDataKeyValueStore::getOrNull(agentuuid, key)
    def self.getOrNull(agentuuid, key)
        object = Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, NSXAgentsDataKeyValueStore::agentuuidToSetUUID(agentuuid), key)
        return nil if object.nil?
        object["value"]
    end

    # NSXAgentsDataKeyValueStore::getOrDefaultValue(agentuuid, key, defaultValue)
    def self.getOrDefaultValue(agentuuid, key, defaultValue)
        value = NSXAgentsDataKeyValueStore::getOrNull(agentuuid, key)
        return value if value
        defaultValue
    end

end
