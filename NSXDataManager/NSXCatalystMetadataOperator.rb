
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

DATA_MANAGER_CATALYST_METADATA_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Data-Manager/Catalyst-Metadata"
DATA_MANAGER_CATALYST_METADATA_V1_REPOSITORY_FOLDERPATH = "#{DATA_MANAGER_CATALYST_METADATA_REPOSITORY_FOLDERPATH}/metadata-v1"
$DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH = {}
=begin
Map[ObjectUUI, MetadataItem]
MetadataItem {
    "objectuuid" : UUID
    (other key value pairs)
}
=end
$DATA_MANAGER_CATALYST_METADATA_IO_SEMAPHORE = Mutex.new

class NSXCatalystMetadataOperator

    # NSXCatalystMetadataOperator::metadataV1FilePaths()
    def self.metadataV1FilePaths()
        filepaths = []
        Find.find(DATA_MANAGER_CATALYST_METADATA_V1_REPOSITORY_FOLDERPATH) do |path|
            next if !File.file?(path)
            next if path[-5,5] != ".json"
            filepaths << path
        end
        filepaths
    end

    # NSXCatalystMetadataOperator::metadataV1InitialLoadFromDisk()
    def self.metadataV1InitialLoadFromDisk()
        NSXCatalystMetadataOperator::metadataV1FilePaths()
            .each{|filepath|
                begin
                    metadata = JSON.parse(IO.read(filepath))
                    $DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH[metadata["objectuuid"]] = metadata
                rescue
                end
            }
    end

    # NSXCatalystMetadataOperator::putItem(metadata)
    def self.putItem(metadata)
        filename = "#{Digest::SHA1.hexdigest(metadata["objectuuid"])}.json"
        folderpath = "#{DATA_MANAGER_CATALYST_METADATA_V1_REPOSITORY_FOLDERPATH}/#{filename[0,2]}/#{filename[2,2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        File.open("#{folderpath}/#{filename}", "w"){|f| f.puts(JSON.pretty_generate(metadata)) }
        $DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH[metadata["objectuuid"]] = metadata
    end

    # NSXCatalystMetadataOperator::initialLoadFromDisk()
    def self.initialLoadFromDisk()
        #filepath = "#{DATA_MANAGER_CATALYST_METADATA_REPOSITORY_FOLDERPATH}/f98188eb-49eb-4cee-9342-1a39815d01e5.json"
        #$DATA_MANAGER_CATALYST_METADATA_IO_SEMAPHORE.synchronize {
        #    $DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH = JSON.parse(IO.read(filepath))
        #}
        NSXCatalystMetadataOperator::metadataV1InitialLoadFromDisk()
    end

    # NSXCatalystMetadataOperator::commitCollectionToDisk()
    def self.commitCollectionToDisk()
        #$DATA_MANAGER_CATALYST_METADATA_IO_SEMAPHORE.synchronize {
        #    File.open("#{DATA_MANAGER_CATALYST_METADATA_REPOSITORY_FOLDERPATH}/f98188eb-49eb-4cee-9342-1a39815d01e5.json", "w"){|f| f.puts(JSON.pretty_generate($DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH)) }
        #}
        $DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH.each{|objectuuid, metadata| 
            NSXCatalystMetadataOperator::putItem(metadata)
        }
    end

    # NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
    def self.getMetadataForObject(objectuuid)
        newmetadata = {
            "objectuuid" => objectuuid
        }
        ($DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH[objectuuid] || newmetadata).clone
    end

    # NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    def self.setMetadataForObject(objectuuid, metadata)
        NSXCatalystMetadataOperator::putItem(metadata)
    end

    # NSXCatalystMetadataOperator::getAllMetadataObjects()
    def self.getAllMetadataObjects()
        $DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH.values.map{|object| object.clone }
    end

end

puts "NSXCatalystMetadataOperator::initialLoadFromDisk()"
NSXCatalystMetadataOperator::initialLoadFromDisk()

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
        metadata["nsx-cycle-unixtime-a3390e5c"] =  unixtime
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)        
    end

    # NSXCatalystMetadataInterface::unSetMetricCycleUnixtimeForObject(objectuuid)
    def self.unSetMetricCycleUnixtimeForObject(objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        metadata.delete("nsx-cycle-unixtime-a3390e5c")     
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    end    

    # NSXCatalystMetadataInterface::getMetricCycleUnixtimeForObjectOrNull(objectuuid)
    def self.getMetricCycleUnixtimeForObjectOrNull(objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        metadata["nsx-cycle-unixtime-a3390e5c"]       
    end

end
