
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

class NSXStreamsUtils

    # ----------------------------------------------------------------
    # Utils

    # NSXStreamsUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSXStreamsUtils::newItemFilenameToFilepath(filename)
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

    # NSXStreamsUtils::resolveFilenameToFilepathOrNullUseTheForce(filename)
    def self.resolveFilenameToFilepathOrNullUseTheForce(filename)
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Streams") do |path|
            next if !File.file?(path)
            next if File.basename(path) != filename
            return path
        end
        nil
    end

    # NSXStreamsUtils::resolveFilenameToFilepathOrNull(filename)
    def self.resolveFilenameToFilepathOrNull(filename)
        filepath = KeyValueStore::getOrNull(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}")
        if filepath then
            if File.exists?(filepath) then
                return filepath
            end
        end
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNullUseTheForce(filename)
        if filepath then
            KeyValueStore::set(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}", filepath)
        end
        filepath
    end

    # NSXStreamsUtils::sendItemToDisk(item)
    def self.sendItemToDisk(item)
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNull(item["filename"])
        if filepath.nil? then
            filepath = NSXStreamsUtils::newItemFilenameToFilepath(item["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NSXStreamsUtils::allStreamsItemsEnumerator()
    def self.allStreamsItemsEnumerator()
        Enumerator.new do |items|
            Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Streams") do |path|
                next if !File.file?(path)
                next if File.basename(path)[-16, 16] != ".StreamItem.json"
                item = JSON.parse(IO.read(path))
                item["filepath-real"] = path
                items << item
            end
        end
    end

    # NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
    def self.getStreamItemByUUIDOrNull(streamItemUUID)
        NSXStreamsUtils::allStreamsItemsEnumerator()
        .select{|item|
            item["uuid"] == streamItemUUID
        }
        .first
    end

    # NSXStreamsUtils::getStreamItemsOrdered(streamUUID)
    def self.getStreamItemsOrdered(streamUUID)
        NSXStreamsUtils::allStreamsItemsEnumerator()
            .select{|item| item["streamuuid"]==streamUUID }
            .sort{|i1,i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # -----------------------------------------------------------------
    # Issuers

    # NSXStreamsUtils::makeItem(streamUUID, genericContentFilename, ordinal)
    def self.makeItem(streamUUID, genericContentFilename, ordinal)
        item = {}
        item["uuid"]                     = SecureRandom.hex
        item["streamuuid"]               = streamUUID
        item["filename"]                 = "#{NSXStreamsUtils::timeStringL22()}.StreamItem.json"
        item["generic-content-filename"] = genericContentFilename        
        item["ordinal"]                  = ordinal
        item
    end

    # NSXStreamsUtils::issueItem(streamUUID, genericContentFilename, ordinal)
    def self.issueItem(streamUUID, genericContentFilename, ordinal)
        item = NSXStreamsUtils::makeItem(streamUUID, genericContentFilename, ordinal)
        NSXStreamsUtils::sendItemToDisk(item)
        item
    end

    # NSXStreamsUtils::issueItemAtNextOrdinal(streamUUID, genericContentFilename)
    def self.issueItemAtNextOrdinal(streamUUID, genericContentFilename)
        ordinal = NSXStreamsUtils::getNextOrdinalForStream(streamUUID)
        NSXStreamsUtils::issueItem(streamUUID, genericContentFilename, ordinal)
    end

    # NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
    def self.issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
        genericContentFilename = genericItem["filename"]
        NSXStreamsUtils::issueItemAtNextOrdinal(streamUUID, genericContentFilename)
    end

    # NSXStreamsUtils::issueItemAtOrdinalUsingGenericContentsItem(streamUUID, genericItem, ordinal)
    def self.issueItemAtOrdinalUsingGenericContentsItem(streamUUID, genericItem, ordinal)
        genericContentFilename = genericItem["filename"]
        NSXStreamsUtils::issueItem(streamUUID, genericContentFilename, ordinal)
    end

    # -----------------------------------------------------------------
    # Data Processing

    # NSXStreamsUtils::getNextOrdinalForStream(streamUUID)
    def self.getNextOrdinalForStream(streamUUID)
        items = NSXStreamsUtils::getStreamItemsOrdered(streamUUID)
        return 1 if items.size==0
        items.map{|item| item["ordinal"] }.max + 1
    end

    # NSXStreamsUtils::getFrontOfTheLineOrdinalForStream(streamUUID)
    def self.getFrontOfTheLineOrdinalForStream(streamUUID)
        items = NSXStreamsUtils::getStreamItemsOrdered(streamUUID)
        return 1 if items.size==0
        items.map{|item| item["ordinal"] }.min - 1
    end

    # NSXStreamsUtils::streamItemsWithoutLightThreadOwner()
    def self.streamItemsWithoutLightThreadOwner()
        managed_streamuuids = NSXLightThreadUtils::lightThreads().map{|lt| lt["streamuuid"] }
        NSXStreamsUtils::allStreamsItemsEnumerator().reject{|streamItem| managed_streamuuids.include?(streamItem["streamuuid"]) }
    end

    # NSXStreamsUtils::recastStreamItem(streamItemUUID)
    def self.recastStreamItem(streamItemUUID)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        pair = NSXStreamsUtils::interactivelySelectStreamUUIDAndOrdinalPairOrNull()
        return if pair.nil?
        streamuuid, ordinal = pair
        item["streamuuid"] = streamuuid
        item["ordinal"] = ordinal
        NSXStreamsUtils::sendItemToDisk(item)
    end

    # NSXStreamsUtils::newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
    def self.newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
        items = NSXStreamsUtils::getStreamItemsOrdered(streamUUID)
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

    # NSXStreamsUtils::resetRunDataAndRotateItem(streamUUID, n, streamItemUUID)
    def self.resetRunDataAndRotateItem(streamUUID, n, streamItemUUID)
        item1 = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item1.nil?
        item2 = item1.clone
        item2["run-data"] = []
        item2["ordinal"] = NSXStreamsUtils::newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
        NSXStreamsUtils::sendItemToDisk(item2)
        [item1, item2]
    end

    # NSXStreamsUtils::shiftItemsOrdinalDownIfRequired(items)
    def self.shiftItemsOrdinalDownIfRequired(items)
        return if items.size == 0
        if ( shift = items.first["ordinal"] ) < 0 then
            items.each{|item|
                item["ordinal"] = item["ordinal"] - shift
                NSXStreamsUtils::sendItemToDisk(item)
            }
        end
        if items.first["ordinal"] > 100 then
            items.each{|item|
            item["ordinal"] = item["ordinal"] - 100
            NSXStreamsUtils::sendItemToDisk(item)
            }
        end
    end

    # NSXStreamsUtils::sendOrphanStreamItemsToInbox()
    def self.sendOrphanStreamItemsToInbox()
        NSXStreamsUtils::streamItemsWithoutLightThreadOwner()
        .each{|item|
            catalystInboxStreamUUID = "03b79978bcf7a712953c5543a9df9047" # Catalyst Inbox
            item["streamuuid"] = catalystInboxStreamUUID
            item["ordinal"] = NSXStreamsUtils::getNextOrdinalForStream(catalystInboxStreamUUID)
            NSXStreamsUtils::sendItemToDisk(item)
        }
    end

    # -----------------------------------------------------------------
    # Cardinal Managament

    # NSXStreamsUtils::cardinal()
    def self.cardinal()
        NSXStreamsUtils::allStreamsItemsEnumerator().to_a.size
    end

    # NSXStreamsUtils::recordCardinalForToday()
    def self.recordCardinalForToday()
        KeyValueStore::set("/Galaxy/DataBank/Catalyst/Streams-KVStoreRepository", "c1b957f8-a8d0-4611-8a9b-bb08a9f4ce75:#{NSXMiscUtils::currentDay()}", NSXStreamsUtils::cardinal())
    end

    # NSXStreamsUtils::getCardinalForDateOrNull(date)
    def self.getCardinalForDateOrNull(date)
        value = KeyValueStore::getOrNull("/Galaxy/DataBank/Catalyst/Streams-KVStoreRepository", "c1b957f8-a8d0-4611-8a9b-bb08a9f4ce75:#{date}")
        return nil if value.nil?
        value.to_i
    end

    # NSXStreamsUtils::getLowestOfTwoReferenceValuesOrNull()
    def self.getLowestOfTwoReferenceValuesOrNull()
        maybeValue1 = NSXStreamsUtils::getCardinalForDateOrNull(NSXMiscUtils::nDaysAgo(7))
        maybeValue2 = NSXStreamsUtils::getCardinalForDateOrNull(NSXMiscUtils::nDaysAgo(1))
        return nil if (maybeValue1.nil? and maybeValue2.nil?)
        [maybeValue1, maybeValue2].compact.min
    end

    # NSXStreamsUtils::getDifferentialOrNull()
    def self.getDifferentialOrNull()
        NSXStreamsUtils::recordCardinalForToday()
        refvalue = NSXStreamsUtils::getLowestOfTwoReferenceValuesOrNull()
        return nil if refvalue.nil?
        NSXStreamsUtils::getCardinalForDateOrNull(NSXMiscUtils::currentDay()) - refvalue
    end

    # -----------------------------------------------------------------
    # Catalyst Objects and Commands

    # NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(nil or lightThread, item)
    def self.streamItemToStreamCatalystObjectAnnounce(lightThread, item)
        announce = item["description"] ? item["description"] : NSXGenericContents::filenameToCatalystObjectAnnounce(item["generic-content-filename"])
        objectuuid = item["uuid"][0,8]
        datetime = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(objectuuid)
        doNotShowString = 
            if datetime then
                " (DoNotShowUntil: #{datetime})"
            else
                ""
            end
        "LightThread: #{(lightThread ? lightThread["description"] : "")} ; StreamItem (#{item["ordinal"]}) ; #{announce}#{doNotShowString}"
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectMetric(lightThreadMetricForStreamItems, item)
    def self.streamItemToStreamCatalystObjectMetric(lightThreadMetricForStreamItems, item)
        return (2 + NSXMiscUtils::traceToMetricShift(item["uuid"]) ) if NSXRunner::isRunning?(item["uuid"])
        lightThreadMetricForStreamItems + Math.exp(-item["ordinal"].to_f/1000).to_f/1000000
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(lightThread, item)
    def self.streamItemToStreamCatalystObjectCommands(lightThread, item)
        if NSXRunner::isRunning?(item["uuid"]) then
            ["open", "stop", "done", "recast", "description:", "ordinal:"]
        else
            ["open" ,"start", "done", "time:", "push", "recast", "description:", "ordinal:"]
        end
    end

    # NSXStreamsUtils::streamItemToStreamCatalystDefaultCommand(lightThread, item)
    def self.streamItemToStreamCatalystDefaultCommand(lightThread, item)
        NSXRunner::isRunning?(item["uuid"]) ? "stop" : "start ; open"
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObject(lightThread, lightThreadMetricForStreamItems, item)
    def self.streamItemToStreamCatalystObject(lightThread, lightThreadMetricForStreamItems, item)
        genericContentsItemOrNull = lambda{|genericContentFilename|
            filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(genericContentFilename)
            return nil if filepath.nil?
            JSON.parse(IO.read(filepath)) 
        }
        object = {}
        object["uuid"] = item["uuid"][0,8]      
        object["agentuid"] = "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"  
        object["metric"] = NSXStreamsUtils::streamItemToStreamCatalystObjectMetric(lightThreadMetricForStreamItems, item)
        object["announce"] = NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(lightThread, item)
        object["commands"] = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(lightThread, item)
        object["defaultExpression"] = NSXStreamsUtils::streamItemToStreamCatalystDefaultCommand(lightThread, item)
        object["isRunning"] = NSXRunner::isRunning?(item["uuid"])
        object["data"] = {}
        object["data"]["stream-item"] = item
        object["data"]["generic-contents-item"] = genericContentsItemOrNull.call(item["generic-content-filename"]) 
        object["data"]["light-thread"] = lightThread
        object
    end

    # NSXStreamsUtils::viewItem(filename)
    def self.viewItem(filename)
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNull(filename)
        if filepath.nil? then
            puts "Error fbc5372e: unknown file" 
            LucilleCore::pressEnterToContinue()
            return
        end
        streamItem = JSON.parse(IO.read(filepath))
        NSXGenericContents::viewItem(streamItem["generic-content-filename"])
    end

    # NSXStreamsUtils::destroyItem(filename)
    def self.destroyItem(filename)
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNull(filename)
        if filepath.nil? then
            puts "Error 316492ca: unknown file (#{filename})" 
            LucilleCore::pressEnterToContinue()
            return
        end
        item = JSON.parse(IO.read(filepath))
        NSXGenericContents::destroyItem(item["generic-content-filename"])
        NSXMiscUtils::moveLocationToCatalystBin(filepath)
    end

    # NSXStreamsUtils::stopStreamItem(streamItemUUID): # timespan
    def self.stopStreamItem(streamItemUUID) # timespan
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return 0 if item.nil?
        return 0 if !NSXRunner::isRunning?(streamItemUUID)
        timespan = NSXRunner::stop(streamItemUUID)
        streamItemRunTimeData = [ Time.new.to_i, timespan ]
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        item["run-data"] << streamItemRunTimeData
        NSXStreamsUtils::sendItemToDisk(item)
        timespan
    end

    # NSXStreamsUtils::stopPostProcessing(streamItemUUID)
    def self.stopPostProcessing(streamItemUUID)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        if item["run-data"].map{|x| x[1] }.inject(0, :+) >= 3600 then
            output = NSXStreamsUtils::resetRunDataAndRotateItem(item["streamuuid"], 3, streamItemUUID)
            puts JSON.pretty_generate(output)
        end
    end

    # NSXStreamsUtils::setItemDescription(streamItemUUID, description)
    def self.setItemDescription(streamItemUUID, description)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        item["description"] = description
        NSXStreamsUtils::sendItemToDisk(item)
    end

    # NSXStreamsUtils::setItemOrdinal(streamItemUUID, ordinal)
    def self.setItemOrdinal(streamItemUUID, ordinal)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        item["ordinal"] = ordinal
        NSXStreamsUtils::sendItemToDisk(item)
    end

    # -----------------------------------------------------------------
    # User Interface

    # NSXStreamsUtils::interactivelySelectOrdinalUsing10ElementsDisplayOrNull(streamuuid)
    def self.interactivelySelectOrdinalUsing10ElementsDisplayOrNull(streamuuid)
        puts "steam items:"
        NSXStreamsUtils::allStreamsItemsEnumerator()
            .select{|item| item["streamuuid"]==streamuuid }
            .sort{|i1, i2| i1["ordinal"]<=>i2["ordinal"] }
            .first(10)
            .each{|streamItem|
                puts NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(nil, streamItem)
            }
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (leave empty for end of queue): ")
        return nil if ordinal == ""
        ordinal.to_f
    end

    # NSXStreamsUtils::interactivelySelectStreamUUIDAndOrdinalPairOrNull(): [streamuuid, ordinal]
    def self.interactivelySelectStreamUUIDAndOrdinalPairOrNull()
        lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
        return if lightThread.nil?
        streamuuid = lightThread["streamuuid"]
        ordinal = NSXMiscUtils::nonNullValueOrDefaultValue(
        NSXStreamsUtils::interactivelySelectOrdinalUsing10ElementsDisplayOrNull(streamuuid), 
        NSXStreamsUtils::getNextOrdinalForStream(streamuuid))
        [streamuuid, ordinal]
    end
end
