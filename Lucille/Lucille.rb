
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)

    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Aether.rb"
=begin
    AetherGenesys::makeNewPoint(filepath)
    AetherKVStore::set(filepath, key, value)
    AetherKVStore::getOrNull(filepath, key)
    AetherKVStore::keys(filepath)
    AetherKVStore::destroy(filepath, key)
    AetherAionOperations::importLocationAgainstReference(filepath, xreference, location)
    AetherAionOperations::exportReferenceAtFolder(filepath, xreference, targetReconstructionFolderpath)
=end

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

class LucilleThisCore

    # LucilleThisCore::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # -----------------------------
    # IO

    # LucilleThisCore::pathToItems()
    def self.pathToItems()
        "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/I2tems"
    end

    # LucilleThisCore::uuid2aetherfilepath(uuid)
    def self.uuid2aetherfilepath(uuid)
        aetherfilename = "#{uuid}.data"
        "#{LucilleThisCore::pathToItems()}/#{aetherfilename}"
    end

    # LucilleThisCore::terminateItem(uuid)
    def self.terminateItem(uuid)
        filepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        CatalystCommon::copyLocationToCatalystBin(filepath)
        FileUtils.rm(filepath)
    end

    # LucilleThisCore::isCurrentUUID(uuid)
    def self.isCurrentUUID(uuid)
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        File.exists?(aetherfilepath)
    end

    # -----------------------------
    # Makers

    # LucilleThisCore::newItemPayloadAionpoint(description, timeline, location)
    def self.newItemPayloadAionpoint(description, timeline, location)
        uuid = LucilleThisCore::timeStringL22()
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherGenesys::makeNewPoint(aetherfilepath)
        AetherKVStore::set(aetherfilepath, "uuid", uuid)
        AetherKVStore::set(aetherfilepath, "description", description)
        AetherKVStore::set(aetherfilepath, "timeline", timeline)
        AetherKVStore::set(aetherfilepath, "payloadType", "aionpoint")
        AetherAionOperations::importLocationAgainstReference(aetherfilepath, "1815ea639314", location)
    end

    # LucilleThisCore::newItemPayloadText(description, timeline, text)
    def self.newItemPayloadText(description, timeline, text)
        uuid = LucilleThisCore::timeStringL22()
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherGenesys::makeNewPoint(aetherfilepath)
        AetherKVStore::set(aetherfilepath, "uuid", uuid)
        AetherKVStore::set(aetherfilepath, "description", description)
        AetherKVStore::set(aetherfilepath, "timeline", timeline)
        AetherKVStore::set(aetherfilepath, "payloadType", "text")
        AetherKVStore::set(aetherfilepath, "472ec67c0dd6", text)
    end

    # LucilleThisCore::newItemPayloadUrl(description, timeline, url)
    def self.newItemPayloadUrl(description, timeline, url)
        uuid = LucilleThisCore::timeStringL22()
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherGenesys::makeNewPoint(aetherfilepath)
        AetherKVStore::set(aetherfilepath, "uuid", uuid)
        AetherKVStore::set(aetherfilepath, "description", description)
        AetherKVStore::set(aetherfilepath, "timeline", timeline)
        AetherKVStore::set(aetherfilepath, "payloadType", "url")
        AetherKVStore::set(aetherfilepath, "67c2db721728", url)
    end

    # -----------------------------
    # Data

    # LucilleThisCore::uuids()
    def self.uuids()
        Dir.entries(LucilleThisCore::pathToItems())
            .select{|filename| filename[-5, 5] == ".data" }
            .map{|filename| filename[0, 22] }
            .sort
    end

    # LucilleThisCore::setDescription(uuid, description)
    def self.setDescription(uuid, description)
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "description", description)
    end

    # LucilleThisCore::getDescription(uuid)
    def self.getDescription(uuid)
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "description")
    end

    # LucilleThisCore::setItemTimeline(uuid, timeline)
    def self.setItemTimeline(uuid, timeline)
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "timeline", timeline)
    end

    # LucilleThisCore::getItemTimeline(uuid)
    def self.getItemTimeline(uuid)
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "timeline")
    end

    # LucilleThisCore::timelines()
    def self.timelines()
        LucilleThisCore::uuids()
            .map{|uuid| LucilleThisCore::getItemTimeline(uuid) }
            .uniq
            .sort
    end

    # LucilleThisCore::getTimelineUUIDs(timeline)
    def self.getTimelineUUIDs(timeline)
        LucilleThisCore::uuids()
            .select{|uuid| LucilleThisCore::getItemTimeline(uuid) == timeline }
    end

    # LucilleThisCore::setPayloadType(uuid, payloadType)
    def self.setPayloadType(uuid, payloadType)
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "payloadType", payloadType)
    end

    # LucilleThisCore::getPayloadType(uuid)
    def self.getPayloadType(uuid)
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "payloadType")
    end

    # -----------------------------
    # Operations

    # LucilleThisCore::selectTimelineOrNull()
    def self.selectTimelineOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("timeline", LucilleThisCore::timelines())
    end

    # LucilleThisCore::exportContentAtDesktop(uuid)
    def self.exportContentAtDesktop(uuid)
        targetfolderpath = "/Users/pascal/Desktop/#{uuid}"
        return if File.exists?(targetfolderpath)
        FileUtils.mkdir(targetfolderpath)
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherAionOperations::exportReferenceAtFolder(aetherfilepath, "1815ea639314", targetfolderpath)
    end

    # LucilleThisCore::recastAsIFCSItem(uuid)
    def self.recastAsIFCSItem(uuid)
        # IFCS expect
        #    uuid        :
        #    description :
        #    payloadType :
        #    position    : Float
        # Lucille has
        #    uuid
        #    description
        #    payloadType
        #    timeline
        ifcsreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-items-report`
        puts ifcsreport
        position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
        aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "position", position)
        ifcsfilepath = "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/Items/#{File.basename(aetherfilepath)}"
        FileUtils.mv(aetherfilepath, ifcsfilepath)
    end

    # LucilleThisCore::recastAsNyxItem(uuid)
    def self.recastAsNyxItem(uuid)
        puts "Not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # LucilleThisCore::selectUUIDOrNull()
    def self.selectUUIDOrNull()
        timeline = LucilleThisCore::selectTimelineOrNull()
        return nil if timeline.nil?
        uuids = LucilleThisCore::getTimelineUUIDs(timeline)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item:", uuids, lambda {|uuid| LucilleThisCore::getDescription(uuid) })
    end

end

class LXCluster

    # LXCluster::selectUUIDsForCluster()
    def self.selectUUIDsForCluster()
        LucilleThisCore::timelines()
            .reject{|timeline| timeline=="Inbox"}
            .map{|timeline|
                LucilleThisCore::getTimelineUUIDs(timeline).sort.first(10)
            }
            .flatten
    end

    # LXCluster::commitClusterToDisk(cluster)
    def self.commitClusterToDisk(cluster)
        filename = "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/cluster.json"
        File.open(filename, "w") {|f| f.puts(JSON.pretty_generate(cluster)) }
    end

    # LXCluster::getClusterFromDisk()
    def self.getClusterFromDisk()
        JSON.parse(IO.read("#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/cluster.json"))
    end

    # LXCluster::issueNewCluster()
    def self.issueNewCluster()
        uuids = LXCluster::selectUUIDsForCluster()
        cluster = {
            "creationunixtime" => Time.new.to_i,
            "initialsize" => uuids.size,
            "uuids" => uuids
        }
        LXCluster::commitClusterToDisk(cluster)
        cluster
    end

    # LXCluster::getWorkingCluster()
    def self.getWorkingCluster()
        cluster = LXCluster::getClusterFromDisk()
        cluster["uuids"] = cluster["uuids"].select{|uuid| File.exists?(LucilleThisCore::uuid2aetherfilepath(uuid)) }
        if cluster["uuids"].size < 0.5*cluster["initialsize"] then
            cluster = LXCluster::issueNewCluster()
        end
        cluster
    end
end

class LXUserInterface

    # LXUserInterface::openItemReadOnly(uuid)
    def self.openItemReadOnly(uuid)
        payloadType = LucilleThisCore::getPayloadType(uuid)
        if payloadType == "aionpoint" then
            LucilleThisCore::exportContentAtDesktop(uuid)
        end
        if payloadType == "text" then
            aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
            text = AetherKVStore::getOrNull(aetherfilepath, "472ec67c0dd6")
            tmpfilepath = "/tmp/#{uuid}.txt"
            File.open(tmpfilepath, "w") {|f| f.puts(text) }
            system("open '#{tmpfilepath}'")
        end
        if payloadType == "url" then
            aetherfilepath = LucilleThisCore::uuid2aetherfilepath(uuid)
            url = AetherKVStore::getOrNull(aetherfilepath, "67c2db721728")
            system("open '#{url}'")
        end
    end

    # LXUserInterface::doneItem(uuid)
    def self.doneItem(uuid)
        LucilleThisCore::terminateItem(uuid)
    end

    # LXUserInterface::recastItem(uuid)
    def self.recastItem(uuid)
        timeline = nil
        loop {
            timelines = LucilleThisCore::timelines().reject{|timeline| timeline == "Inbox" }
            t = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeline", timelines)
            if t then
                timeline = t
                break
            end
            t = LucilleCore::askQuestionAnswerAsString("timeline: ")
            if t.size>0 then
                timeline = t
                break
            end
        }
        LucilleThisCore::setItemTimeline(uuid, timeline)
    end

    # LXUserInterface::itemDive(uuid)
    def self.itemDive(uuid)
        loop {
            system("clear")
            puts "uuid: #{uuid}"
            puts "description: #{LucilleThisCore::getDescription(uuid)}"
            options = [
                "open",
                "done",
                "set description",
                "recast",
                ">nyx"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                LucilleThisCore::exportContentAtDesktop(uuid)
            end
            if option == "done" then
                LXUserInterface::doneItem(uuid)
                return
            end
            if option == "set description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                LucilleThisCore::setDescription(uuid, description)
            end
            if option == "recast" then
                LXUserInterface::recastItem(uuid)
            end
            if option == ">ifcs" then
                LucilleThisCore::recastAsIFCSItem(uuid)
                return
            end
            if option == ">nyx" then
                LucilleThisCore::recastAsNyxItem(uuid)
                return
            end
        }
    end

    # LXUserInterface::timelineDive(timeline)
    def self.timelineDive(timeline)
        puts "-> #{timeline}"
        loop {
            locations = LucilleThisCore::getTimelineUUIDs(timeline)
            location = LucilleCore::selectEntityFromListOfEntitiesOrNull("locations:", locations, lambda {|location| LucilleThisCore::getDescription(location) })
            break if location.nil?
            LXUserInterface::itemDive(location)
        }
    end

end
