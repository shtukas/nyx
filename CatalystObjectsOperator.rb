
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------------------

$CATALYST_OBJECTS_IN_MEMORY = {}
$semaphore22d1768a = Mutex.new

class CatalystObjectsOperator

    # CatalystObjectsOperator::initialLoadFromDisk()
    def self.initialLoadFromDisk()
        $CATALYST_OBJECTS_IN_MEMORY = JSON.parse(KeyValueStore::getOrDefaultValue(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "80ce3a9c-1b06-4f05-ab8e-a285b1945c8d", "{}"))
    end

    # CatalystObjectsOperator::commitCollectionToDisk()
    def self.commitCollectionToDisk()
        $semaphore22d1768a.synchronize {
            KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "80ce3a9c-1b06-4f05-ab8e-a285b1945c8d", JSON.generate($CATALYST_OBJECTS_IN_MEMORY))
        }
    end

    # CatalystObjectsOperator::getObjectsFromAgents()
    def self.getObjectsFromAgents()
        NSXBob::agents()
            .each{|agentinterface| 
                agentinterface["get-objects"].call()
                    .each{|object|
                        $CATALYST_OBJECTS_IN_MEMORY[object["uuid"]] = object
                    } 
            }
    end

    # CatalystObjectsOperator::getObjects()
    def self.getObjects()
        $CATALYST_OBJECTS_IN_MEMORY.values.compact.map{|object| object.clone }
    end

    # CatalystObjectsOperator::processAgentProcessorSignal(signal)
    def self.processAgentProcessorSignal(signal)
        puts "signal: #{signal.join(" ")}"
        return if signal[0] == "nothing"
        if signal[0] == "update" then
            object = signal[1]
            $CATALYST_OBJECTS_IN_MEMORY[object["uuid"]] = object
            CatalystObjectsOperator::commitCollectionToDisk()
        end
        if signal[0] == "remove" then
            objectuuid = signal[1]
            $CATALYST_OBJECTS_IN_MEMORY.delete(objectuuid)
            CatalystObjectsOperator::commitCollectionToDisk()
        end
        if signal[0] == "reload-agent-objects" then
            agentuuid = signal[1]
            # Removing the objects of that agent
            $CATALYST_OBJECTS_IN_MEMORY.keys.each{|objectuuid|
                object = $CATALYST_OBJECTS_IN_MEMORY[objectuuid]
                next if object["agent-uid"] != agentuuid
                $CATALYST_OBJECTS_IN_MEMORY.delete(object["uuid"])
            }
            # Recalling agent objects
            agentinterface = NSXBob::agentuuid2AgentDataOrNull(agentuuid)
            return if agentinterface.nil?
            objects = agentinterface["get-objects"].call()
            objects.each{|object| $CATALYST_OBJECTS_IN_MEMORY[object["uuid"]] = object }
            CatalystObjectsOperator::commitCollectionToDisk()
        end
    end

end

CatalystObjectsOperator::initialLoadFromDisk()

Thread.new {
    loop {
        sleep 12
        CatalystObjectsOperator::getObjectsFromAgents()
        sleep 120
        CatalystObjectsOperator::commitCollectionToDisk()
    }
}

