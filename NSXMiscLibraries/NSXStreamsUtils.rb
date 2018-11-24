
# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

# ----------------------------------------------------------------------

class NSXStreamsUtils

    # NSXStreamsUtils::StreamNames()
    def self.StreamNames()
        ["Right-Now", "Today-Important", "XStream"]
    end

    # NSXStreamsUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSXStreamsUtils::newItemFilenameToFilepath(filename)
    def self.newItemFilenameToFilepath(filename)
        frg1 = filename[0,4]
        frg2 = filename[0,6]
        frg3 = filename[0,8]
        folder1 = "/Galaxy/DataBank/Catalyst/Streams/#{frg1}/#{frg2}/#{frg3}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        filepath = "#{folder2}/#{filename}"
        filepath
    end

    # NSXStreamsUtils::resolveFilenameToFilepathOrNull(filename)
    def self.resolveFilenameToFilepathOrNull(filename)
        Find.find("/Galaxy/DataBank/Catalyst/Streams") do |path|
            next if !File.file?(path)
            next if File.basename(path) != filename
            return path
        end
        nil
    end

    # NSXStreamsUtils::makeItem(streamName, genericContentFilename, ordinal)
    def self.makeItem(streamName, genericContentFilename, ordinal)
        item = {}
        item["uuid"]                     = SecureRandom.hex
        item["streamName"]               = streamName
        item["filename"]                 = "#{NSXStreamsUtils::timeStringL22()}.StreamItem.json"
        item["generic-content-filename"] = genericContentFilename        
        item["ordinal"]                  = ordinal 
        item["ignore-until-datetime"]    = nil 
        item
    end

    # NSXStreamsUtils::issueItem(streamName, genericContentFilename, ordinal)
    def self.issueItem(streamName, genericContentFilename, ordinal)
        item = NSXStreamsUtils::makeItem(streamName, genericContentFilename, ordinal)
        NSXStreamsUtils::sendItemToDisk(item)
        item
    end

    # NSXStreamsUtils::issueItemAtNextOrdinal(streamName, genericContentFilename)
    def self.issueItemAtNextOrdinal(streamName, genericContentFilename)
        ordinal = NSXStreamsUtils::getNextOrdinalForStream(streamName)
        NSXStreamsUtils::issueItem(streamName, genericContentFilename, ordinal)
    end

    # NSXStreamsUtils::issueUsingGenericItem(streamName, genericItem)
    def self.issueUsingGenericItem(streamName, genericItem)
        genericContentFilename = genericItem["filename"]
        NSXStreamsUtils::issueItemAtNextOrdinal(streamName, genericContentFilename)
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
            Find.find("/Galaxy/DataBank/Catalyst/Streams") do |path|
                next if !File.file?(path)
                next if !File.basename(path).include?('.StreamItem.json')
                items << JSON.parse(IO.read(path))
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

    # NSXStreamsUtils::getStreamItemsOrdered(streamName)
    def self.getStreamItemsOrdered(streamName)
        NSXStreamsUtils::allStreamsItemsEnumerator()
            .select{|item| item["streamName"]==streamName }
            .sort{|i1,i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # NSXStreamsUtils::getNextOrdinalForStream(streamName)
    def self.getNextOrdinalForStream(streamName)
        items = NSXStreamsUtils::getStreamItemsOrdered(streamName)
        return 1 if items.size==0
        items.map{|item| item["ordinal"] }.max + 1
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(streamName, item)
    def self.streamItemToStreamCatalystObjectAnnounce(streamName, item)
        genericContentFilename = item["generic-content-filename"]
        genericContentsAnnounce = NSXGenericContents::filenameToCatalystObjectAnnounce(genericContentFilename)
        "[Stream: #{streamName}] #{genericContentsAnnounce}"
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectMetric(streamName, item)
    def self.streamItemToStreamCatalystObjectMetric(streamName, item)
        streamNameToMetricMap = {
            "Right-Now"       => 0.85 + Math.exp(-item["ordinal"].to_f/1000).to_f/10,
            "Today-Important" => 0.55 + Math.exp(-item["ordinal"].to_f/1000).to_f/10,
            "XStream"         => 0.35 + Math.exp(-item["ordinal"].to_f/1000).to_f/10
        }
        streamNameToMetricMap[streamName]
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
    def self.streamItemToStreamCatalystObjectCommands(item)
        isRunning = !item["run-status"].nil?
        if isRunning then
            ["open", "stop", "done"]
        else
            ["start"]
        end
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObject(streamName, item)
    def self.streamItemToStreamCatalystObject(streamName, item)
        isRunning = !item["run-status"].nil?
        object = {}
        object["uuid"] = item["uuid"][0,8]      
        object["agent-uid"] = "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"  
        object["metric"] = NSXStreamsUtils::streamItemToStreamCatalystObjectMetric(streamName, item)
        object["announce"] = NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(streamName, item)
        object["commands"] = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
        object["default-expression"] = nil
        object["is-running"] = isRunning
        object["data"] = {}
        object["data"]["stream-item"] = item
        object["data"]["generic-contents-item"] = JSON.parse(IO.read(NSXGenericContents::resolveFilenameToFilepathOrNull(item["generic-content-filename"]))) 
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
            puts "Error 316492ca: unknown file" 
            LucilleCore::pressEnterToContinue()
            return
        end
        FileUtils.rm(filepath)
    end

    # NSXStreamsUtils::pickUpXStreamDropOff()
    def self.pickUpXStreamDropOff()
        Dir.entries("/Users/pascal/Desktop/XStream-DropOff")
        .select{|filename| filename[0,1]!="." }
        .map{|filename| "/Users/pascal/Desktop/XStream-DropOff/#{filename}" }
        .map{|location|
            genericItem = NSXGenericContents::issueItemLocationMoveOriginal(location)
            NSXStreamsUtils::issueUsingGenericItem("XStream", genericItem)
        }
    end

    # NSXStreamsUtils::startStreamItem(streamItemUUID)
    def self.startStreamItem(streamItemUUID)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        return if item["run-status"] # already running
        item["run-status"] = Time.new.to_i
        NSXStreamsUtils::sendItemToDisk(item)
    end

    # NSXStreamsUtils::stopStreamItem(streamItemUUID)
    def self.stopStreamItem(streamItemUUID)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        return if !item["run-status"] # not running
        timespan = Time.new.to_i - item["run-status"]
        streamItemRunTimeData = [ Time.new.to_i, timespan ]
        item["run-status"] = nil
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        item["run-data"] << streamItemRunTimeData
        NSXStreamsUtils::sendItemToDisk(item)
        NSXStreamsUtils::stopPostProcessing(streamItemUUID)
    end

    # NSXStreamsUtils::stopPostProcessing(streamItemUUID)
    def self.stopPostProcessing(streamItemUUID)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        return if item["streamName"]!="XStream"
        totalProcessingTimeInSeconds = item["run-data"].map{|x| x[1] }.inject(0, :+)
        if totalProcessingTimeInSeconds >= 3600 then
            # Here we update the oridinal or the object to be the new object in position 5
            item["ordinal"] = NSXStreamsUtils::newPosition5OrdinalForXStreamItem(streamItemUUID)
            NSXStreamsUtils::sendItemToDisk(item)
        end
    end

    # NSXStreamsUtils::newPosition5OrdinalForXStreamItem(streamItemUUID)
    def self.newPosition5OrdinalForXStreamItem(streamItemUUID)
        items = NSXStreamsUtils::getStreamItemsOrdered(streamName)
        # first we remove the item from the stream
        items = items.reject{|item| item["uuid"]==streamItemUUID }
        if item.size == 0 then
            return 1 # There was only one item (or zero) in the stream and we default to 1
        end 
        if items.size <= 4 then
            return items.last["ordinal"] + 1
        end
        return ( items[3]["ordinal"] + items[4]["ordinal"] ).to_f/2 # Average of the 4th item and the 5th item ordinals
    end

end

