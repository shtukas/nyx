
# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'find'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
KeyValueStore::set(repositorylocation or nil, key, value)
KeyValueStore::getOrNull(repositorylocation or nil, key)
KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

class NSXStreamsUtilsPrivate

    # ----------------------------------------------------------------
    # Utils

    # NSXStreamsUtilsPrivate::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSXStreamsUtilsPrivate::newItemFilenameToFilepath(filename)
    def self.newItemFilenameToFilepath(filename)
        frg1 = filename[0,4]
        frg2 = filename[0,6]
        frg3 = filename[0,8]
        folder1 = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Streams/#{frg1}/#{frg2}/#{frg3}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        filepath = "#{folder2}/#{filename}"
        filepath
    end

    # -----------------------------------------------------------------
    # IO

    # NSXStreamsUtilsPrivate::resolveFilenameToFilepathOrNullUseTheForce(filename)
    def self.resolveFilenameToFilepathOrNullUseTheForce(filename)
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Streams") do |path|
            next if !File.file?(path)
            next if File.basename(path) != filename
            return path
        end
        nil
    end

    # NSXStreamsUtilsPrivate::resolveFilenameToFilepathOrNull(filename)
    def self.resolveFilenameToFilepathOrNull(filename)
        filepath = KeyValueStore::getOrNull(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}")
        if filepath then
            if File.exists?(filepath) then
                return filepath
            end
        end
        filepath = NSXStreamsUtilsPrivate::resolveFilenameToFilepathOrNullUseTheForce(filename)
        if filepath then
            KeyValueStore::set(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}", filepath)
        end
        filepath
    end

    # NSXStreamsUtilsPrivate::sendItemToDisk(item)
    def self.sendItemToDisk(item)
        filepath = NSXStreamsUtilsPrivate::resolveFilenameToFilepathOrNull(item["filename"])
        if filepath.nil? then
            filepath = NSXStreamsUtilsPrivate::newItemFilenameToFilepath(item["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NSXStreamsUtilsPrivate::allStreamsItemsEnumerator()
    def self.allStreamsItemsEnumerator()
        Enumerator.new do |items|
            Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Streams") do |path|
                next if !File.file?(path)
                next if File.basename(path)[-16, 16] != ".StreamItem.json"
                item = JSON.parse(IO.read(path))
                item["filepath"] = path
                items << item
            end
        end
    end

    # NSXStreamsUtilsPrivate::getStreamItemByUUIDOrNull(streamItemUUID)
    def self.getStreamItemByUUIDOrNull(streamItemUUID)
        NSXStreamsUtilsPrivate::allStreamsItemsEnumerator()
        .select{|item| item["uuid"] == streamItemUUID }
        .first
    end

    # NSXStreamsUtilsPrivate::getStreamItemsOrdered(streamUUID)
    def self.getStreamItemsOrdered(streamUUID)
        NSXStreamsUtilsPrivate::allStreamsItemsEnumerator()
            .select{|item| item["streamuuid"]==streamUUID }
            .sort{|i1,i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # -----------------------------------------------------------------
    # Issuers

    # NSXStreamsUtilsPrivate::makeItem(streamUUID, genericContentFilename, ordinal)
    def self.makeItem(streamUUID, genericContentFilename, ordinal)
        item = {}
        item["uuid"]                     = SecureRandom.hex
        item["streamuuid"]               = streamUUID
        item["filename"]                 = "#{NSXStreamsUtilsPrivate::timeStringL22()}.StreamItem.json"
        item["generic-content-filename"] = genericContentFilename        
        item["ordinal"]                  = ordinal
        item
    end

    # NSXStreamsUtilsPrivate::issueItem(streamUUID, genericContentFilename, ordinal)
    def self.issueItem(streamUUID, genericContentFilename, ordinal)
        item = NSXStreamsUtilsPrivate::makeItem(streamUUID, genericContentFilename, ordinal)
        NSXStreamsUtilsPrivate::sendItemToDisk(item)
        item
    end

    # NSXStreamsUtilsPrivate::issueItemAtNextOrdinal(streamUUID, genericContentFilename)
    def self.issueItemAtNextOrdinal(streamUUID, genericContentFilename)
        ordinal = NSXStreamsUtilsPrivate::getNextOrdinalForStream(streamUUID)
        NSXStreamsUtilsPrivate::issueItem(streamUUID, genericContentFilename, ordinal)
    end

    # NSXStreamsUtilsPrivate::issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
    def self.issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
        genericContentFilename = genericItem["filename"]
        NSXStreamsUtilsPrivate::issueItemAtNextOrdinal(streamUUID, genericContentFilename)
    end

    # NSXStreamsUtilsPrivate::issueItemAtOrdinalUsingGenericContentsItem(streamUUID, genericItem, ordinal)
    def self.issueItemAtOrdinalUsingGenericContentsItem(streamUUID, genericItem, ordinal)
        genericContentFilename = genericItem["filename"]
        NSXStreamsUtilsPrivate::issueItem(streamUUID, genericContentFilename, ordinal)
    end

    # -----------------------------------------------------------------
    # Data Processing

    # NSXStreamsUtilsPrivate::getNextOrdinalForStream(streamUUID)
    def self.getNextOrdinalForStream(streamUUID)
        items = NSXStreamsUtilsPrivate::getStreamItemsOrdered(streamUUID)
        return 1 if items.size==0
        items.map{|item| item["ordinal"] }.max + 1
    end

    # NSXStreamsUtilsPrivate::streamItemsWithoutLightThreadOwner()
    def self.streamItemsWithoutLightThreadOwner()
        managed_streamuuids = NSXLightThreadUtils::lightThreads().map{|lt| lt["streamuuid"] }
        NSXStreamsUtilsPrivate::allStreamsItemsEnumerator().reject{|streamItem| managed_streamuuids.include?(streamItem["streamuuid"]) }
    end

    # NSXStreamsUtilsPrivate::recastStreamItem(streamItemUUID)
    def self.recastStreamItem(streamItemUUID)
        item = NSXStreamsUtilsPrivate::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        pair = NSXStreamsUtilsPublic::interactivelySelectStreamUUIDAndOrdinalPairOrNull()
        return if pair.nil?
        streamuuid, ordinal = pair
        item["streamuuid"] = streamuuid
        item["ordinal"] = ordinal
        NSXStreamsUtilsPrivate::sendItemToDisk(item)
    end

    # NSXStreamsUtilsPrivate::newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
    def self.newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
        items = NSXStreamsUtilsPrivate::getStreamItemsOrdered(streamUUID)
        # First we remove the item from the stream
        items = items.reject{|item| item["uuid"]==streamItemUUID }
        if items.size == 0 then
        return 1 # There was only one item (or zero) in the stream and we default to 1
        end 
        if items.size < n then
        return items.last["ordinal"] + 1
        end
        return ( items[n-2]["ordinal"] + items[n-1]["ordinal"] ).to_f/2 # Average of the (n-1)^th item and the n^th item ordinals
    end

    # NSXStreamsUtilsPrivate::resetRunDataAndRotateItem(streamUUID, n, streamItemUUID)
    def self.resetRunDataAndRotateItem(streamUUID, n, streamItemUUID)
        item1 = NSXStreamsUtilsPrivate::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item1.nil?
        item2 = item1.clone
        item2["run-data"] = []
        item2["ordinal"] = NSXStreamsUtilsPrivate::newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
        NSXStreamsUtilsPrivate::sendItemToDisk(item2)
        [item1, item2]
    end

    # NSXStreamsUtilsPrivate::sendOrphanStreamItemsToInbox()
    def self.sendOrphanStreamItemsToInbox()
        NSXStreamsUtilsPrivate::streamItemsWithoutLightThreadOwner()
        .each{|item|
            catalystInboxStreamUUID = "03b79978bcf7a712953c5543a9df9047" # Catalyst Inbox
            item["streamuuid"] = catalystInboxStreamUUID
            item["ordinal"] = NSXStreamsUtilsPrivate::getNextOrdinalForStream(catalystInboxStreamUUID)
            NSXStreamsUtilsPrivate::sendItemToDisk(item)
        }
    end

    # -----------------------------------------------------------------
    # Catalyst Objects and Commands

    # NSXStreamsUtilsPrivate::streamItemToStreamCatalystObjectAnnounce(nil or lightThread, item)
    def self.streamItemToStreamCatalystObjectAnnounce(lightThread, item)
        announce = item["description"] ? item["description"] : NSXGenericContents::filenameToCatalystObjectAnnounce(item["generic-content-filename"]).strip
        objectuuid = item["uuid"][0,8]
        datetime = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(objectuuid)
        doNotShowString = 
            if datetime then
                " (DoNotShowUntil: #{datetime})"
            else
                ""
            end
        runtimestring = ""
        if NSXRunner::isRunning?(item["uuid"]) then
            runtimestring = " (running for #{(NSXRunner::runningTimeOrNull(item["uuid"]).to_f/3600).round(2)} hours)"
        end
        "LightThread: #{(lightThread ? lightThread["description"] : "")} ; StreamItem (#{item["ordinal"]}) ; #{announce}#{doNotShowString}#{runtimestring}"
    end

    # NSXStreamsUtilsPrivate::streamItemToStreamCatalystObjectMetric(lightThreadMetricForStreamItems, item)
    def self.streamItemToStreamCatalystObjectMetric(lightThreadMetricForStreamItems, item)
        return (2 + NSXMiscUtils::traceToMetricShift(item["uuid"]) ) if NSXRunner::isRunning?(item["uuid"])
        claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(item["uuid"])
        return 0 if (claim and claim["status"] == "deleted-on-server")
        return 0 if (claim and claim["status"] == "deleted-on-local")
        return 0 if (claim and claim["status"] == "dead")
        lightThreadMetricForStreamItems + Math.exp(-item["ordinal"].to_f/1000).to_f/1000000
    end

    # NSXStreamsUtilsPrivate::streamItemToStreamCatalystObjectCommands(lightThread, item)
    def self.streamItemToStreamCatalystObjectCommands(lightThread, item)
        if NSXRunner::isRunning?(item["uuid"]) then
            ["open", "stop", "done", "recast", "description:", "ordinal:"]
        else
            ["open" ,"start", "done", "time:", "push", "recast", "description:", "ordinal:"]
        end
    end

    # NSXStreamsUtilsPrivate::streamItemToStreamCatalystDefaultCommand(lightThread, item)
    def self.streamItemToStreamCatalystDefaultCommand(lightThread, item)
        NSXRunner::isRunning?(item["uuid"]) ? "stop" : "start ; open"
    end

    # NSXStreamsUtilsPrivate::streamItemToStreamCatalystObject(lightThread, lightThreadMetricForStreamItems, item)
    def self.streamItemToStreamCatalystObject(lightThread, lightThreadMetricForStreamItems, item)
        genericContentsItemOrNull = lambda{|genericContentFilename|
            filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(genericContentFilename)
            return nil if filepath.nil?
            JSON.parse(IO.read(filepath)) 
        }
        object = {}
        object["uuid"] = item["uuid"][0,8]      
        object["agentuid"] = "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"  
        object["metric"] = NSXStreamsUtilsPrivate::streamItemToStreamCatalystObjectMetric(lightThreadMetricForStreamItems, item)
        object["announce"] = NSXStreamsUtilsPrivate::streamItemToStreamCatalystObjectAnnounce(lightThread, item)
        object["commands"] = NSXStreamsUtilsPrivate::streamItemToStreamCatalystObjectCommands(lightThread, item)
        object["defaultExpression"] = NSXStreamsUtilsPrivate::streamItemToStreamCatalystDefaultCommand(lightThread, item)
        object["isRunning"] = NSXRunner::isRunning?(item["uuid"])
        object["data"] = {}
        object["data"]["stream-item"] = item
        object["data"]["generic-contents-item"] = genericContentsItemOrNull.call(item["generic-content-filename"]) 
        object["data"]["light-thread"] = lightThread
        object
    end

    # NSXStreamsUtilsPrivate::viewItem(filename)
    def self.viewItem(filename)
        filepath = NSXStreamsUtilsPrivate::resolveFilenameToFilepathOrNull(filename)
        if filepath.nil? then
            puts "Error fbc5372e: unknown file" 
            LucilleCore::pressEnterToContinue()
            return
        end
        streamItem = JSON.parse(IO.read(filepath))
        NSXGenericContents::viewItem(streamItem["generic-content-filename"])
    end

    # NSXStreamsUtilsPrivate::destroyItem(filename)
    def self.destroyItem(filename)
        filepath = NSXStreamsUtilsPrivate::resolveFilenameToFilepathOrNull(filename)
        if filepath.nil? then
            puts "Error 316492ca: unknown file (#{filename})" 
            LucilleCore::pressEnterToContinue()
        end
        item = JSON.parse(IO.read(filepath))
        NSXGenericContents::destroyItem(item["generic-content-filename"])
        NSXMiscUtils::moveLocationToCatalystBin(filepath)
    end

    # NSXStreamsUtilsPrivate::stopStreamItem(streamItemUUID): # timespan
    def self.stopStreamItem(streamItemUUID) # timespan
        item = NSXStreamsUtilsPrivate::getStreamItemByUUIDOrNull(streamItemUUID)
        return 0 if item.nil?
        return 0 if !NSXRunner::isRunning?(streamItemUUID)
        timespan = NSXRunner::stop(streamItemUUID)
        streamItemRunTimeData = [ Time.new.to_i, timespan ]
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        item["run-data"] << streamItemRunTimeData
        NSXStreamsUtilsPrivate::sendItemToDisk(item)
        timespan
    end

    # NSXStreamsUtilsPrivate::stopPostProcessing(streamItemUUID)
    def self.stopPostProcessing(streamItemUUID)
        item = NSXStreamsUtilsPrivate::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        if item["run-data"].map{|x| x[1] }.inject(0, :+) >= 3600 then
            output = NSXStreamsUtilsPrivate::resetRunDataAndRotateItem(item["streamuuid"], 3, streamItemUUID)
            puts JSON.pretty_generate(output)
        end
    end

    # NSXStreamsUtilsPrivate::setItemDescription(streamItemUUID, description)
    def self.setItemDescription(streamItemUUID, description)
        item = NSXStreamsUtilsPrivate::getStreamItemByUUIDOrNull(streamItemUUID)
        item["description"] = description
        NSXStreamsUtilsPrivate::sendItemToDisk(item)
    end

    # NSXStreamsUtilsPrivate::setItemOrdinal(streamItemUUID, ordinal)
    def self.setItemOrdinal(streamItemUUID, ordinal)
        item = NSXStreamsUtilsPrivate::getStreamItemByUUIDOrNull(streamItemUUID)
        item["ordinal"] = ordinal
        NSXStreamsUtilsPrivate::sendItemToDisk(item)
    end

    # -----------------------------------------------------------------
    # User Interface

    # NSXStreamsUtilsPrivate::interactivelySelectOrdinalUsing10ElementsDisplayOrNull(streamuuid)
    def self.interactivelySelectOrdinalUsing10ElementsDisplayOrNull(streamuuid)
        puts "steam items:"
        NSXStreamsUtilsPrivate::allStreamsItemsEnumerator()
            .select{|item| item["streamuuid"]==streamuuid }
            .sort{|i1, i2| i1["ordinal"]<=>i2["ordinal"] }
            .first(10)
            .each{|streamItem|
                puts NSXStreamsUtilsPrivate::streamItemToStreamCatalystObjectAnnounce(nil, streamItem).lines.first
            }
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (leave empty for end of queue): ")
        return nil if ordinal == ""
        ordinal.to_f
    end

    # NSXStreamsUtilsPrivate::interactivelySelectStreamUUIDAndOrdinalPairOrNull(): [streamuuid, ordinal]
    def self.interactivelySelectStreamUUIDAndOrdinalPairOrNull()
        lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
        return if lightThread.nil?
        streamuuid = lightThread["streamuuid"]
        ordinal = NSXMiscUtils::nonNullValueOrDefaultValue(
            NSXStreamsUtilsPrivate::interactivelySelectOrdinalUsing10ElementsDisplayOrNull(streamuuid), 
            NSXStreamsUtilsPrivate::getNextOrdinalForStream(streamuuid))
        [streamuuid, ordinal]
    end
end

# -------------------------------------------------------------------
# Internal data

$STREAM_ITEMS_MAP = {} 

NSXStreamsUtilsPrivate::allStreamsItemsEnumerator()
.each{|item|
    $STREAM_ITEMS_MAP[item["uuid"]] = item
}

# -------------------------------------------------------------------
# Public Interface

class NSXStreamsUtilsPublic
    # NSXStreamsUtilsPublic::allStreamsItemsEnumerator()
    def self.allStreamsItemsEnumerator()
        NSXStreamsUtilsPrivate::allStreamsItemsEnumerator()
    end

    # NSXStreamsUtilsPublic::issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
    def self.issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
        NSXStreamsUtilsPrivate::issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
    end

    # NSXStreamsUtilsPublic::getNextOrdinalForStream(streamUUID)
    def self.getNextOrdinalForStream(streamUUID)
        NSXStreamsUtilsPrivate::getNextOrdinalForStream(streamUUID)
    end

    # NSXStreamsUtilsPublic::recastStreamItem(streamItemUUID)
    def self.recastStreamItem(streamItemUUID)
        NSXStreamsUtilsPrivate::recastStreamItem(streamItemUUID)
    end

    # NSXStreamsUtilsPublic::resetRunDataAndRotateItem(streamUUID, n, streamItemUUID)
    def self.resetRunDataAndRotateItem(streamUUID, n, streamItemUUID)
        NSXStreamsUtilsPrivate::resetRunDataAndRotateItem(streamUUID, n, streamItemUUID)
    end

    # NSXStreamsUtilsPublic::sendOrphanStreamItemsToInbox()
    def self.sendOrphanStreamItemsToInbox()
        NSXStreamsUtilsPrivate::sendOrphanStreamItemsToInbox()
    end

    # NSXStreamsUtilsPublic::streamItemToStreamCatalystObject(lightThread, lightThreadMetricForStreamItems, item)
    def self.streamItemToStreamCatalystObject(lightThread, lightThreadMetricForStreamItems, item)
        NSXStreamsUtilsPrivate::streamItemToStreamCatalystObject(lightThread, lightThreadMetricForStreamItems, item)
    end

    # NSXStreamsUtilsPublic::viewItem(filename)
    def self.viewItem(filename)
        NSXStreamsUtilsPrivate::viewItem(filename)
    end

    # NSXStreamsUtilsPublic::destroyItem(filename)
    def self.destroyItem(filename)
        NSXStreamsUtilsPrivate::destroyItem(filename)
    end

    # NSXStreamsUtilsPublic::stopStreamItem(streamItemUUID): # timespan
    def self.stopStreamItem(streamItemUUID) # timespan
        NSXStreamsUtilsPrivate::stopStreamItem(streamItemUUID)
    end

    # NSXStreamsUtilsPublic::stopPostProcessing(streamItemUUID)
    def self.stopPostProcessing(streamItemUUID)
        NSXStreamsUtilsPrivate::stopPostProcessing(streamItemUUID)
    end

    # NSXStreamsUtilsPublic::setItemDescription(streamItemUUID, description)
    def self.setItemDescription(streamItemUUID, description)
        NSXStreamsUtilsPrivate::setItemDescription(streamItemUUID, description)
    end

    # NSXStreamsUtilsPublic::setItemOrdinal(streamItemUUID, ordinal)
    def self.setItemOrdinal(streamItemUUID, ordinal)
        NSXStreamsUtilsPrivate::setItemOrdinal(streamItemUUID, ordinal)
    end

    # NSXStreamsUtilsPublic::interactivelySelectStreamUUIDAndOrdinalPairOrNull(): [streamuuid, ordinal]
    def self.interactivelySelectStreamUUIDAndOrdinalPairOrNull()
        NSXStreamsUtilsPrivate::interactivelySelectStreamUUIDAndOrdinalPairOrNull()
    end
end
