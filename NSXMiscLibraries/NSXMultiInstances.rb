
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

    # NSXMultiInstancesWrite::makeEvent(instanceName, eventType, objectuuid, command)
    def self.makeEvent(instanceName, eventType, objectuuid, command)
        {
            "instanceName" => instanceName,
            "eventType"    => eventType,
            "objectuuid"   => objectuuid,
            "command"      => command
        }
    end

    # NSXMultiInstancesWrite::sendEventToDisk(event, instanceName)
    def self.sendEventToDisk(event, instanceName)
        filename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.json"
        filepath = "#{MULTIINSTANCE_ROOT_PATH}/Log/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end

    # NSXMultiInstancesWrite::getOtherInstanceName()
    def self.getOtherInstanceName()
        (NSXMiscUtils::instanceName() == "Lucille18") ? "Lucille19" : "Lucille18" 
    end

    # NSXMultiInstancesWrite::issueEventCommand(objectuuid, command)
    def self.issueEventCommand(objectuuid, command)
        event = NSXMultiInstancesWrite::makeEvent(NSXMiscUtils::instanceName(), "command", objectuuid, command)
        NSXMultiInstancesWrite::sendEventToDisk(event, NSXMiscUtils::instanceName())
    end

end

class NSXMultiInstancesRead

    # NSXMultiInstancesRead::instanceEventsFilepaths(instanceName)
    def self.instanceEventsFilepaths(instanceName)
        instanceMessagesRepositoryPath = "#{MULTIINSTANCE_ROOT_PATH}/Log"
        filenames = Dir.entries(instanceMessagesRepositoryPath).select{|filename| filename[-5, 5] == ".json" }.sort
        filenames
            .map{|filename| "#{instanceMessagesRepositoryPath}/#{filename}" }
            .select{|filepath| JSON.parse(IO.read(filepath))["instanceName"]==instanceName }
    end

    # NSXMultiInstancesRead::processMessage(message)
    def self.processMessage(message)
        if message["eventType"] == "command" then
            objectuuid = message["objectuuid"]
            command = message["command"]
            object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(objectuuid)
            return if object.nil?
            # To be implemented
            return true
        end
        puts "Doesn't know how to process this message"
        puts JSON.pretty_generate(message)
        exit
    end

    # NSXMultiInstancesRead::processMessages(instanceName)
    def self.processMessages(instanceName)
        NSXMultiInstancesRead::instanceEventsFilepaths(instanceName)
        .each{|filepath|
            puts filepath
            message = JSON.parse(IO.read(filepath))
            shouldDelete = NSXMultiInstancesRead::processMessage(message)
            if shouldDelete then
                FileUtils.rm(filepath)
            end
        }
    end

    # NSXMultiInstancesRead::processLocalMessages()
    def self.processLocalMessages()
        NSXMultiInstancesRead::processMessages(NSXMiscUtils::instanceName())
    end

end
