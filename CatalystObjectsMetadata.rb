
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
    "nsx-requirements-c633a5d8"      : Array[String]
    "nsx-cycle-unixtime-a3390e5c"    : Unixitime
    "nsx-ordinal-per-day"            : Map[Date, Ordinal]
}

=end

class MetadataInterface

    # -----------------------------------------------------------------------
    # Ordinal

    # MetadataInterface::setOrdinal(objectuuid, ordinal)
    def self.setOrdinal(objectuuid, ordinal)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        if metadata["nsx-ordinal-per-day"].nil? then
            metadata["nsx-ordinal-per-day"] = {}
        end
        metadata["nsx-ordinal-per-day"][NSXMiscUtils::currentDay()] = ordinal
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)
    end

    # MetadataInterface::getOrdinalOrNull(objectuuid)
    def self.getOrdinalOrNull(objectuuid)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        if metadata["nsx-ordinal-per-day"].nil? then
            metadata["nsx-ordinal-per-day"] = {}
        end
        metadata["nsx-ordinal-per-day"][NSXMiscUtils::currentDay()]
    end

    # -----------------------------------------------------------------------
    # TimeProton CatalystObject link

    # MetadataInterface::setTimeProtonObjectLink(lightThreadUUID, objectuuid)
    def self.setTimeProtonObjectLink(lightThreadUUID, objectuuid)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        if metadata["nsx-timeprotons-uuids-e9b8519d"].nil? then
            metadata["nsx-timeprotons-uuids-e9b8519d"] = []
        end
        metadata["nsx-timeprotons-uuids-e9b8519d"] << lightThreadUUID
        metadata["nsx-timeprotons-uuids-e9b8519d"] = metadata["nsx-timeprotons-uuids-e9b8519d"].uniq
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)
    end

    # MetadataInterface::unSetTimeProtonObjectLink(lightThreadUUID, objectuuid)
    def self.unSetTimeProtonObjectLink(lightThreadUUID, objectuuid)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        if metadata["nsx-timeprotons-uuids-e9b8519d"].nil? then
            metadata["nsx-timeprotons-uuids-e9b8519d"] = []
        end
        metadata["nsx-timeprotons-uuids-e9b8519d"].delete(lightThreadUUID)
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)
    end

    # MetadataInterface::lightThreadCatalystObjectsUUIDs(lightThreadUUID)
    def self.lightThreadCatalystObjectsUUIDs(lightThreadUUID)
        CatalystObjectsNonAgentMetadataUtils::getAllMetadataObjects()
            .select{|metadata|
                (metadata["nsx-timeprotons-uuids-e9b8519d"] || []).include?(lightThreadUUID)
            }
            .map{|metadata| metadata["objectuuid"] }
            .uniq
    end

    # MetadataInterface::lightThreadsAllCatalystObjectsUUIDs()
    def self.lightThreadsAllCatalystObjectsUUIDs()
        CatalystObjectsNonAgentMetadataUtils::getAllMetadataObjects()
            .select{|metadata| (metadata["nsx-timeprotons-uuids-e9b8519d"] || []).size>0 }
            .map{|metadata|
                metadata["objectuuid"]
            }
            .uniq
    end

    # -----------------------------------------------------------------------
    # Objects Requirements

    # MetadataInterface::setRequirementForObject(objectuuid, requirement)
    def self.setRequirementForObject(objectuuid, requirement)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        if metadata["nsx-requirements-c633a5d8"].nil? then
            metadata["nsx-requirements-c633a5d8"] = []
        end
        metadata["nsx-requirements-c633a5d8"] << requirement
        metadata["nsx-requirements-c633a5d8"] = metadata["nsx-requirements-c633a5d8"].uniq
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)        
    end

    # MetadataInterface::unSetRequirementForObject(objectuuid, requirement)
    def self.unSetRequirementForObject(objectuuid, requirement)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        if metadata["nsx-requirements-c633a5d8"].nil? then
            metadata["nsx-requirements-c633a5d8"] = []
        end
        metadata["nsx-requirements-c633a5d8"].delete(requirement)
        metadata["nsx-requirements-c633a5d8"] = metadata["nsx-requirements-c633a5d8"].uniq
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)        
    end

    # MetadataInterface::getObjectsRequirements(objectuuid)
    def self.getObjectsRequirements(objectuuid)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        metadata["nsx-requirements-c633a5d8"] || []        
    end

    # MetadataInterface::allObjectRequirementsAreSatisfied(objectuuid)
    def self.allObjectRequirementsAreSatisfied(objectuuid)
        MetadataInterface::getObjectsRequirements(objectuuid)
            .all?{|requirement| RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    # MetadataInterface::allKnownRequirementsCarriedByObjects()
    def self.allKnownRequirementsCarriedByObjects()
        CatalystObjectsNonAgentMetadataUtils::getAllMetadataObjects()
            .map{|metadata| metadata["nsx-requirements-c633a5d8"] || []}
            .flatten
            .uniq
    end

    # -----------------------------------------------------------------------
    # Cycle Unixtimes

    # MetadataInterface::setMetricCycleUnixtimeForObject(objectuuid,  unixtime)
    def self.setMetricCycleUnixtimeForObject(objectuuid,  unixtime)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        metadata["nsx-cycle-unixtime-a3390e5c"] =  unixtime
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)        
    end

    # MetadataInterface::unSetMetricCycleUnixtimeForObject(objectuuid)
    def self.unSetMetricCycleUnixtimeForObject(objectuuid)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        metadata.delete("nsx-cycle-unixtime-a3390e5c")     
        CatalystObjectsNonAgentMetadataUtils::setMetadataForObject(objectuuid, metadata)
    end    

    # MetadataInterface::getMetricCycleUnixtimeForObjectOrNull(objectuuid)
    def self.getMetricCycleUnixtimeForObjectOrNull(objectuuid)
        metadata = CatalystObjectsNonAgentMetadataUtils::getMetadataForObject(objectuuid)
        metadata["nsx-cycle-unixtime-a3390e5c"]       
    end

end
