#!/usr/bin/ruby

# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'colorize'
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'time'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'
require 'drb/drb'
require 'thread'

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/YmirEstate.rb"
=begin
    YmirEstate::ymirFilepathEnumerator(pathToYmir)
    YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, basename)
    YmirEstate::makeNewYmirLocationForBasename(pathToYmir, basename)
        # If base name is meant to be the name of a folder then folder itself 
        # still need to be created. Only the parent is created.
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

# --------------------------------------------------------------------

require_relative "BinUtils.rb"

PATH_TO_YMIR = "/Users/pascal/Galaxy/DataBank/todo/Ymir"
TODO_INBOX_TIMELINE_NAME = "[Inbox]"

# --------------------------------------------------------------------

class Utils

    # Utils::chooseALinePecoStyle(announce: String, strs: Array[String]): String
    def self.chooseALinePecoStyle(announce, strs)
        `echo "#{strs.join("\n")}" | peco --prompt "#{announce}"`.strip
    end

    # Utils::l22()
    def self.l22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # Utils::editTextUsingTextmate(text)
    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end
end

class Estate

    # Estate::uniqueNameResolutionLocationPathOrNull(uniquename)
    def self.uniqueNameResolutionLocationPathOrNull(uniquename)
        location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
        return nil if location.nil?
        location
    end

    # Estate::destroyTNode(tnode)
    def self.destroyTNode(tnode)
        # We try and preserve contents

        destroyTarget = lambda{|target|
            if target["type"] == "line-2A35BA23" then
                # Nothing
                return
            end
            if target["type"] == "text-A9C3641C" then
                textFilepath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, target["filename"])
                return if textFilepath.nil?
                return if !File.exists?(textFilepath)
                CatalystCommon::copyLocationToCatalystBin(textFilepath)
                LucilleCore::removeFileSystemLocation(textFilepath)
                return
            end
            if target["type"] == "url-EFB8D55B" then
                # Nothing
                return
            end
            if target["type"] == "unique-name-C2BF46D6" then
                # Nothing
                return
            end
            if target["type"] == "perma-dir-11859659" then
                folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, target["foldername"])
                return if folderpath.nil?
                return if !File.exists?(folderpath)
                CatalystCommon::copyLocationToCatalystBin(folderpath)
                LucilleCore::removeFileSystemLocation(folderpath)
                return
            end
            raise "[error: e838105]"
        }

        destroyClassificationItem = lambda{|item|
            if item["type"] == "tag-18303A17" then
                # Nothing
                return
            end
            if item["type"] == "timeline-329D3ABD" then
                # Nothing
                return
            end
            raise "[error: a38375c2]"
        }

        tnode["targets"].each{|target| destroyTarget.call(target) }
        tnode["classification"].each{|item| destroyClassificationItem.call(item) }

        tnodelocation = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR,tnode["filename"])
        if tnodelocation.nil? then
            puts "[warning: 82d400d0] Interesting. This should not have hapenned."
            LucilleCore::pressEnterToContinue()
            return
        end
        CatalystCommon::copyLocationToCatalystBin(tnodelocation)
        LucilleCore::removeFileSystemLocation(tnodelocation)
    end

    # ------------------------------------------
    # Integrity

    # Estate::objectIsTNodeTarget(object)
    def self.objectIsTNodeTarget(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["type"].nil?
        types = ["lstore-directory-mark-BEE670D0", "unique-name-C2BF46D6", "url-EFB8D55B", "perma-dir-11859659", "text-A9C3641C", "line-2A35BA23"]
        return false if !types.include?(object["type"])
        if object["type"] == "perma-dir-11859659" then
            return false if object["foldername"].nil?
        end
        true
    end

    # Return true if the passed object is a well formed permanode
    # Estate::objectIsTNode(object)
    def self.objectIsTNode(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["filename"].nil?
        return false if object["description"].nil?
        return false if object["description"].lines.to_a.size != 1
        return false if object["targets"].nil?
        return false if object["targets"].any?{|target| !Estate::objectIsTNodeTarget(target) }
        return false if object["classification"].nil?
        true
    end

    # ------------------------------------------
    # IO Ops

    # Estate::commitTNodeToDisk(pathToYmir, permanode)
    def self.commitTNodeToDisk(pathToYmir, permanode)
        raise "[error: not a permanode]" if !Estate::objectIsTNode(permanode)
        filepath = YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, permanode["filename"])
        if filepath.nil? then
            # probably a new permanode 
            filepath = YmirEstate::makeNewYmirLocationForBasename(pathToYmir, permanode["filename"])
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(permanode)) }
    end

    # Estate::tNodesEnumerator(pathToYmir)
    def self.tNodesEnumerator(pathToYmir)
        isFilenameOfPermanode = lambda {|filename|
            filename[-5, 5] == ".json"
        }
        Enumerator.new do |permanodes|
            YmirEstate::ymirFilepathEnumerator(pathToYmir).each{|filepath|
                next if !isFilenameOfPermanode.call(File.basename(filepath))
                permanodes << JSON.parse(IO.read(filepath))
            }
        end
    end

end

class CoreData

    # CoreData::timelines()
    def self.timelines()
        Estate::tNodesEnumerator(PATH_TO_YMIR)
            .map{|tnode| tnode["classification"] }
            .flatten
            .select{|item| item["type"] == "timeline-329D3ABD" }
            .map{|item| item["timeline"] }
            .uniq
    end

    # CoreData::timelinesInIncreasingActivityTime()
    def self.timelinesInIncreasingActivityTime()
        extractTimelinesFromTNode = lambda {|tnode|
            tnode["classification"]
                .select{|item| item["type"] == "timeline-329D3ABD" }
                .map{|item| item["timeline"] }
        }
        map1 = Estate::tNodesEnumerator(PATH_TO_YMIR).reduce({}){|map2, tnode|
            timelines = extractTimelinesFromTNode.call(tnode)
            timelines.each{|timeline|
                if map2[timeline].nil? then
                    map2[timeline] = tnode["creationTimestamp"]
                else
                    map2[timeline] = [map2[timeline], tnode["creationTimestamp"]].max
                end
            }
            map2
        }
        map1
            .to_a
            .sort{|p1, p2| p1[1]<=>p2[1] }
            .map{|pair| pair[0] }
    end

    # CoreData::tNodeIsOnThisTimeline(tnode, timeline)
    def self.tNodeIsOnThisTimeline(tnode, timeline)
        tnode["classification"].any?{|item| item["type"] == "timeline-329D3ABD" and item["timeline"] == timeline }
    end

    # CoreData::getTimelineTNodesOrdered(timeline)
    def self.getTimelineTNodesOrdered(timeline)
        Estate::tNodesEnumerator(PATH_TO_YMIR)
            .select{|tnode| CoreData::tNodeIsOnThisTimeline(tnode, timeline) }
            .sort{|tn1, tn2| tn1["creationTimestamp"] <=> tn2["creationTimestamp"] }
    end

    # CoreData::searchPatternToTNodes(pattern)
    def self.searchPatternToTNodes(pattern)
        Estate::tNodesEnumerator(PATH_TO_YMIR)
            .select{|tnode| 
                b1 = tnode["uuid"].downcase.include?(pattern.downcase)
                b2 = tnode["description"].downcase.include?(pattern.downcase)
                b1 or b2
            }
            .sort{|tn1, tn2| tn1["creationTimestamp"] <=> tn2["creationTimestamp"] }
    end

    # CoreData::getTNodeByUUIDOrNull(uuid)
    def self.getTNodeByUUIDOrNull(uuid)
        Estate::tNodesEnumerator(PATH_TO_YMIR)
            .select{|tnode| tnode["uuid"] == uuid }
            .first
    end

end

class TMakers

    # TMakers::interactivelymakeZeroOrMoreTags()
    def self.interactivelymakeZeroOrMoreTags()
        tags = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty for exit): ")
            break if tag.size == 0
            tags << tag
        }
        tags
    end

    # TMakers::interactively2SelectTimelineOrNull(timelines)
    def self.interactively2SelectTimelineOrNull(timelines)
        timeline = Utils::chooseALinePecoStyle("Timeline:", [""] + timelines)
        return nil if timeline.size == 0
        timeline
    end

    # TMakers::interactively2SelectOneTimelinePossiblyNew(timelines)
    def self.interactively2SelectOneTimelinePossiblyNew(timelines)
        timeline = TMakers::interactively2SelectTimelineOrNull(timelines)
        return timeline if timeline
        LucilleCore::askQuestionAnswerAsString("new timeline: ")
    end

    # TMakers::interactively2SelectAtLeastOneTimelinePossiblyNewOne(_timelines_)
    def self.interactively2SelectAtLeastOneTimelinePossiblyNewOne(_timelines_)
        timelines = []
        loop {
            timeline = TMakers::interactively2SelectTimelineOrNull(_timelines_)
            break if timeline.nil?
            timelines << timeline
        }
        loop {
            timeline = LucilleCore::askQuestionAnswerAsString("new timeline (empty to exit): ")
            break if timeline.size == 0
            timelines << timeline
        }
        if timelines.size == 0 then
            return TMakers::interactively2SelectAtLeastOneTimelinePossiblyNewOne(_timelines_)
        end
        timelines
    end

    # TMakers::makeTNodeTargetInteractivelyOrNull()
    def self.makeTNodeTargetInteractivelyOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "text", "url", "unique name", "permadir"])
        return nil if type.nil?
        if type == "line" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "line-2A35BA23",
                "line" => LucilleCore::askQuestionAnswerAsString("line: ")
            }
        end
        if type == "text" then
            filename = "#{Utils::l22()}.txt"
            filecontents = Utils::editTextUsingTextmate("")
            filepath = YmirEstate::makeNewYmirLocationForBasename(PATH_TO_YMIR, filename)
            File.open(filepath, "w"){|f| f.puts(filecontents) }
            return {
                "uuid"     => SecureRandom.uuid,
                "type"     => "text-A9C3641C",
                "filename" => filename
            }
        end
        if type == "url" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url"  => LucilleCore::askQuestionAnswerAsString("url: ")
            }
        end
        if type == "unique name" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => LucilleCore::askQuestionAnswerAsString("unique name: ")
            }
        end
        if type == "permadir" then
            foldername = Utils::l22()
            folderpath = YmirEstate::makeNewYmirLocationForBasename(PATH_TO_YMIR, foldername)
            FileUtils.mkdir(folderpath)
            system("open '#{folderpath}'")
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername
            }
        end
    end

    # TMakers::makeOneTNodeTarget()
    def self.makeOneTNodeTarget()
        loop {
            target = TMakers::makeTNodeTargetInteractivelyOrNull()
            return target if target
        }
    end

    # TMakers::makeNewPermadirOutOfThoseLocationsDestroyGivenLocationsAndReturnPermadirTarget(locations)
    def self.makeNewPermadirOutOfThoseLocationsDestroyGivenLocationsAndReturnPermadirTarget(locations)
        foldername2 = Utils::l22()
        folderpath2 = YmirEstate::makeNewYmirLocationForBasename(PATH_TO_YMIR, foldername2)
        FileUtils.mkdir(folderpath2)
        locations.each{|location|
            LucilleCore::copyFileSystemLocation(location, folderpath2)
        }
        locations.each{|location|
            LucilleCore::removeFileSystemLocation(location)
        }
        {
            "uuid"       => SecureRandom.uuid,
            "type"       => "perma-dir-11859659",
            "foldername" => foldername2
        }
    end

    # TMakers::makeNewTNode()
    def self.makeNewTNode()
        uuid = SecureRandom.uuid
        target = TMakers::makeOneTNodeTarget()
        description = Interface::targetToString(target)
        targets = [ target ]
        timeline = TMakers::interactively2SelectOneTimelinePossiblyNew(CoreData::timelinesInIncreasingActivityTime().reverse)
        classification = [{
            "uuid"     => SecureRandom.uuid,
            "type"     => "timeline-329D3ABD",
            "timeline" => timeline
        }]
        # we are no setting tags for TNodes
        tnode = {
            "uuid"              => uuid,
            "filename"          => "#{Utils::l22()}.json",
            "creationTimestamp" => Time.new.to_f,
            "description"       => description,
            "targets"           => targets,
            "classification"    => classification
        }
        puts JSON.pretty_generate(tnode)
        Estate::commitTNodeToDisk(PATH_TO_YMIR, tnode)
    end

end

class Interface

    # Interface::targetToString(target)
    def self.targetToString(target)
        if target["type"] == "line-2A35BA23" then
            return "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, target["filename"])
            if filepath.nil? or !File.exists?(filepath) then
                return "[error: e8703185] There doesn't seem to be a Ymir file for filename '#{target["filename"]}'"
            else
                return "text (#{IO.read(filepath).lines.count} lines)"
            end
        end
        if target["type"] == "url-EFB8D55B" then
            return "url: #{target["url"]}"
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return "unique name: #{target["name"]}"
        end
        if target["type"] == "perma-dir-11859659" then
            foldername = target["foldername"]
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, foldername)
            locations = LucilleCore::locationsAtFolder(folderpath)
            if locations.size == 0 then
                return "permadir: #{target["foldername"]} (empty folder)"
            end
            if locations.size == 1 then
                return "permadir: contents: #{File.basename(locations[0])}"
            end
            if locations.size > 1 then
                return "permadir: multiple contents"
            end
            raise "[error: e4969484]"
        end
        raise "[error: 706ce2f5]"
    end

    # Interface::classificationItemToString(item)
    def self.classificationItemToString(item)
        if item["type"] == "tag-18303A17" then
            return "tag: #{item["tag"]}"
        end
        if item["type"] == "timeline-329D3ABD" then
            return "timeline: #{item["timeline"]}"
        end
        raise "[error: 44ccb03c]"
    end

    # Interface::diveTarget(tnodeuuid, target)
    def self.diveTarget(tnodeuuid, target)
        puts "Target: #{Interface::targetToString(target)}"
        operations = [
            "open", 
            "remove/destroy from tnode"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation: ", operations)
        return if operation.nil?
        if operation == "open" then

        end
        if operation == "remove/destroy from tnode" then
            # we get the tnode and just remove the offending target
            tnode = CoreData::getTNodeByUUIDOrNull(tnodeuuid)
            return if tnode.nil?
            tnode["targets"] = tnode["targets"].reject{|t| t["uuid"]==target["uuid"] }
            Estate::commitTNodeToDisk(PATH_TO_YMIR, tnode)
        end
    end

    # Interface::diveClassificationItem(tnodeuuid, item)
    def self.diveClassificationItem(tnodeuuid, item)
        puts "Item: #{Interface::classificationItemToString(item)}"
        operations = [
            "remove/destroy from tnode"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation: ", operations)
        return if operation.nil?
        if operation == "remove/destroy from tnode" then
            # we get the tnode and just remove the offending classification item
            tnode = CoreData::getTNodeByUUIDOrNull(tnodeuuid)
            return if tnode.nil?
            tnode["classification"] = tnode["classification"].reject{|i| i["uuid"]==item["uuid"] }
            Estate::commitTNodeToDisk(PATH_TO_YMIR, tnode)
        end
    end

    # Interface::diveTargets(tnodeuuid, targets)
    def self.diveTargets(tnodeuuid, targets)
        target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target: ", targets, lambda{|target| Interface::targetToString(target) })
        return if target.nil?
    end

    # Interface::diveClassificationItems(tnodeuuid, items)
    def self.diveClassificationItems(tnodeuuid, items)
        puts "Interface::diveClassificationItems is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # Interface::openTarget(target)
    def self.openTarget(target)
        if target["type"] == "line-2A35BA23" then
            puts "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, target["filename"])
            if filepath.nil? or !File.exists?(filepath) then
                puts "[error: 359a6c99] There doesn't seem to be a Ymir file for filename '#{target["filename"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{filepath}'")
        end
        if target["type"] == "url-EFB8D55B" then
            system("open '#{target["url"]}'")
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            location = Estate::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location.nil? then
                puts "I could not resolve unique name '#{uniquename}'"
                LucilleCore::pressEnterToContinue()
            else
                if LucilleCore::askQuestionAnswerAsBoolean("opening '#{location}' ? ") then
                    system("open '#{location}'")
                end
            end
        end
        if target["type"] == "perma-dir-11859659" then
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, target["foldername"])
            if folderpath.nil? or !File.exists?(folderpath) then
                puts "[error: c87c7b41] There doesn't seem to be a Ymir file for filename '#{target["foldername"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{folderpath}'")
        end
    end

    # Interface::optimizedOpenTarget(target)
    def self.optimizedOpenTarget(target)
        if target["type"] == "line-2A35BA23" then
            puts "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, target["filename"])
            if filepath.nil? or !File.exists?(filepath) then
                puts "[error: a3a1b7a0] There doesn't seem to be a Ymir file for filename '#{target["filename"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{filepath}'")
        end
        if target["type"] == "url-EFB8D55B" then
            system("open '#{target["url"]}'")
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            location = Estate::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location.nil? then
                puts "I could not resolve unique name '#{uniquename}'"
                LucilleCore::pressEnterToContinue()
            else
                system("open '#{location}'")
            end
        end
        if target["type"] == "perma-dir-11859659" then
            locationCanBeQuickOpened = lambda {|location|
                # We white list the ones that we want
                whiteListedExtensions = [".txt", ".jpg", ".png", ".md", ".webloc", ".eml"]
                return true if whiteListedExtensions.any?{|extension| location[-extension.size, extension.size] == extension }
                false
            }
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, target["foldername"])
            if folderpath.nil? or !File.exists?(folderpath) then
                puts "[error: 0916fd87] There doesn't seem to be a Ymir file for filename '#{target["foldername"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            sublocations = LucilleCore::nonDottedLocationsAtFolder(folderpath)
            if sublocations.size != 0 and locationCanBeQuickOpened.call(sublocations[0]) and !sublocations[0].include?("'") then
                system("open '#{sublocations[0]}'")
            else
                system("open '#{folderpath}'")
            end
        end
    end

    # Interface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
    def self.optimizedOpenTNodeUniqueTargetOrNothing(tnode)
        return if tnode["targets"].size != 1
        Interface::optimizedOpenTarget(tnode["targets"][0])
    end

    # Interface::tNodeDive(tnodeuuid)
    def self.tNodeDive(tnodeuuid)
        loop {
            tnode = CoreData::getTNodeByUUIDOrNull(tnodeuuid)
            if tnode.nil? then
                raise "[error: a151f422] tnodeuuid: #{tnodeuuid}"
            end
            puts "tnode:"
            puts "    uuid: #{tnode["uuid"]}"
            puts "    filename: #{tnode["filename"]}"
            puts "    description: #{tnode["description"]}"
            puts "    targets:"
            tnode["targets"].each{|target|
                puts "        #{Interface::targetToString(target)}"
            }
            puts "    classification items:"
            tnode["classification"].each{|item|
                puts "        #{Interface::classificationItemToString(item)}"
            }
            operations = [
                "quick open",
                "edit description",
                "dive targets",
                "dive classification items",
                "destroy tnode"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "quick open" then
                Interface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
            end
            if operation == "edit description" then
                tnode["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
                Estate::commitTNodeToDisk(PATH_TO_YMIR, tnode)
            end
            if operation == "dive targets" then
                Interface::diveTargets(tnode["uuid"], tnode["targets"])
            end
            if operation == "dive classification items" then
                Interface::diveClassificationItems(tnode["uuid"], tnode["classification"])
            end
            if operation == "destroy tnode" then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item? ") then
                    Estate::destroyTNode(tnode)
                    return
                end
            end
        }
    end

    # Interface::tNodesDive(tnodes)
    def self.tNodesDive(tnodes)
        loop {
            tnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("tnode: ", tnodes, lambda{|tnode| tnode["description"] })
            return if tnode.nil?
            Interface::tNodeDive(tnode["uuid"])
        }
    end

    # Interface::timelineDive(timeline)
    def self.timelineDive(timeline)
        loop {
            puts "Timeline: #{timeline}"
            tnodes = CoreData::getTimelineTNodesOrdered(timeline)
            tnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("tnode: ", tnodes, lambda{|tnode| tnode["description"] })
            return if tnode.nil?
            Interface::tNodeDive(tnode["uuid"])
        }
    end

    # Interface::timelinesDive()
    def self.timelinesDive()
        loop {
            timeline = TMakers::interactively2SelectTimelineOrNull(CoreData::timelinesInIncreasingActivityTime().reverse)
            return if timeline.nil?
            Interface::timelineDive(timeline)
        }
    end

    # Interface::timelineWalk(timeline)
    def self.timelineWalk(timeline)
        operationWithSpecifiedDefault = lambda {|default|
            operation = LucilleCore::askQuestionAnswerAsString("operation: (open, dive, destroy, next, exit) [default: #{default}]: ")
            if operation == "" then
                default
            else
                operation
            end
        }
        tnodes = CoreData::getTimelineTNodesOrdered(timeline)
        loop {
            tnode = tnodes.shift
            default = "open"
            loop {
                puts ""
                puts "-> #{tnode["description"]}"
                operation = operationWithSpecifiedDefault.call(default)
                if operation == "open" then
                    Interface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
                    default = "destroy"
                end
                if operation == "dive" then
                    Interface::tNodeDive(tnode["uuid"])
                    default = "open"
                end
                if operation == "next" then
                    break
                end
                if operation == "destroy" then
                    Estate::destroyTNode(tnode)
                    break
                end
                if operation == "exit" then
                    return
                end
            }
        }
    end

    # Interface::ui()
    def self.ui()
        loop {
            operations = [
                "make new item",
                "search",
                "view most recent items",
                "timelines dive",
                "timeline walk"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "make new item" then
                TMakers::makeNewTNode()
            end
            if operation == "search" then
                pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
                tnodes = CoreData::searchPatternToTNodes(pattern)
                if tnodes.size == 0 then
                    puts "Could not find tnodes for this pattern: '#{pattern}'"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                Interface::tNodesDive(tnodes)
            end
            if operation == "view most recent items" then
                tnodes = Estate::tNodesEnumerator(PATH_TO_YMIR).to_a.reverse.take(10)
                Interface::tNodesDive(tnodes)
            end
            if operation == "timelines dive" then
                Interface::timelinesDive()
            end
            if operation == "timeline walk" then
                timeline = TMakers::interactively2SelectTimelineOrNull(CoreData::timelinesInIncreasingActivityTime().reverse)
                next if timeline.nil?
                Interface::timelineWalk(timeline)
            end
        }
    end

end

class TodoNyxConverter
    # As it says on the tin, this class has the tools to convert a todo item into a Nyx item

    # TodoNyxConverter::getNyxTimelines()
    def self.getNyxTimelines()
        JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Nyx/nyx-api-timelines`)
    end

    # TodoNyxConverter::transmuteTodoTargetIntoNyxTarget(target, todoYmirFolderPath, nyxYmirFolderPath)
    def self.transmuteTodoTargetIntoNyxTarget(target, todoYmirFolderPath, nyxYmirFolderPath)
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return target
        end
        if target["type"] == "url-EFB8D55B" then
            return target
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return target
        end
        if target["type"] == "perma-dir-11859659" then
            foldername = target["foldername"]
            folderpath1 = YmirEstate::locationBasenameToYmirLocationOrNull(todoYmirFolderPath, foldername)
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(nyxYmirFolderPath,  foldername)
            FileUtils.mkdir(folderpath2)
            LucilleCore::copyContents(folderpath1, folderpath2)
            return target
        end
        if target["type"] == "text-A9C3641C" then
            filename1 = target["filename"]
            filepath1 = YmirEstate::locationBasenameToYmirLocationOrNull(todoYmirFolderPath, filename1)
            foldername2 = Utils::l22()
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(nyxYmirFolderPath, foldername2)
            FileUtils.mkdir(folderpath2)
            FileUtils.cp(filepath1, folderpath2)
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
        end
        if target["type"] == "line-2A35BA23" then
            line = target["line"]
            foldername2 = Utils::l22()
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(nyxYmirFolderPath, foldername2)
            FileUtils.mkdir(folderpath2)
            File.open("#{folderpath2}/text.txt", "w"){|f| f.puts(line) }
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
        end
        raise "[error: 79e14af6]"
    end

    # TodoNyxConverter::interactivelymakeZeroOrMoreTags()
    def self.interactivelymakeZeroOrMoreTags()
        TMakers::interactivelymakeZeroOrMoreTags()
    end

    # TodoNyxConverter::interactivelySelectAtLeastOneTimelinePossiblyNewOne(timelines)
    def self.interactivelySelectAtLeastOneTimelinePossiblyNewOne(timelines)
        TMakers::interactively2SelectAtLeastOneTimelinePossiblyNewOne(timelines)
    end

    # TodoNyxConverter::transmuteTodoItemIntoNyxObject(todo, todoYmirFolderPath, nyxYmirFolderPath)
    def self.transmuteTodoItemIntoNyxObject(todo, todoYmirFolderPath, nyxYmirFolderPath)
        nyx = {}
        nyx["uuid"] = todo["uuid"]
        nyx["filename"] = todo["filename"]
        nyx["creationTimestamp"] = todo["creationTimestamp"]
        nyx["referenceDateTime"] = Time.new.utc.iso8601
        nyx["description"] = Utils::editTextUsingTextmate(todo["description"])
        nyx["targets"] = todo["targets"].map{|target| TodoNyxConverter::transmuteTodoTargetIntoNyxTarget(target, todoYmirFolderPath, nyxYmirFolderPath) }
        tagObjects = TodoNyxConverter::interactivelymakeZeroOrMoreTags()
                        .map{|tag|
                            {
                                "uuid" => SecureRandom.uuid,
                                "type" => "tag-18303A17",
                                "tag"  => tag
                            }
                        }
        timelineObjects = TodoNyxConverter::interactivelySelectAtLeastOneTimelinePossiblyNewOne(TodoNyxConverter::getNyxTimelines())
                        .map{|timeline|
                            {
                                "uuid" => SecureRandom.uuid,
                                "type" => "timeline-329D3ABD",
                                "timeline" => timeline
                            }
                        }
        nyx["classification"] = tagObjects + timelineObjects
        nyx
    end
end

# --------------------------------------------------------------------

WALKS_DATASTORE_FOLDERPATH = "/Users/pascal/Galaxy/DataBank/todo/todo-walks/dataset"
WALKS_SETUUID1 = "CFCD19D8-A904-41C5-AE42-37EFE5ACF733"

=begin

Dataset1

    Point:
    {
        "uuid"     => String,
        "unixtime" => Integer,
        "timeline" => String,
        "timespan" => Float
    }

    TimeStructure: Map[String # Timeline, Float # Timespan]

=end

class WalksCore

    # WalksCore::timeline2TimeMapping()
    def self.timeline2TimeMapping() # TimeStructure: Map[String # Timeline, Float # Timespan]
        BTreeSets::values(WALKS_DATASTORE_FOLDERPATH, WALKS_SETUUID1)
            .reduce({}){|mapping, point|
                if mapping[point["timeline"]].nil? then
                    mapping[point["timeline"]] = 0
                end
                mapping[point["timeline"]] = mapping[point["timeline"]] + point["timespan"]
                mapping
            }
    end

    # WalksCore::get2TNodesTimelines()
    def self.get2TNodesTimelines() # Array[String]
        Estate::tNodesEnumerator(PATH_TO_YMIR)
            .map{|tnode|
                tnode["classification"]
                    .select{|item| item["type"] == "timeline-329D3ABD" }
                    .map{|item| item["timeline"] }
            }
            .flatten
            .uniq
    end

    # WalksCore::remove2FromDataset1ThePointsWithObsoleteTimelines()
    def self.remove2FromDataset1ThePointsWithObsoleteTimelines()
        datasetTimelines = BTreeSets::values(WALKS_DATASTORE_FOLDERPATH, WALKS_SETUUID1).map{|point| point["timeline"] }.uniq
        aliveTimelines = WalksCore::get2TNodesTimelines()
        deadTimelines = datasetTimelines - aliveTimelines
        BTreeSets::values(WALKS_DATASTORE_FOLDERPATH, WALKS_SETUUID1).each{|point|
            if deadTimelines.include?(point["timeline"]) then
                #puts "destroying point:"
                #puts JSON.pretty_generate(point)
                BTreeSets::destroy(WALKS_DATASTORE_FOLDERPATH, WALKS_SETUUID1, point["uuid"])
            end
        }
    end

    # WalksCore::limit2SizeOfDataset1()
    def self.limit2SizeOfDataset1()
        points = BTreeSets::values(WALKS_DATASTORE_FOLDERPATH, WALKS_SETUUID1)
            .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
        while points.size > 100 do
            point = points.shift
            #puts "destroying point:"
            #puts JSON.pretty_generate(point)
            BTreeSets::destroy(WALKS_DATASTORE_FOLDERPATH, WALKS_SETUUID1, point["uuid"])
        end
    end

    # WalksCore::get2TimelineWithLowestTimespan(timelines, timeStruct)
    def self.get2TimelineWithLowestTimespan(timelines, timeStruct)
        timelines.each{|timeline|
            if timeStruct[timeline].nil? then
                timeStruct[timeline] = 0
            end
        }
        selection = timeStruct.to_a.reduce(nil){|chosen, pair|
            if chosen.nil? then
                pair
            else
                if chosen[1] > pair[1] then
                    pair
                else
                    chosen
                end
            end

        }
        selection[0]
    end

end
