
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

DATA_MANAGER_CATALYST_OBJECTS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Data-Manager/Catalyst-Objects"
DATA_MANAGER_CATALYST_OBJECTS_OBJECTS_V1_REPOSITORY_FOLDERPATH = "#{DATA_MANAGER_CATALYST_OBJECTS_REPOSITORY_FOLDERPATH}/objects-v1"
$DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH = {}
$DATA_MANAGER_CATALYST_OBJECTS_IO_SEMAPHORE = Mutex.new

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::objectsV1FilePaths()
    def self.objectsV1FilePaths()
        filepaths = []
        Find.find(DATA_MANAGER_CATALYST_OBJECTS_OBJECTS_V1_REPOSITORY_FOLDERPATH) do |path|
            next if !File.file?(path)
            next if path[-5,5] != ".json"
            filepaths << path
        end
        filepaths
    end

    # NSXCatalystObjectsOperator::objectsV1InitialLoadFromDisk()
    def self.objectsV1InitialLoadFromDisk()
        NSXCatalystObjectsOperator::objectsV1FilePaths()
            .each{|filepath|
                begin
                    object = JSON.parse(IO.read(filepath))
                    $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH[object["uuid"]] = object
                rescue
                end
            }
    end

    # NSXCatalystObjectsOperator::putObject(object)
    def self.putObject(object)
        filename = "#{Digest::SHA1.hexdigest(object["uuid"])}.json"
        folderpath = "#{DATA_MANAGER_CATALYST_OBJECTS_OBJECTS_V1_REPOSITORY_FOLDERPATH}/#{filename[0,2]}/#{filename[2,2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        File.open("#{folderpath}/#{filename}", "w"){|f| f.puts(JSON.pretty_generate(object)) }
        $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH[object["uuid"]] = object
    end

    # NSXCatalystObjectsOperator::destroyObject(objectuuid)
    def self.destroyObject(objectuuid)
        filename = "#{Digest::SHA1.hexdigest(objectuuid)}.json"
        folderpath = "#{DATA_MANAGER_CATALYST_OBJECTS_OBJECTS_V1_REPOSITORY_FOLDERPATH}/#{filename[0,2]}/#{filename[2,2]}"
        filepath = "#{folderpath}/#{filename}"
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end        
        $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH.delete(objectuuid)
    end

    # NSXCatalystObjectsOperator::initialLoadFromDisk()
    def self.initialLoadFromDisk()
        #$DATA_MANAGER_CATALYST_OBJECTS_IO_SEMAPHORE.synchronize {
        #    $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH = JSON.parse(IO.read("#{DATA_MANAGER_CATALYST_OBJECTS_REPOSITORY_FOLDERPATH}/ffbea143-d99f-4e91-9061-027622b11c09.json"))
        #}
        NSXCatalystObjectsOperator::objectsV1InitialLoadFromDisk()
    end

    # NSXCatalystObjectsOperator::commitCollectionToDisk()
    def self.commitCollectionToDisk()
        #$DATA_MANAGER_CATALYST_OBJECTS_IO_SEMAPHORE.synchronize {
        #    File.open("#{DATA_MANAGER_CATALYST_OBJECTS_REPOSITORY_FOLDERPATH}/ffbea143-d99f-4e91-9061-027622b11c09.json", "w"){|f| f.puts(JSON.pretty_generate($DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH)) }
        #}
        $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH.each{|objectuuid, object| 
            NSXCatalystObjectsOperator::putObject(object)
        }
    end

    # NSXCatalystObjectsOperator::getObjectsFromAgents()
    def self.getObjectsFromAgents()
        NSXBob::agents()
            .each{|agentinterface| 
                agentinterface["get-objects"].call()
                    .each{|object|
                        NSXCatalystObjectsOperator::putObject(object)
                    } 
            }
    end

    # NSXCatalystObjectsOperator::getObjects()
    def self.getObjects()
        $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH.values.compact.map{|object| object.clone }
    end

    # NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
    def self.processAgentProcessorSignal(signal)
        return if signal[0] == "nothing"
        if signal[0] == "update" then
            object = signal[1]
            NSXCatalystObjectsOperator::putObject(object)
        end
        if signal[0] == "remove" then
            objectuuid = signal[1]
            NSXCatalystObjectsOperator::destroyObject(objectuuid)
        end
        if signal[0] == "reload-agent-objects" then
            agentuuid = signal[1]
            # Removing the objects of that agent
            $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH.keys.each{|objectuuid|
                object = $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH[objectuuid]
                next if object["agent-uid"] != agentuuid
                NSXCatalystObjectsOperator::destroyObject(object["uuid"])
            }
            # Recalling agent objects
            agentinterface = NSXBob::agentuuid2AgentDataOrNull(agentuuid)
            return if agentinterface.nil?
            objects = agentinterface["get-objects"].call()
            objects.each{|object| 
                NSXCatalystObjectsOperator::putObject(object)
            }
        end
    end

end

puts "NSXCatalystObjectsOperator::initialLoadFromDisk()"
NSXCatalystObjectsOperator::initialLoadFromDisk()


