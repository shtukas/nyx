
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------------------

$CATALYST_OBJECTS_NON_AGENT_METADATA = {}

class CatalystObjectsNonAgentMetadataUtils

    # CatalystObjectsNonAgentMetadataUtils::initialLoadFromDisk()
    def self.initialLoadFromDisk()
        $CATALYST_OBJECTS_NON_AGENT_METADATA = JSON.parse(KeyValueStore::getOrDefaultValue(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "52e0f71b-2914-4fdc-b491-0828b50aad05", "{}"))
    end

    # CatalystObjectsNonAgentMetadataUtils::commitCollectionToDisk()
    def self.commitCollectionToDisk()
        KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "52e0f71b-2914-4fdc-b491-0828b50aad05", JSON.generate($CATALYST_OBJECTS_NON_AGENT_METADATA))
    end

    # CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
    def self.getMetadataForObject(objectuuid)
        newmetadata = {
            "objectuuid" => objectuuid
        }
        ($CATALYST_OBJECTS_NON_AGENT_METADATA[objectuuid] || newmetadata).clone
    end

    # CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)
    def self.setMetadataForObject(objectuuid, metadata)
        $CATALYST_OBJECTS_NON_AGENT_METADATA[objectuuid] = metadata
        CatalystObjectsNonAgentMetadataUtils::commitCollectionToDisk()
    end

    # CatalystObjectsNonAgentMetadataUtils::getAllMetadataObjects()
    def self.getAllMetadataObjects()
        $CATALYST_OBJECTS_NON_AGENT_METADATA.values.map{|object| object.clone }
    end

end

CatalystObjectsNonAgentMetadataUtils::initialLoadFromDisk()


=begin

Structure of individual objects metadata
{
    "objectuuid" : UUID
    "nsx-timeprotons-uuids-e9b8519d" : Array[CatalystObjectUUIDs]
}

=end

class MetadataInterface

    # MetadataInterface::setTimeProtonObjectLink(timeProtonUUID, objectuuid)
    def self.setTimeProtonObjectLink(timeProtonUUID, objectuuid)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        if metadata["nsx-timeprotons-uuids-e9b8519d"].nil? then
            metadata["nsx-timeprotons-uuids-e9b8519d"] = []
        end
        metadata["nsx-timeprotons-uuids-e9b8519d"] << timeProtonUUID
        metadata["nsx-timeprotons-uuids-e9b8519d"] = metadata["nsx-timeprotons-uuids-e9b8519d"].uniq
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)
    end

    # MetadataInterface::unSetTimeProtonObjectLink(timeProtonUUID, objectuuid)
    def self.unSetTimeProtonObjectLink(timeProtonUUID, objectuuid)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        if metadata["nsx-timeprotons-uuids-e9b8519d"].nil? then
            metadata["nsx-timeprotons-uuids-e9b8519d"] = []
        end
        metadata["nsx-timeprotons-uuids-e9b8519d"].delete(objectuuid)
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)
    end

    # MetadataInterface::timeProtonCatalystObjectsUUIDs(timeProtonUUID)
    def self.timeProtonCatalystObjectsUUIDs(timeProtonUUID)
        CatalystObjectsNonAgentMetadataUtils::getAllMetadataObjects()
            .select{|metadata|
                (metadata["nsx-timeprotons-uuids-e9b8519d"] || []).include?(timeProtonUUID)
            }
            .map{|metadata| metadata["objectuuid"] }
            .uniq

    end

    # MetadataInterface::timeProtonsAllCatalystObjectsUUIDs()
    def self.timeProtonsAllCatalystObjectsUUIDs()
        CatalystObjectsNonAgentMetadataUtils::getAllMetadataObjects()
            .select{|metadata| (metadata["nsx-timeprotons-uuids-e9b8519d"] || []).size>0 }
            .map{|metadata|
                metadata["objectuuid"]
            }
            .uniq
    end

end
