# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'find'

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
KeyValueStore::set(repositorylocation or nil, key, value)
KeyValueStore::getOrNull(repositorylocation or nil, key)
KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

STREAMUUID_INFINITY_STREAM_STREAMUUID = "00010011101100010011101100011001"

$STREAM_ITEMS_IN_MEMORY_4B4BFE22 = nil

def nsx1309_removeItemIdentifiedById(uuid)
    return if $STREAM_ITEMS_IN_MEMORY_4B4BFE22.nil?
    $STREAM_ITEMS_IN_MEMORY_4B4BFE22 = $STREAM_ITEMS_IN_MEMORY_4B4BFE22.reject{|item| item["uuid"]==uuid }
end

class NSXStreamsUtils

    # -----------------------------------------------------------------
    # IO

    # NSXStreamsUtils::newStreamItemFilepathForFilename(filename)
    def self.newStreamItemFilepathForFilename(filename)
        folder1 = "#{CATALYST_INSTANCE_FOLDERPATH}/Streams-Items/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        filepath = "#{folder2}/#{filename}"
        KeyValueStore::set(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}", filepath)
        filepath
    end

    # NSXStreamsUtils::filenameToFilepathResolutionOrNullUseTheForce(filename)
    def self.filenameToFilepathResolutionOrNullUseTheForce(filename)
        Find.find("#{CATALYST_INSTANCE_FOLDERPATH}/Streams-Items") do |path|
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
        Find.find("#{CATALYST_INSTANCE_FOLDERPATH}/Streams-Items") do |path|
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

    # NSXStreamsUtils::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filepath = NSXStreamsUtils::filenameToFilepathResolutionOrNull(item["filename"])
        if filepath.nil? then
            filepath = NSXStreamsUtils::newStreamItemFilepathForFilename(item["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # -----------------------------------------------------------------
    # Core Data

    # NSXStreamsUtils::issueNewStreamItem(status, genericContent, ordinal)
    def self.issueNewStreamItem(status, genericContent, ordinal)
        item = {}
        item["uuid"]            = SecureRandom.hex
        item["status"]          = status
        item["ordinal"]         = ordinal
        item['generic-content'] = genericContent
        item["filename"]        = "#{NSXMiscUtils::timeStringL22()}.StreamItem.json"
        NSXStreamsUtils::commitItemToDisk(item)
        item
    end

    # NSXStreamsUtils::getStreamItems()
    def self.getStreamItems()
        items = []
        Find.find("#{CATALYST_INSTANCE_FOLDERPATH}/Streams-Items") do |path|
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
            .reduce([]) { |collection, item|
                if ["inbox", "focus"].include?(item["status"]) or (collection.size < 5) then
                    collection + [item]
                else
                    collection
                end
            }
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
        items.map{|item| item["ordinal"] }.max.to_i + 1
    end

    # NSXStreamsUtils::recastStreamItem(item): item
    def self.recastStreamItem(item)
        status = LucilleCore::selectEntityFromListOfEntitiesOrNull("status:", ["focus", "infinity"])
        return if status.nil?
        mapping = {
            "focus"    => "focus",
            "infinity" => nil
        }
        item[status] = mapping[status]
        item
    end

    # -----------------------------------------------------------------
    # Catalyst Objects and Commands

    # NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
    def self.streamItemToStreamCatalystObjectAnnounce(item)
        [
            "[inbox]",
            NSX2GenericContentUtils::genericContentsItemToCatalystObjectAnnounce(item["generic-content"])
        ].join(" ")
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectBody(item)
    def self.streamItemToStreamCatalystObjectBody(item)
        announce = NSX2GenericContentUtils::genericContentsItemToCatalystObjectBody(item["generic-content"]).strip
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
        "[#{announce}#{doNotShowString}#{runtimestring}"
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
    def self.streamItemToStreamCatalystObjectCommands(item)
        ["open", "done", "recast", "folder"]
    end

    # NSXStreamsUtils::streamItemToCatalystObjectMetric(item)
    def self.streamItemToCatalystObjectMetric(item)
        m0 = Math.exp(-item["ordinal"].to_f/100).to_f/100
        return (0.72 + m0) if (item["status"] == "inbox")
        return (0.50 + m0) if (item["status"] == "focus")
        return 0.25
    end

    # NSXStreamsUtils::streamItemToCatalystObject(item)
    def self.streamItemToCatalystObject(item)
        announce = NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(item)
        body = NSXStreamsUtils::streamItemToStreamCatalystObjectBody(item)
        contentItem = {
            "type" => "line-and-body",
            "line" => announce,
            "body" => body
        }
        object = {}
        object["uuid"] = item["uuid"]
        object["agentuid"] = NSXAgentInfinityStream::agentuid()
        object["contentItem"] = contentItem
        object["metric"] = NSXStreamsUtils::streamItemToCatalystObjectMetric(item)
        object["commands"] = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
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

