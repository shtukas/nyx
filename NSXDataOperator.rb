#!/usr/bin/ruby

# encoding: UTF-8

# ----------------------------------------------------------------------------------

CATALYST_IPHETRA_AGENT_DATA_SETUUID_PREFIX = "d0b1f843-324d-469e-80e6-b0f330491287"

=begin
{
    "uuid"  => key,
    "value" => value
}
=end

class NSXAgentsDataOperator

    # NSXAgentsDataOperator::agentuuidToSetUUID(agentuuid)
    def self.agentuuidToSetUUID(agentuuid)
        "#{CATALYST_IPHETRA_AGENT_DATA_SETUUID_PREFIX}:#{agentuuid}"
    end

    # NSXAgentsDataOperator::set(agentuuid, key, value)
    def self.set(agentuuid, key, value)
        object = {
            "uuid"  => key,
            "value" => value
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, NSXAgentsDataOperator::agentuuidToSetUUID(agentuuid), object)        
    end

    # NSXAgentsDataOperator::getOrNull(agentuuid, key)
    def self.getOrNull(agentuuid, key)
        object = Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, NSXAgentsDataOperator::agentuuidToSetUUID(agentuuid), key)
        return nil if object.nil?
        object["value"]
    end

    # NSXAgentsDataOperator::getOrDefaultValue(agentuuid, key, defaultValue)
    def self.getOrDefaultValue(agentuuid, key, defaultValue)
        value = NSXAgentsDataOperator::getOrNull(agentuuid, key)
        return value if value
        defaultValue
    end

    # NSXAgentsDataOperator::destroy(agentuuid, key)
    def self.destroy(agentuuid, key)
        Iphetra::destroyObject(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, NSXAgentsDataOperator::agentuuidToSetUUID(agentuuid), key)
    end

end

# ----------------------------------------------------------------------------------

$CATALYST_OBJECTS_996CA6AB = {}

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::putObject(object)
    def self.putObject(object)
        $CATALYST_OBJECTS_996CA6AB[object["uuid"]] = object
    end

    # NSXCatalystObjectsOperator::destroyObject(objectuuid)
    def self.destroyObject(objectuuid)
        $CATALYST_OBJECTS_996CA6AB.delete(objectuuid)
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
        $CATALYST_OBJECTS_996CA6AB.values
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
            NSXCatalystObjectsOperator::getObjects().each{|object|
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

# ----------------------------------------------------------------------------------

CATALYST_IPHETRA_SYSTEM_DATA_SETUUID = "e13183f1-4615-49a9-8862-b23a38783f26"

=begin
{
    "uuid"  => key,
    "value" => value
}
=end

class NSXSystemDataOperator

    # NSXSystemDataOperator::set(key, value)
    def self.set(key, value)
        object = {
            "uuid"  => key,
            "value" => value
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, CATALYST_IPHETRA_SYSTEM_DATA_SETUUID, object)
    end

    # NSXSystemDataOperator::getOrNull(key)
    def self.getOrNull(key)
        object = Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, CATALYST_IPHETRA_SYSTEM_DATA_SETUUID, key)
        return nil if object.nil?
        object["value"]
    end

    # NSXSystemDataOperator::getOrDefaultValue(key, defaultValue)
    def self.getOrDefaultValue(key, defaultValue)
        value = NSXSystemDataOperator::getOrNull(key)
        return value if value
        defaultValue
    end

    # NSXSystemDataOperator::destroy(key)
    def self.destroy(key)
        Iphetra::destroyObject(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, CATALYST_IPHETRA_SYSTEM_DATA_SETUUID, key)
    end

end

