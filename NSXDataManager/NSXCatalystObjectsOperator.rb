
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

DATA_MANAGER_CATALYST_OBJECTS_IPHETRA_SETUUID = "86d2fb58-6fae-4b8a-812c-3f66a768cd7a"

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::putObject(object)
    def self.putObject(object)
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, DATA_MANAGER_CATALYST_OBJECTS_IPHETRA_SETUUID, object) 
    end

    # NSXCatalystObjectsOperator::destroyObject(objectuuid)
    def self.destroyObject(objectuuid)
        Iphetra::destroyObject(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, DATA_MANAGER_CATALYST_OBJECTS_IPHETRA_SETUUID, objectuuid)
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
        Iphetra::getObjects(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, DATA_MANAGER_CATALYST_OBJECTS_IPHETRA_SETUUID)
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

