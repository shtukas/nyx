
# encoding: UTF-8

require "json"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

# ----------------------------------------------------------------------------------

=begin

Structure of individual objects metadata
{
    "objectuuid" : UUID
    "nsx-timeprotons-uuids-e9b8519d" : Array[CatalystObjectUUIDs]
    "nsx-requirements-c633a5d8"      : Array[String]
    "nsx-cycle-unixtime-20181005-085102-091691"    : Unixitime
    "nsx-ordinal-per-day"            : Map[Date, Ordinal]
}

=end

class NSXCatalystMetadataInterface

    # -----------------------------------------------------------------------
    # Ordinal

    # NSXCatalystMetadataInterface::setOrdinal(objectuuid, ordinal)
    def self.setOrdinal(objectuuid, ordinal)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        if metadata["nsx-ordinal-per-day"].nil? then
            metadata["nsx-ordinal-per-day"] = {}
        end
        metadata["nsx-ordinal-per-day"][NSXMiscUtils::currentDay()] = ordinal
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    end

    # NSXCatalystMetadataInterface::getOrdinalOrNull(objectuuid)
    def self.getOrdinalOrNull(objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        if metadata["nsx-ordinal-per-day"].nil? then
            metadata["nsx-ordinal-per-day"] = {}
        end
        metadata["nsx-ordinal-per-day"][NSXMiscUtils::currentDay()]
    end

    # -----------------------------------------------------------------------
    # TimeProton CatalystObject link

    # NSXCatalystMetadataInterface::setTimeProtonObjectLink(lightThreadUUID, objectuuid)
    def self.setTimeProtonObjectLink(lightThreadUUID, objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        if metadata["nsx-timeprotons-uuids-e9b8519d"].nil? then
            metadata["nsx-timeprotons-uuids-e9b8519d"] = []
        end
        metadata["nsx-timeprotons-uuids-e9b8519d"] << lightThreadUUID
        metadata["nsx-timeprotons-uuids-e9b8519d"] = metadata["nsx-timeprotons-uuids-e9b8519d"].uniq
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    end

    # NSXCatalystMetadataInterface::unSetTimeProtonObjectLink(lightThreadUUID, objectuuid)
    def self.unSetTimeProtonObjectLink(lightThreadUUID, objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        if metadata["nsx-timeprotons-uuids-e9b8519d"].nil? then
            metadata["nsx-timeprotons-uuids-e9b8519d"] = []
        end
        metadata["nsx-timeprotons-uuids-e9b8519d"].delete(lightThreadUUID)
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    end

    # NSXCatalystMetadataInterface::lightThreadCatalystObjectsUUIDs(lightThreadUUID)
    def self.lightThreadCatalystObjectsUUIDs(lightThreadUUID)
        NSXCatalystMetadataOperator::getAllMetadataObjects()
            .select{|metadata|
                (metadata["nsx-timeprotons-uuids-e9b8519d"] || []).include?(lightThreadUUID)
            }
            .map{|metadata| metadata["objectuuid"] }
            .uniq
    end

    # NSXCatalystMetadataInterface::lightThreadsAllCatalystObjectsUUIDs()
    def self.lightThreadsAllCatalystObjectsUUIDs()
        NSXCatalystMetadataOperator::getAllMetadataObjects()
            .select{|metadata| (metadata["nsx-timeprotons-uuids-e9b8519d"] || []).size>0 }
            .map{|metadata|
                metadata["objectuuid"]
            }
            .uniq
    end

    # -----------------------------------------------------------------------
    # Objects Requirements

    # NSXCatalystMetadataInterface::setRequirementForObject(objectuuid, requirement)
    def self.setRequirementForObject(objectuuid, requirement)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        if metadata["nsx-requirements-c633a5d8"].nil? then
            metadata["nsx-requirements-c633a5d8"] = []
        end
        metadata["nsx-requirements-c633a5d8"] << requirement
        metadata["nsx-requirements-c633a5d8"] = metadata["nsx-requirements-c633a5d8"].uniq
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)        
    end

    # NSXCatalystMetadataInterface::unSetRequirementForObject(objectuuid, requirement)
    def self.unSetRequirementForObject(objectuuid, requirement)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        if metadata["nsx-requirements-c633a5d8"].nil? then
            metadata["nsx-requirements-c633a5d8"] = []
        end
        metadata["nsx-requirements-c633a5d8"].delete(requirement)
        metadata["nsx-requirements-c633a5d8"] = metadata["nsx-requirements-c633a5d8"].uniq
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)        
    end

    # NSXCatalystMetadataInterface::getObjectsRequirements(objectuuid)
    def self.getObjectsRequirements(objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        metadata["nsx-requirements-c633a5d8"] || []        
    end

    # NSXCatalystMetadataInterface::allObjectRequirementsAreSatisfied(objectuuid)
    def self.allObjectRequirementsAreSatisfied(objectuuid)
        NSXCatalystMetadataInterface::getObjectsRequirements(objectuuid)
            .all?{|requirement| NSXRequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    # NSXCatalystMetadataInterface::allKnownRequirementsCarriedByObjects()
    def self.allKnownRequirementsCarriedByObjects()
        NSXCatalystMetadataOperator::getAllMetadataObjects()
            .map{|metadata| metadata["nsx-requirements-c633a5d8"] || []}
            .flatten
            .uniq
    end

    # -----------------------------------------------------------------------
    # Cycle Unixtimes

    # NSXCatalystMetadataInterface::setMetricCycleUnixtimeForObject(objectuuid,  unixtime)
    def self.setMetricCycleUnixtimeForObject(objectuuid,  unixtime)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        metadata["nsx-cycle-unixtime-20181005-085102-091691"] =  [NSXMiscUtils::currentDay(), unixtime]
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)        
    end

    # NSXCatalystMetadataInterface::unSetMetricCycleUnixtimeForObject(objectuuid)
    def self.unSetMetricCycleUnixtimeForObject(objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        metadata.delete("nsx-cycle-unixtime-20181005-085102-091691")     
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    end    

    # NSXCatalystMetadataInterface::getMetricCycleUnixtimeForObjectOrNull(objectuuid)
    def self.getMetricCycleUnixtimeForObjectOrNull(objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        pair = metadata["nsx-cycle-unixtime-20181005-085102-091691"]
        return nil if pair.nil?
        (pair[0] == NSXMiscUtils::currentDay()) ? pair[1] : nil
    end

end
