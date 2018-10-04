
# encoding: UTF-8

# ----------------------------------------------------------------------------------

DATA_MANAGER_CATALYST_OBJECTS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Data-Manager/Catalyst-Objects"
$DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH = {}
$DATA_MANAGER_CATALYST_OBJECTS_IO_SEMAPHORE = Mutex.new

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::initialLoadFromDisk()
    def self.initialLoadFromDisk()
        $DATA_MANAGER_CATALYST_OBJECTS_IO_SEMAPHORE.synchronize {
            $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH = JSON.parse(IO.read("#{DATA_MANAGER_CATALYST_OBJECTS_REPOSITORY_FOLDERPATH}/ffbea143-d99f-4e91-9061-027622b11c09.json"))
        }
    end

    # NSXCatalystObjectsOperator::commitCollectionToDisk()
    def self.commitCollectionToDisk()
        $DATA_MANAGER_CATALYST_OBJECTS_IO_SEMAPHORE.synchronize {
            File.open("#{DATA_MANAGER_CATALYST_OBJECTS_REPOSITORY_FOLDERPATH}/ffbea143-d99f-4e91-9061-027622b11c09.json", "w"){|f| f.puts(JSON.pretty_generate($DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH)) }
        }
    end

    # NSXCatalystObjectsOperator::getObjectsFromAgents()
    def self.getObjectsFromAgents()
        NSXBob::agents()
            .each{|agentinterface| 
                agentinterface["get-objects"].call()
                    .each{|object|
                        $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH[object["uuid"]] = object
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
            $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH[object["uuid"]] = object
            NSXCatalystObjectsOperator::commitCollectionToDisk()
        end
        if signal[0] == "remove" then
            objectuuid = signal[1]
            $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH.delete(objectuuid)
            NSXCatalystObjectsOperator::commitCollectionToDisk()
        end
        if signal[0] == "reload-agent-objects" then
            agentuuid = signal[1]
            # Removing the objects of that agent
            $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH.keys.each{|objectuuid|
                object = $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH[objectuuid]
                next if object["agent-uid"] != agentuuid
                $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH.delete(object["uuid"])
            }
            # Recalling agent objects
            agentinterface = NSXBob::agentuuid2AgentDataOrNull(agentuuid)
            return if agentinterface.nil?
            objects = agentinterface["get-objects"].call()
            objects.each{|object| $DATA_MANAGER_CATALYST_OBJECTS_IN_MEMORY_HASH[object["uuid"]] = object }
            NSXCatalystObjectsOperator::commitCollectionToDisk()
        end
    end

end

NSXCatalystObjectsOperator::initialLoadFromDisk()

