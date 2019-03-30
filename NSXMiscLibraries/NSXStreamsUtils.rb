
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

    # NSXStreamsUtils::getStreamItemsOrdinalOrdered(streamUUID)
    def self.getStreamItemsOrdinalOrdered(streamUUID)
        NSXStreamsUtils::allStreamsItemsEnumerator()
            .select{|item| item["streamuuid"]==streamUUID }
            .sort{|i1,i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # -----------------------------------------------------------------
    # Data Processing

    # NSXStreamsUtils::recastStreamItem(item): item
    def self.recastStreamItem(item)
        description = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
        streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(description)
        item["streamuuid"] = streamuuid
        item["ordinal"] = Time.new.to_f
        item
    end

    # NSXStreamsUtils::newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
    def self.newPositionNOrdinalForStreamItem(streamUUID, n, streamItemUUID)
        items = NSXStreamsUtils::getStreamItemsOrdinalOrdered(streamUUID)
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

    # NSXStreamsUtils::streamsMetadata()
    def self.streamsMetadata()
        [
            {
                "streamuuid"       => "03b79978bcf7a712953c5543a9df9047",
                "description"      => "Catalyst Inbox",
                "isPriorityStream" => true
            },
            {
                "streamuuid"       => "38d5658ed46c4daf0ec064e58fb2b97a",
                "description"      => "Personal Admin",
                "isPriorityStream" => false
            },
            {
                "streamuuid"       => "134de9a4e9eae4841fdbc4c1e53f4455",
                "description"      => "Pascal Technology Jedi",
                "isPriorityStream" => false
            },
            {
                "streamuuid"       => "00010011101100010011101100011001",
                "description"      => "Infinity Stream",
                "isPriorityStream" => false
            }
        ]
    end


    # NSXStreamsUtils::streamUUIDs()
    def self.streamUUIDs()
        NSXStreamsUtils::streamsMetadata().map{|item| item["streamuuid"] }
    end

    # NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
    def self.interactivelySelectStreamDescriptionOrNull()
        descriptions = NSXStreamsUtils::streamsMetadata().map{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("description:", descriptions)
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

    # NSXStreamsUtils::streamuuidToPriorityFlagOrNull(streamuuid)
    def self.streamuuidToPriorityFlagOrNull(streamuuid)
        NSXStreamsUtils::streamsMetadata()
            .select{|item| item["streamuuid"]==streamuuid }
            .each{|item|
                return item["isPriorityStream"]
            }
        nil
    end

    # -----------------------------------------------------------------
    # Catalyst Objects and Commands

    # NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
    def self.streamItemToStreamCatalystObjectAnnounce(item)
        announce = NSXGenericContents::genericContentsItemToCatalystObjectAnnounce(item["generic-content-item"]).strip
        datetime = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(item["uuid"])
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
        "#{NSXStreamsUtils::streamuuidToStreamDescriptionOrNull(item['streamuuid'])} : #{announce}#{doNotShowString}#{runtimestring}"
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
    def self.streamItemToStreamCatalystObjectCommands(item)
        if NSXRunner::isRunning?(item["uuid"]) then
            ["open", "stop", "done", "recast"]
        else
            ["open" ,"start", "done", "push", "recast"]
        end
    end

    # NSXStreamsUtils::streamItemToStreamCatalystDefaultCommand(item)
    def self.streamItemToStreamCatalystDefaultCommand(item)
        NSXRunner::isRunning?(item["uuid"]) ? "stop" : "done"
    end
end

class StreamItemsManager
    def initialize()
        @ITEMS = {} # Map[String#streamuuid, Map[String#itemuuid, StreamItem]]
        @DISPLAYITEMS = []
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Streams") do |path|
            next if !File.file?(path)
            next if File.basename(path)[-16, 16] != ".StreamItem.json"
            item = JSON.parse(IO.read(path))
            item["filename"] = File.basename(path)
            item["filepath"] = path
            @ITEMS[item["uuid"]] = item.clone
        end
        cookItemsForDisplay()
    end
    def items()
        @ITEMS.values
    end
    def itemsForStreamUUIDOrdered(streamuuid)
        @ITEMS
            .values
            .select{|item| item["streamuuid"]==streamuuid }
            .sort{|i1, i2| i1["ordinal"]<=>i2["ordinal"] }
    end
    def cookItemsForDisplay()
        streamuuids = @ITEMS.values.map{|item| item["streamuuid"] }.uniq
        @DISPLAYITEMS = 
            streamuuids
                .map{|streamuuid|
                    if NSXStreamsUtils::streamuuidToPriorityFlagOrNull(streamuuid) then
                        self.itemsForStreamUUIDOrdered(streamuuid)
                    else
                        self
                            .itemsForStreamUUIDOrdered(streamuuid)
                            .map{|object| NSXMiscUtils::catalystObjectToObjectOrPrioritizedObjectOrNilIfDoNotShowUntil(object) }
                            .compact
                            .first(3)
                    end
                }
                .flatten
                .map{|item|
                    item["announce"] = NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
                    item["commands"] = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
                    item["defaultExpression"] = NSXStreamsUtils::streamItemToStreamCatalystDefaultCommand(item)
                    item
                }
    end
    def getItemsForDisplay()
        @DISPLAYITEMS
    end
    def issueNewStreamItem(streamUUID, genericContentItem, ordinal)

        item = {}
        item["uuid"]                     = SecureRandom.hex
        item["agentuid"]                 = "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
        item["prioritization"]           = nil

        item["streamuuid"]               = streamUUID
        item["ordinal"]                  = ordinal
        item["filename"]                 = "#{NSXStreamsUtils::timeStringL22()}.StreamItem.json"
        item['generic-content-item']     = genericContentItem
        item["run-data"]                 = []

        # The next one should come after 'generic-content-item' has been set
        item["announce"]                 = NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
        item["commands"]                 = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
        item["defaultExpression"]        = NSXStreamsUtils::streamItemToStreamCatalystDefaultCommand(item)

        commitItem(item)
        item
    end
    def getItemByUUIDOrNull(itemuuid)
        @ITEMS.values.each{|map1| 
            map1.values.each{|item|
                if item["uuid"]==itemuuid then
                    return item
                end
            }
        }
        nil
    end
    def commitItem(item)
        @ITEMS[item["uuid"]] = item.clone
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNull(item["filename"])
        if filepath.nil? then
            filepath = NSXStreamsUtils::newItemFilenameToFilepath(item["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        cookItemsForDisplay()
    end
    def destroyItem(item)
        filename = item['filename']
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNull(filename)
        if filepath.nil? then
            puts "Error 316492ca: unknown file (#{filename})"
        else
            NSXMiscUtils::moveLocationToCatalystBin(filepath)
        end
        NSXGenericContents::destroyItem(item["generic-content-item"])
        @ITEMS.delete(item['uuid'])
        cookItemsForDisplay()
    end
end

$STREAM_ITEMS_MANAGER = StreamItemsManager.new()

