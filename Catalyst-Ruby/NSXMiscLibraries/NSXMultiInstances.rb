
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

MULTIINSTANCE_LOG_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_CATALYST_SHARED_FOLDERPATH}/Activity-Log"

class NSXMultiInstancesWrite
    # NSXMultiInstancesWrite::sendEventToDisk(event)
    def self.sendEventToDisk(event)
        #puts JSON.pretty_generate(event)
        filename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.json"
        filepath = "#{MULTIINSTANCE_LOG_FOLDERPATH}/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end
end

class NSXMultiInstancesRead

    # NSXMultiInstancesRead::processEvent(event, filepath): Boolean
    def self.processEvent(event, filepath)
        if event["eventType"] == "MultiInstanceEventType:CatalystObjectUUID+Command" then
            object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(event["payload"]["objectuuid"])
            return true if object.nil?
            NSXGeneralCommandHandler::processCatalystCommandCore(object, event["payload"]["command"], false)
            return true
        end
        if event["eventType"] == "MultiInstanceEventType:DoNotShowUntil" then
            NSXDoNotShowUntilDatetime::setDatetime(event["payload"]["objectuuid"], event["payload"]["datetime"])
            return true
        end
        if event["eventType"] == "MultiInstanceEventType:RunTimesPoint" then
            NSXRunTimes::addPoint2(event["payload"])
            return true
        end
        if event["eventType"] == "MultiInstanceEventType:MetaDataStoreUpdate" then
            NSXMetaDataStore::setFromMultiInstanceProcessing(event["payload"]["uid"], event["payload"]["key"], event["payload"]["value"])
            return true
        end
        puts "I do not have instructions on how to process this event:"
        puts JSON.pretty_generate(event)
        false
    end

    # NSXMultiInstancesRead::eventsFilepaths()
    def self.eventsFilepaths()
        Dir.entries(MULTIINSTANCE_LOG_FOLDERPATH)
            .select{|filename| filename[-5, 5] == ".json" }
            .sort
            .map{|filename| "#{MULTIINSTANCE_LOG_FOLDERPATH}/#{filename}" }
    end

    # NSXMultiInstancesRead::processEvents()
    def self.processEvents()
        NSXMultiInstancesRead::eventsFilepaths()
        .each{|filepath|
            event = JSON.parse(IO.read(filepath))
            next if event["instanceName"] == NSXMiscUtils::instanceName()
            status = NSXMultiInstancesRead::processEvent(event, filepath)
            FileUtils.rm(filepath) if status
        }
    end

end
