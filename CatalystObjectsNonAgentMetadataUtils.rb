
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

    def self.getMetadataForObject(objectuuid)
        $CATALYST_OBJECTS_NON_AGENT_METADATA[objectuuid].clone
    end

    def self.setMetadataForObject(objectuuid, metadata)
        $CATALYST_OBJECTS_NON_AGENT_METADATA[objectuuid] = metadata
        CatalystObjectsNonAgentMetadataUtils::commitCollectionToDisk()
    end

end

CatalystObjectsNonAgentMetadataUtils::initialLoadFromDisk()

