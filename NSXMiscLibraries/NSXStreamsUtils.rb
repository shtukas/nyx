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

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds, simulationWeight = 0)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

# ----------------------------------------------------------------------

$STREAM_ITEMS_IN_MEMORY_4B4BFE22 = nil

def nsx1309_removeItemIdentifiedById(uuid)
    $STREAM_ITEMS_IN_MEMORY_4B4BFE22 = $STREAM_ITEMS_IN_MEMORY_4B4BFE22.reject{|item| item["uuid"]==uuid }
end


class NSXStreamsUtils

    # ----------------------------------------------------------------
    # Utils

    # NSXStreamsUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSXStreamsUtils::newItemFilepathForFilename(filename)
    def self.newItemFilepathForFilename(filename)
        folder1 = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Streams/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        filepath = "#{folder2}/#{filename}"
        KeyValueStore::set(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}", filepath)
        filepath
    end

    # -----------------------------------------------------------------
    # Streams Metadata

    # NSXStreamsUtils::streamsMetadata()
    def self.streamsMetadata()
        [
            {
                "streamuuid"         => "03b79978bcf7a712953c5543a9df9047",
                "description"        => "Catalyst Inbox",
                "naturalMetric"      => 0.70, # Stable metric
                "hoursExpectation"   => 1, # This has no effect due to special processing of this Stream
            },
            {
                "streamuuid"         => "134de9a4e9eae4841fdbc4c1e53f4455",
                "description"        => "Pascal Technology Jedi",
                "naturalMetric"      => 0.50,
                "hoursExpectation"   => 2,
            },
            {
                "streamuuid"         => "38d5658ed46c4daf0ec064e58fb2b97a",
                "description"        => "Personal Entertainment",
                "naturalMetric"      => 0.40,
                "hoursExpectation"   => 1,
            },
            {
                "streamuuid"         => "00010011101100010011101100011001",
                "description"        => "Infinity Stream",
                "naturalMetric"      => 0.30,
                "hoursExpectation"   => 1,
            }
        ]
    end

    # NSXStreamsUtils::streamUUIDs()
    def self.streamUUIDs()
        NSXStreamsUtils::streamsMetadata().map{|item| item["streamuuid"] }
    end

    # NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(description)
    def self.streamDescriptionToStreamUUIDOrNull(description)
        NSXStreamsUtils::streamsMetadata()
            .select{|item| item["description"]==description }
            .each{|item|
                return item["streamuuid"]
            }
        nil
    end

    # NSXStreamsUtils::streamuuidToStreamDescriptionOrNull(streamuuid)
    def self.streamuuidToStreamDescriptionOrNull(streamuuid)
        NSXStreamsUtils::streamsMetadata()
            .select{|item| item["streamuuid"]==streamuuid }
            .each{|item|
                return item["description"]
            }
        nil
    end

    # NSXStreamsUtils::streamuuidToStreamNaturalMetricDefault1(streamuuid)
    def self.streamuuidToStreamNaturalMetricDefault1(streamuuid)
        NSXStreamsUtils::streamsMetadata()
            .select{|item| item["streamuuid"]==streamuuid }
            .each{|item|
                return item["naturalMetric"]
            }
        1
    end

    # NSXStreamsUtils::streamuuidToStreamHoursExpectationDefault1(streamuuid)
    def self.streamuuidToStreamHoursExpectationDefault1(streamuuid)
        NSXStreamsUtils::streamsMetadata()
            .select{|item| item["streamuuid"]==streamuuid }
            .each{|item|
                return item["hoursExpectation"]
            }
        1
    end

    # -----------------------------------------------------------------
    # IO

    # NSXStreamsUtils::filenameToFilepathResolutionOrNullUseTheForce(filename)
    def self.filenameToFilepathResolutionOrNullUseTheForce(filename)
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Streams") do |path|
            next if !File.file?(path)
            next if File.basename(path) != filename
            return path
        end
        nil
    end

    # NSXStreamsUtils::filenameToFilepathResolutionOrNull(filename)
    def self.filenameToFilepathResolutionOrNull(filename)
        filepath = KeyValueStore::getOrNull(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}")
        if filepath and File.basename(filepath)==filename and File.exists?(filepath) then
            return filepath
        end
        filepath = NSXStreamsUtils::filenameToFilepathResolutionOrNullUseTheForce(filename)
        if filepath then
            KeyValueStore::set(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}", filepath)
        end
        filepath
    end

    # NSXStreamsUtils::uuidToFilepathResolutionOrNull(uuid)
    def self.uuidToFilepathResolutionOrNull(uuid)
        filepath = KeyValueStore::getOrNull(nil, "437c8725-e862-4031-b6ba-1eddf33c3746:#{uuid}")
        if filepath then
            if File.exists?(filepath) then
                item = JSON.parse(IO.read(filepath))
                if item["uuid"] == uuid then
                    return filepath
                end
            end
        end
        filepath = nil
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Streams") do |path|
            next if !File.file?(path)
            next if File.basename(path)[-16, 16] != ".StreamItem.json"
            item = JSON.parse(IO.read(path))
            if item["uuid"] == uuid then
                filepath = path
            end
        end
        if filepath then
            KeyValueStore::set(nil, "437c8725-e862-4031-b6ba-1eddf33c3746:#{uuid}", filepath)
        end
        filepath
    end

    # NSXStreamsUtils::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filepath = NSXStreamsUtils::uuidToFilepathResolutionOrNull(uuid)
        return nil if filepath.nil?
        JSON.parse(IO.read(filepath))
    end

    # NSXStreamsUtils::destroyItem(item)
    def self.destroyItem(item)
        filename = item['filename']
        filepath = NSXStreamsUtils::filenameToFilepathResolutionOrNull(filename)
        if filepath.nil? then
            puts "Error 316492ca: unknown file (#{filename})"
        else
            NSXMiscUtils::moveLocationToCatalystBin(filepath)
        end
        NSXGenericContents::destroyItem(item["generic-content-item"])
    end

    # NSXStreamsUtils::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filepath = NSXStreamsUtils::filenameToFilepathResolutionOrNull(item["filename"])
        if filepath.nil? then
            filepath = NSXStreamsUtils::newItemFilepathForFilename(item["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # -----------------------------------------------------------------
    # Core Data

    # NSXStreamsUtils::getItems()
    def self.getItems()
        items = []
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Streams") do |path|
            next if !File.file?(path)
            next if File.basename(path)[-16, 16] != ".StreamItem.json"
            item = JSON.parse(IO.read(path))
            item["filename"] = File.basename(path)
            item["filepath"] = path
            items << item
        end
        items
    end

    # NSXStreamsUtils::getSelectionOfItems()
    def self.getSelectionOfItems()
        NSXStreamsUtils::getItems()
            .sort{|i1, i2| i1["ordinal"]<=>i2["ordinal"] }
            .reduce([]) { |collection, item|
                if 
                    NSXRunner::isRunning?(item["uuid"]) or
                    (item["streamuuid"] == "03b79978bcf7a712953c5543a9df9047") or 
                    (collection.select{|o| o["streamuuid"]==item["streamuuid"] }.size < 5) 
                then
                    collection + [item]
                else
                    collection
                end
            }
    end

    # NSXStreamsUtils::getStreamItemsOrdinalOrdered(streamUUID)
    def self.getStreamItemsOrdinalOrdered(streamUUID)
        NSXStreamsUtils::getItems()
            .select{|item| item["streamuuid"]==streamUUID }
            .sort{|i1,i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # NSXStreamsUtils::itemsForStreamUUIDOrdered(streamuuid)
    def self.itemsForStreamUUIDOrdered(streamuuid)
        NSXStreamsUtils::getItems()
            .select{|item| item["streamuuid"]==streamuuid }
            .sort{|i1, i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # NSXStreamsUtils::issueNewStreamItem(streamUUID, genericContentItem, ordinal)
    def self.issueNewStreamItem(streamUUID, genericContentItem, ordinal)
        item = {}
        item["uuid"]                     = SecureRandom.hex
        item["streamuuid"]               = streamUUID
        item["ordinal"]                  = ordinal
        item['generic-content-item']     = genericContentItem
        item["filename"]                 = "#{NSXStreamsUtils::timeStringL22()}.StreamItem.json"
        NSXStreamsUtils::commitItemToDisk(item)
        item
    end

    # NSXStreamsUtils::itemToCatalystObject(item)
    def self.itemToCatalystObject(item)
        announce = NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
        contentStoreItem = {
            "type" => "line",
            "line" => announce
        }
        NSXContentStore::setItem(item["uuid"], contentStoreItem)
        object = {}
        object["uuid"] = item["uuid"]
        object["agentuid"] = "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
        object["metric"] = NSXStreamsUtils::streamItemToStreamCatalystMetric(item)
        object["announce"] = announce
        object["contentStoreItemId"] = item["uuid"]
        object["body"] = NSXStreamsUtils::streamItemToStreamCatalystObjectBody(item)
        object["commands"] = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
        object["defaultCommand"] = NSXStreamsUtils::streamItemToStreamCatalystDefaultCommand(item, announce)
        object["isRunning"] = NSXRunner::isRunning?(item["uuid"])
        object
    end

    # NSXStreamsUtils::getCatalystObjectsForDisplay()
    def self.getCatalystObjectsForDisplay()
        if $STREAM_ITEMS_IN_MEMORY_4B4BFE22.nil? or $STREAM_ITEMS_IN_MEMORY_4B4BFE22.empty? then
            $STREAM_ITEMS_IN_MEMORY_4B4BFE22 = NSXStreamsUtils::getSelectionOfItems()
        end
        $STREAM_ITEMS_IN_MEMORY_4B4BFE22.map{|item| NSXStreamsUtils::itemToCatalystObject(item) }
    end

    # NSXStreamsUtils::getAllCatalystObjects()
    def self.getAllCatalystObjects()
        NSXStreamsUtils::getItems()
            .map{|item| NSXStreamsUtils::itemToCatalystObject(item) }
    end

    # -----------------------------------------------------------------
    # Stream Utils

    # NSXStreamsUtils::recastStreamItem(item): item
    def self.recastStreamItem(item)
        description = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
        streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(description)
        item["streamuuid"] = streamuuid
        item["ordinal"] = NSXStreamsUtils::interactivelySpecifyStreamItemOrdinal(streamuuid)
        item
    end

    # NSXStreamsUtils::newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
    def self.newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
        items = NSXStreamsUtils::getStreamItemsOrdinalOrdered(streamUUID)
        # First we remove the item from the stream
        items = items.reject{|item| item["uuid"]==streamItemUUID }
        if items.size == 0 then
            return NSXMiscUtils::makeEndOfQueueStreamItemOrdinal()
        end 
        if items.size < n then
            return NSXMiscUtils::makeEndOfQueueStreamItemOrdinal()
        end
        return ( items[n-2]["ordinal"] + items[n-1]["ordinal"] ).to_f/2 # Average of the (n-1)^th item and the n^th item ordinals
    end

    # NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
    def self.interactivelySelectStreamDescriptionOrNull()
        descriptions = NSXStreamsUtils::streamsMetadata().map{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("description:", descriptions)
    end

    # NSXStreamsUtils::interactivelySpecifyStreamItemOrdinal(streamuuid)
    def self.interactivelySpecifyStreamItemOrdinal(streamuuid)
        # We get the first 20 items, display them, ask for either a number or null for the next ordinal at the end of the queue
        items = NSXStreamsUtils::getStreamItemsOrdinalOrdered(streamuuid)
        return 1 if items.size==0
        puts "-> start"
        items
            .first(10)
            .each{|item|
                puts "#{item["ordinal"]} #{NSXGenericContents::genericContentsItemToCatalystObjectAnnounce(item["generic-content-item"])}"
            }
        puts "-> end"
        items
            .last(5)
            .each{|item|
                puts "#{item["ordinal"]} #{NSXGenericContents::genericContentsItemToCatalystObjectAnnounce(item["generic-content-item"])}"
            }
        answer = LucilleCore::askQuestionAnswerAsString("ordinal: ")
        if answer.size==0 then
            items.map{|item| item["ordinal"] }.max.to_i + 1
        else
            answer.to_f
        end
    end

    # -----------------------------------------------------------------
    # Catalyst Objects and Commands

    # NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
    def self.streamItemToStreamCatalystObjectAnnounce(item)
        [
            "[#{NSXStreamsUtils::streamuuidToStreamDescriptionOrNull(item["streamuuid"])}]",
            " ",
            NSXGenericContents::genericContentsItemToCatalystObjectAnnounce(item["generic-content-item"])
        ].join()
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectBody(item)
    def self.streamItemToStreamCatalystObjectBody(item)
        announce = NSXGenericContents::genericContentsItemToCatalystObjectBody(item["generic-content-item"]).strip
        splitChar = announce.lines.size>1 ? "\n" : " "
        datetime = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(item["uuid"])
        doNotShowString =
            if datetime then
                "#{splitChar}(DoNotShowUntil: #{datetime})"
            else
                ""
            end
        runtimestring =
            if NSXRunner::isRunning?(item["uuid"]) then
                "#{splitChar}(running for #{(NSXRunner::runningTimeOrNull(item["uuid"]).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[#{NSXStreamsUtils::streamuuidToStreamDescriptionOrNull(item['streamuuid'])}]#{splitChar}#{announce}#{doNotShowString}#{runtimestring}"
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
    def self.streamItemToStreamCatalystObjectCommands(item)
        if NSXRunner::isRunning?(item["uuid"]) then
            ["open", "stop", "done", "recast", "folder"]
        else
            ["open" ,"start", "done", "push", "recast", "folder"]
        end
    end

    # NSXStreamsUtils::streamItemToStreamCatalystDefaultCommand(item, announce)
    def self.streamItemToStreamCatalystDefaultCommand(item, announce)
        if NSXRunner::isRunning?(item["uuid"]) then
            nil
        else
            if announce.start_with?('[Catalyst Inbox] http') then
                "start ; open"
            else
                "start"
            end
        end
    end

    # NSXStreamsUtils::streamItemToStreamCatalystMetric(item)
    def self.streamItemToStreamCatalystMetric(item)
        return (2 + NSXMiscUtils::traceToMetricShift(item["uuid"])) if NSXRunner::isRunning?(item["uuid"])
        streamuuid = item["streamuuid"]
        if streamuuid == "03b79978bcf7a712953c5543a9df9047" then
            return NSXStreamsUtils::streamuuidToStreamNaturalMetricDefault1(streamuuid) + Math.exp(-item["ordinal"].to_f/100).to_f/100
        end
        repositorylocation = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Streams-KVStoreRepository"
        collectionuuid = "a12b763e-6e84-4c31-9e5e-470cfbd93a32:#{streamuuid}"
        stabililityPeriodInSeconds = NSXStreamsUtils::streamuuidToStreamHoursExpectationDefault1(streamuuid)
        expectationTimeInSeconds = NSXStreamsUtils::streamuuidToStreamHoursExpectationDefault1(streamuuid)*3600
        metricAtZero = NSXStreamsUtils::streamuuidToStreamNaturalMetricDefault1(streamuuid)
        if NSXStreamsTimeTracking::getTimeInSecondsForStream(streamuuid) < expectationTimeInSeconds then
            NSXStreamsTimeTracking::streamWideMetric(streamuuid, expectationTimeInSeconds, metricAtZero, metricAtZero-0.1) + Math.exp(-item["ordinal"].to_f/100).to_f/100
        else
            0.25 + NSXMiscUtils::traceToMetricShift(item["uuid"])
        end
    end
end

Thread.new {
    loop {
        sleep 300
        $STREAM_ITEMS_IN_MEMORY_4B4BFE22 = NSXStreamsUtils::getSelectionOfItems()
    }
}
