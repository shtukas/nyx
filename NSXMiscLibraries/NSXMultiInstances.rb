
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

MULTIINSTANCE_LOG_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_CATALYST_SHARED_FOLDERPATH}/Multi-Instance-Log"

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
        filepath = "#{MULTIINSTANCE_LOG_FOLDERPATH}/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end

    # NSXMultiInstancesWrite::issueEventCommand(objectuuid, agentuid, command)
    def self.issueEventCommand(objectuuid, agentuid, command)
        payload = {
            "objectuuid" => objectuuid,
            "agentuid"  => agentuid,
            "command"    => command
        }
        event = NSXMultiInstancesWrite::makeEvent(NSXMiscUtils::instanceName(), "command", payload)
        NSXMultiInstancesWrite::sendEventToDisk(NSXMiscUtils::instanceName(), event)
    end

    # NSXMultiInstancesWrite::issueEventDoNotShowUntil(objectuuid, datetime)
    def self.issueEventDoNotShowUntil(objectuuid, datetime)
        payload = {
            "objectuuid" => objectuuid,
            "datetime"   => datetime
        }
        event = NSXMultiInstancesWrite::makeEvent(NSXMiscUtils::instanceName(), "DoNotShowUntil", payload)
        NSXMultiInstancesWrite::sendEventToDisk(NSXMiscUtils::instanceName(), event)
    end
end

class NSXMultiInstancesRead

    # NSXMultiInstancesRead::eventsFilepaths()
    def self.eventsFilepaths()
        filenames = Dir.entries(MULTIINSTANCE_LOG_FOLDERPATH).select{|filename| filename[-5, 5] == ".json" }.sort
        filenames
            .map{|filename| "#{MULTIINSTANCE_LOG_FOLDERPATH}/#{filename}" }
    end

    # NSXMultiInstancesRead::processEvent(event, filepath)
    def self.processEvent(event, filepath)
        if event["eventType"] == "command" then
            payload    = event["payload"]
            objectuuid = payload["objectuuid"]
            agentuid   = payload["agentuid"]
            command    = payload ["command"]
            agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(agentuid)
            return if agentdata.nil?
            agentdata["object-command-processor"].call(objectuuid, command, false)
            return
        end
        if event["eventType"] == "DoNotShowUntil" then
            payload    = event["payload"]
            objectuuid = payload["objectuuid"]
            datetime   = payload["datetime"]
            NSXDoNotShowUntilDatetime::setDatetime(objectuuid, datetime)
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
            puts "processing: #{filepath}"
            #puts JSON.pretty_generate(event)
            NSXMultiInstancesRead::processEvent(event, filepath)
            FileUtils.rm(filepath)
        }
    end

end
