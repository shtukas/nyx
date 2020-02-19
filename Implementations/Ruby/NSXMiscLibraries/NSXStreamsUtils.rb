# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'find'

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
KeyValueStore::set(repositorylocation or nil, key, value)
KeyValueStore::getOrNull(repositorylocation or nil, key)
KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

INFINITY_STREAM_STREAMUUID = "00010011101100010011101100011001"

INFINITY_STREAM_TIMING_COLLECTIONUUID = "584bfe8e-cc59-43b4-8b35-f62001df9aa9"

$STREAM_ITEMS_IN_MEMORY_4B4BFE22 = nil

def nsx1309_removeItemIdentifiedById(uuid)
    return if $STREAM_ITEMS_IN_MEMORY_4B4BFE22.nil?
    $STREAM_ITEMS_IN_MEMORY_4B4BFE22 = $STREAM_ITEMS_IN_MEMORY_4B4BFE22.reject{|item| item["uuid"]==uuid }
end

class NSXStreamsUtils

    # -----------------------------------------------------------------
    # IO & Core Data

    # NSXStreamsUtils::streamItemUUIDToFilepathResolutionOrNull(uuid)
    def self.streamItemUUIDToFilepathResolutionOrNull(uuid)
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
        Find.find("#{CATALYST_DATA_FOLDERPATH}/Streams-Items") do |path|
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

    # NSXStreamsUtils::filenameToFilepathResolutionOrNullUseTheForce(filename)
    def self.filenameToFilepathResolutionOrNullUseTheForce(filename)
        Find.find("#{CATALYST_DATA_FOLDERPATH}/Streams-Items") do |path|
            next if !File.file?(path)
            next if File.basename(path) != filename
            return path
        end
        nil
    end

    # NSXStreamsUtils::filenameToFilepathResolutionOrNull(filename)
    def self.filenameToFilepathResolutionOrNull(filename)
        filepath = KeyValueStore::getOrNull(nil, "56f6f040-c6f9-4825-ba19-499791da5f67:#{filename}")
        if filepath and File.basename(filepath)==filename and File.exists?(filepath) then
            return filepath
        end
        filepath = NSXStreamsUtils::filenameToFilepathResolutionOrNullUseTheForce(filename)
        if filepath then
            KeyValueStore::set(nil, "56f6f040-c6f9-4825-ba19-499791da5f67:#{filename}", filepath)
        end
        filepath
    end

    # NSXStreamsUtils::newStreamItemFilepathForFilename(filename)
    def self.newStreamItemFilepathForFilename(filename)
        folder1 = "#{CATALYST_DATA_FOLDERPATH}/Streams-Items/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        filepath = "#{folder2}/#{filename}"
        KeyValueStore::set(nil, "56f6f040-c6f9-4825-ba19-499791da5f67:#{filename}", filepath)
        filepath
    end

    # NSXStreamsUtils::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filepath = NSXStreamsUtils::filenameToFilepathResolutionOrNull(item["filename"])
        if filepath.nil? then
            filepath = NSXStreamsUtils::newStreamItemFilepathForFilename(item["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NSXStreamsUtils::makeSchedule(type)
    # type: "inbox"
    def self.makeSchedule(type)
        if type == "inbox" then
            return {
                "type" => "inbox"
            }
        end
        raise "error 12dcd14ea92b"
    end

    # NSXStreamsUtils::issueNewStreamItem(schedule, genericContent, ordinal)
    def self.issueNewStreamItem(schedule, genericContent, ordinal)
        item = {}
        item["uuid"]            = SecureRandom.hex
        item["schedule"]        = schedule
        item["ordinal"]         = ordinal
        item['generic-content'] = genericContent
        item["filename"]        = "#{NSXMiscUtils::timeStringL22()}.StreamItem.json"
        NSXStreamsUtils::commitItemToDisk(item)
        item
    end

    # NSXStreamsUtils::getStreamItems()
    def self.getStreamItems()
        items = []
        Find.find("#{CATALYST_DATA_FOLDERPATH}/Streams-Items") do |path|
            next if !File.file?(path)
            next if File.basename(path)[-16, 16] != ".StreamItem.json"
            item = JSON.parse(IO.read(path))
            item["filename"] = File.basename(path)
            item["filepath"] = path
            items << item
        end
        items
    end

    # NSXStreamsUtils::getStreamItemByUUIDOrNull(uuid)
    def self.getStreamItemByUUIDOrNull(uuid)
        filepath = NSXStreamsUtils::streamItemUUIDToFilepathResolutionOrNull(uuid)
        return nil if filepath.nil?
        JSON.parse(IO.read(filepath))
    end

    # NSXStreamsUtils::getStreamItemsOrdinalOrdered()
    def self.getStreamItemsOrdinalOrdered()
        NSXStreamsUtils::getStreamItems()
            .sort{|i1,i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # NSXStreamsUtils::getSelectionOfStreamItems()
    def self.getSelectionOfStreamItems()
        NSXStreamsUtils::getStreamItemsOrdinalOrdered()
        .map{|item|
            {
                "item"   => item,
                "object" => NSXStreamsUtils::streamItemToCatalystObject(item)
            }
        }
        .sort{|p1, p2|
            p1["object"]["metric"] <=> p2["object"]["metric"]
        }
        .reverse
        .first(10)
        .map{|p| p["item"] }

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
        NSX2GenericContentUtils::destroyItem(item["generic-content"])
    end

    # NSXStreamsUtils::getNewStreamOrdinal()
    def self.getNewStreamOrdinal()
        items = NSXStreamsUtils::getStreamItems()
        return 1 if items.size==0
        (items.map{|item| item["ordinal"] }.max.to_i + 1).floor
    end

    # -----------------------------------------------------------------
    # Catalyst Objects and Commands

    # NSXStreamsUtils::scheduleToString(schedule)
    def self.scheduleToString(schedule)
        if schedule["type"] == "inbox" then
            return "[stream / inbox]"
        end
        raise "43a5-97f15"
    end

    # NSXStreamsUtils::streamItemToScheduleString(item)
    def self.streamItemToScheduleString(item)
        return "[stream]" if item["schedule"].nil? 
        NSXStreamsUtils::scheduleToString(item["schedule"])
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
    def self.streamItemToStreamCatalystObjectAnnounce(item)
        [
            NSXStreamsUtils::streamItemToScheduleString(item),
            NSX2GenericContentUtils::genericContentsItemToCatalystObjectAnnounce(item["generic-content"])
        ].join(" ")
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectBody(item)
    def self.streamItemToStreamCatalystObjectBody(item)
        announce = NSX2GenericContentUtils::genericContentsItemToCatalystObjectBody(item["generic-content"]).strip
        splitChar = announce.lines.size>1 ? "\n" : " " 
        datetime = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(item["uuid"])
        doNotShowString = datetime ? "#{splitChar}(DoNotShowUntil: #{datetime})" : "" 
        [
            NSXStreamsUtils::streamItemToScheduleString(item) + " ", 
            announce,
            doNotShowString
        ].join("")
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(objectuuid)
    def self.streamItemToStreamCatalystObjectCommands(objectuuid)
        if NSXRunner::isRunning?(objectuuid) then
            ["open", "stop", "done", "push", "folder"]
        else
            ["open", "start", "done", "push", "folder"]
        end
    end

    # NSXStreamsUtils::streamItemToCatalystObject(item)
    def self.streamItemToCatalystObject(item)
        objectuuid = item["uuid"]
        announce = NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
        body = NSXStreamsUtils::streamItemToStreamCatalystObjectBody(item)
        contentItem = {
            "type" => "line-and-body",
            "line" => announce,
            "body" => body
        }
        generalRuntimePoints = NSXRunTimes::getPoints(INFINITY_STREAM_TIMING_COLLECTIONUUID)
        isRunning = NSXRunner::isRunning?(objectuuid)
        object = {}
        object["uuid"] = objectuuid
        object["agentuid"] = NSXAgentInfinityStream::agentuid()
        object["contentItem"] = contentItem
        object["metric"] =  NSXStreamTodoFoldersCommon::metric1(item["ordinal"], item["schedule"], generalRuntimePoints, isRunning)
        object["commands"] = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(objectuuid)
        object["defaultCommand"] = isRunning ? "stop" : "start"
        object["isRunning"] = isRunning
        object["metadata"] = {}
        object["metadata"]["item"] = item
        object
    end

end

Thread.new {
    loop {
        sleep 300
        $STREAM_ITEMS_IN_MEMORY_4B4BFE22 = NSXStreamsUtils::getSelectionOfStreamItems()
    }
}

