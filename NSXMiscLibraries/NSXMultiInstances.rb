
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

MULTIINSTANCE_ROOT_PATH = "/Galaxy/DataBank/Catalyst/Multi-Instance"

class NSXMultiInstancesWrite

    # NSXMultiInstancesWrite::makeEvent(instanceName, eventType, payload)
    def self.makeEvent(instanceName, eventType, payload)
        {
            "instanceName" => instanceName,
            "eventType"    => eventType,
            "payload"      => payload
        }
    end

    # NSXMultiInstancesWrite::sendEventToDisk(instanceName, event)
    def self.sendEventToDisk(instanceName, event)
        filename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.json"
        filepath = "#{MULTIINSTANCE_ROOT_PATH}/Log/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end

    # NSXMultiInstancesWrite::issueEventCommand(objectuuid, agentuuid, command)
    def self.issueEventCommand(objectuuid, agentuuid, command)
        payload = {
            "objectuuid" => objectuuid,
            "agentuuid"  => agentuuid,
            "command"    => command
        }
        event = NSXMultiInstancesWrite::makeEvent(NSXMiscUtils::instanceName(), "command", payload)
        NSXMultiInstancesWrite::sendEventToDisk(NSXMiscUtils::instanceName(), event)
    end

end

class NSXMultiInstancesRead

    # NSXMultiInstancesRead::eventsFilepaths()
    def self.eventsFilepaths()
        instanceMessagesRepositoryPath = "#{MULTIINSTANCE_ROOT_PATH}/Log"
        filenames = Dir.entries(instanceMessagesRepositoryPath).select{|filename| filename[-5, 5] == ".json" }.sort
        filenames
            .map{|filename| "#{instanceMessagesRepositoryPath}/#{filename}" }
    end

    # NSXMultiInstancesRead::processEvent(event, filepath)
    def self.processEvent(event, filepath)
        if event["eventType"] == "command" then
            payload    = event["payload"]
            objectuuid = payload["objectuuid"]
            agentuid   = payload["agentuid"]
            command    = payload ["command"]
            object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(objectuuid)
            return if object.nil?
            agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(agentuid)
            return if agentdata.nil?
            agentdata["object-command-processor"].call(object, fragment, false)
            return
        end
        puts "Doesn't know how to process this event"
        puts JSON.pretty_generate(event)
        exit
    end

    # NSXMultiInstancesRead::processEvents()
    def self.processEvents()
        NSXMultiInstancesRead::eventsFilepaths()
        .each{|filepath|
            event = JSON.parse(IO.read(filepath))
            next if event["instanceName"] == NSXMiscUtils::instanceName()
            puts filepath
            NSXMultiInstancesRead::processEvent(event, filepath)
            FileUtils.rm(filepath)
        }
    end

end
