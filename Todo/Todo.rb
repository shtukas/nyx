
# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/Todo.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/YmirEstate.rb"
=begin
    YmirEstate::ymirFilepathEnumerator(pathToYmir)
    YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, basename)
    YmirEstate::makeNewYmirLocationForBasename(pathToYmir, basename)
        # If base name is meant to be the name of a folder then folder itself 
        # still need to be created. Only the parent is created.
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Zeta.rb"
=begin
    Zeta::makeNewFile(filepath)
    Zeta::set(filepath, key, value)
    Zeta::getOrNull(filepath, key)
    Zeta::destroy(filepath, key)
=end

# --------------------------------------------------------------------

class TodoXBinUtils

    # TodoBinTodoXUtils::newBinArchivesFolderpath()
    def self.newBinArchivesFolderpath()
        time = Time.new
        folder1 = "/Users/pascal/Galaxy/DataBank/Catalyst/Bin-Timeline/#{time.strftime("%Y")}/#{time.strftime("%Y-%m")}/#{time.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(folder3)
        folder3
    end

    # TodoBinTodoXUtils::copyLocationToCatalystBin(location)
    def self.copyLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        targetFolder = TodoBinTodoXUtils::newBinArchivesFolderpath()
        LucilleCore::copyFileSystemLocation(location,targetFolder)
    end

end

class TodoXUtils

    # TodoXUtils::chooseALinePecoStyle(announce: String, strs: Array[String]): String
    def self.chooseALinePecoStyle(announce, strs)
        `echo "#{strs.join("\n")}" | peco --prompt "#{announce}"`.strip
    end

    # TodoXUtils::l22()
    def self.l22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # TodoXUtils::editTextUsingTextmate(text)
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

class TodoXEstate

    # TodoXEstate::uniqueNameResolutionLocationPathOrNull(uniquename)
    def self.uniqueNameResolutionLocationPathOrNull(uniquename)
        location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
        return nil if location.nil?
        location
    end

    # TodoXEstate::destroyTNode(tnode)
    def self.destroyTNode(tnode)
        # We try and preserve contents

        destroyTarget = lambda{|target|
            if target["type"] == "line-2A35BA23" then
                # Nothing
                return
            end
            if target["type"] == "text-A9C3641C" then
                textFilepath = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), target["filename"])
                return if textFilepath.nil?
                return if !File.exists?(textFilepath)
                TodoBinTodoXUtils::copyLocationToCatalystBin(textFilepath)
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
                folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), target["foldername"])
                return if folderpath.nil?
                return if !File.exists?(folderpath)
                TodoBinTodoXUtils::copyLocationToCatalystBin(folderpath)
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

        tnodelocation = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), tnode["filename"])
        if tnodelocation.nil? then
            puts "[warning: 82d400d0] Interesting. This should not have hapenned."
            LucilleCore::pressEnterToContinue()
            return
        end
        TodoBinTodoXUtils::copyLocationToCatalystBin(tnodelocation)
        LucilleCore::removeFileSystemLocation(tnodelocation)
    end

    # ------------------------------------------
    # Integrity

    # TodoXEstate::objectIsTNodeTarget(object)
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
    # TodoXEstate::objectIsTNode(object)
    def self.objectIsTNode(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["filename"].nil?
        return false if object["description"].nil?
        return false if object["description"].lines.to_a.size != 1
        return false if object["targets"].nil?
        return false if object["targets"].any?{|target| !TodoXEstate::objectIsTNodeTarget(target) }
        return false if object["classification"].nil?
        true
    end

    # ------------------------------------------
    # IO Ops

    # TodoXEstate::commitTNodeToDisk(pathToYmir, permanode)
    def self.commitTNodeToDisk(pathToYmir, permanode)
        raise "[error: not a permanode]" if !TodoXEstate::objectIsTNode(permanode)
        filepath = YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, permanode["filename"])
        if filepath.nil? then
            # probably a new permanode 
            filepath = YmirEstate::makeNewYmirLocationForBasename(pathToYmir, permanode["filename"])
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(permanode)) }
    end

    # TodoXEstate::tNodesEnumerator(pathToYmir)
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

class TodoXCoreData

    # TodoXCoreData::timelines()
    def self.timelines()
        TodoXEstate::tNodesEnumerator(Todo::pathToYmir())
            .map{|tnode| tnode["classification"] }
            .flatten
            .select{|item| item["type"] == "timeline-329D3ABD" }
            .map{|item| item["timeline"] }
            .uniq
    end

    # TodoXCoreData::timelinesInIncreasingActivityTime()
    def self.timelinesInIncreasingActivityTime()
        extractTimelinesFromTNode = lambda {|tnode|
            tnode["classification"]
                .select{|item| item["type"] == "timeline-329D3ABD" }
                .map{|item| item["timeline"] }
        }
        map1 = TodoXEstate::tNodesEnumerator(Todo::pathToYmir()).reduce({}){|map2, tnode|
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

    # TodoXCoreData::tNodeIsOnThisTimeline(tnode, timeline)
    def self.tNodeIsOnThisTimeline(tnode, timeline)
        tnode["classification"].any?{|item| item["type"] == "timeline-329D3ABD" and item["timeline"] == timeline }
    end

    # TodoXCoreData::getTimelineTNodesOrdered(timeline)
    def self.getTimelineTNodesOrdered(timeline)
        TodoXEstate::tNodesEnumerator(Todo::pathToYmir())
            .select{|tnode| TodoXCoreData::tNodeIsOnThisTimeline(tnode, timeline) }
            .sort{|tn1, tn2| tn1["creationTimestamp"] <=> tn2["creationTimestamp"] }
    end

    # TodoXCoreData::searchPatternToTNodes(pattern)
    def self.searchPatternToTNodes(pattern)
        TodoXEstate::tNodesEnumerator(Todo::pathToYmir())
            .select{|tnode| 
                b1 = tnode["uuid"].downcase.include?(pattern.downcase)
                b2 = tnode["description"].downcase.include?(pattern.downcase)
                b1 or b2
            }
            .sort{|tn1, tn2| tn1["creationTimestamp"] <=> tn2["creationTimestamp"] }
    end

    # TodoXCoreData::getTNodeByUUIDOrNull(uuid)
    def self.getTNodeByUUIDOrNull(uuid)
        TodoXEstate::tNodesEnumerator(Todo::pathToYmir())
            .select{|tnode| tnode["uuid"] == uuid }
            .first
    end

end

class TodoXTMakers

    # TodoXTMakers::interactivelymakeZeroOrMoreTags()
    def self.interactivelymakeZeroOrMoreTags()
        tags = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty for exit): ")
            break if tag.size == 0
            tags << tag
        }
        tags
    end

    # TodoXTMakers::interactively2SelectTimelineOrNull(timelines)
    def self.interactively2SelectTimelineOrNull(timelines)
        timeline = TodoXUtils::chooseALinePecoStyle("Timeline:", [""] + timelines)
        return nil if timeline.size == 0
        timeline
    end

    # TodoXTMakers::interactively2SelectOneTimelinePossiblyNew(timelines)
    def self.interactively2SelectOneTimelinePossiblyNew(timelines)
        timeline = TodoXTMakers::interactively2SelectTimelineOrNull(timelines)
        return timeline if timeline
        LucilleCore::askQuestionAnswerAsString("new timeline: ")
    end

    # TodoXTMakers::interactively2SelectAtLeastOneTimelinePossiblyNewOne(_timelines_)
    def self.interactively2SelectAtLeastOneTimelinePossiblyNewOne(_timelines_)
        timelines = []
        loop {
            timeline = TodoXTMakers::interactively2SelectTimelineOrNull(_timelines_)
            break if timeline.nil?
            timelines << timeline
        }
        loop {
            timeline = LucilleCore::askQuestionAnswerAsString("new timeline (empty to exit): ")
            break if timeline.size == 0
            timelines << timeline
        }
        if timelines.size == 0 then
            return TodoXTMakers::interactively2SelectAtLeastOneTimelinePossiblyNewOne(_timelines_)
        end
        timelines
    end

    # TodoXTMakers::makeTNodeTargetInteractivelyOrNull()
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
            filename = "#{TodoXUtils::l22()}.txt"
            filecontents = TodoXUtils::editTextUsingTextmate("")
            filepath = YmirEstate::makeNewYmirLocationForBasename(Todo::pathToYmir(), filename)
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
            foldername = TodoXUtils::l22()
            folderpath = YmirEstate::makeNewYmirLocationForBasename(Todo::pathToYmir(), foldername)
            FileUtils.mkdir(folderpath)
            system("open '#{folderpath}'")
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername
            }
        end
    end

    # TodoXTMakers::makeOneTNodeTarget()
    def self.makeOneTNodeTarget()
        loop {
            target = TodoXTMakers::makeTNodeTargetInteractivelyOrNull()
            return target if target
        }
    end

    # TodoXTMakers::makeNewPermadirOutOfThoseLocationsDestroyGivenLocationsAndReturnPermadirTarget(locations)
    def self.makeNewPermadirOutOfThoseLocationsDestroyGivenLocationsAndReturnPermadirTarget(locations)
        foldername2 = TodoXUtils::l22()
        folderpath2 = YmirEstate::makeNewYmirLocationForBasename(Todo::pathToYmir(), foldername2)
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

    # TodoXTMakers::makeNewTNode()
    def self.makeNewTNode()
        uuid = SecureRandom.uuid
        target = TodoXTMakers::makeOneTNodeTarget()
        description = TodoXInterface::targetToString(target)
        targets = [ target ]
        timeline = TodoXTMakers::interactively2SelectOneTimelinePossiblyNew(TodoXCoreData::timelinesInIncreasingActivityTime().reverse)
        classification = [{
            "uuid"     => SecureRandom.uuid,
            "type"     => "timeline-329D3ABD",
            "timeline" => timeline
        }]
        # we are no setting tags for TNodes
        tnode = {
            "uuid"              => uuid,
            "filename"          => "#{TodoXUtils::l22()}.json",
            "creationTimestamp" => Time.new.to_f,
            "description"       => description,
            "targets"           => targets,
            "classification"    => classification
        }
        puts JSON.pretty_generate(tnode)
        TodoXEstate::commitTNodeToDisk(Todo::pathToYmir(), tnode)
    end

end

class TodoXInterface

    # TodoXInterface::targetToString(target)
    def self.targetToString(target)
        if target["type"] == "line-2A35BA23" then
            return "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), target["filename"])
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
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), foldername)
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

    # TodoXInterface::classificationItemToString(item)
    def self.classificationItemToString(item)
        if item["type"] == "tag-18303A17" then
            return "tag: #{item["tag"]}"
        end
        if item["type"] == "timeline-329D3ABD" then
            return "timeline: #{item["timeline"]}"
        end
        raise "[error: 44ccb03c]"
    end

    # TodoXInterface::diveTarget(tnodeuuid, target)
    def self.diveTarget(tnodeuuid, target)
        puts "Target: #{TodoXInterface::targetToString(target)}"
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
            tnode = TodoXCoreData::getTNodeByUUIDOrNull(tnodeuuid)
            return if tnode.nil?
            tnode["targets"] = tnode["targets"].reject{|t| t["uuid"]==target["uuid"] }
            TodoXEstate::commitTNodeToDisk(Todo::pathToYmir(), tnode)
        end
    end

    # TodoXInterface::diveClassificationItem(tnodeuuid, item)
    def self.diveClassificationItem(tnodeuuid, item)
        puts "Item: #{TodoXInterface::classificationItemToString(item)}"
        operations = [
            "remove/destroy from tnode"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation: ", operations)
        return if operation.nil?
        if operation == "remove/destroy from tnode" then
            # we get the tnode and just remove the offending classification item
            tnode = TodoXCoreData::getTNodeByUUIDOrNull(tnodeuuid)
            return if tnode.nil?
            tnode["classification"] = tnode["classification"].reject{|i| i["uuid"]==item["uuid"] }
            TodoXEstate::commitTNodeToDisk(Todo::pathToYmir(), tnode)
        end
    end

    # TodoXInterface::diveTargets(tnodeuuid, targets)
    def self.diveTargets(tnodeuuid, targets)
        target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target: ", targets, lambda{|target| TodoXInterface::targetToString(target) })
        return if target.nil?
    end

    # TodoXInterface::diveClassificationItems(tnodeuuid, items)
    def self.diveClassificationItems(tnodeuuid, items)
        puts "TodoXInterface::diveClassificationItems is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # TodoXInterface::openTarget(target)
    def self.openTarget(target)
        if target["type"] == "line-2A35BA23" then
            puts "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), target["filename"])
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
            location = TodoXEstate::uniqueNameResolutionLocationPathOrNull(uniquename)
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
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), target["foldername"])
            if folderpath.nil? or !File.exists?(folderpath) then
                puts "[error: c87c7b41] There doesn't seem to be a Ymir file for filename '#{target["foldername"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{folderpath}'")
        end
    end

    # TodoXInterface::optimizedOpenTarget(target)
    def self.optimizedOpenTarget(target)
        if target["type"] == "line-2A35BA23" then
            puts "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), target["filename"])
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
            location = TodoXEstate::uniqueNameResolutionLocationPathOrNull(uniquename)
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
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(Todo::pathToYmir(), target["foldername"])
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

    # TodoXInterface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
    def self.optimizedOpenTNodeUniqueTargetOrNothing(tnode)
        return if tnode["targets"].size != 1
        TodoXInterface::optimizedOpenTarget(tnode["targets"][0])
    end

    # TodoXInterface::tNodeDive(tnodeuuid)
    def self.tNodeDive(tnodeuuid)
        loop {
            tnode = TodoXCoreData::getTNodeByUUIDOrNull(tnodeuuid)
            if tnode.nil? then
                raise "[error: a151f422] tnodeuuid: #{tnodeuuid}"
            end
            puts "tnode:"
            puts "    uuid: #{tnode["uuid"]}"
            puts "    filename: #{tnode["filename"]}"
            puts "    description: #{tnode["description"]}"
            puts "    targets:"
            tnode["targets"].each{|target|
                puts "        #{TodoXInterface::targetToString(target)}"
            }
            puts "    classification items:"
            tnode["classification"].each{|item|
                puts "        #{TodoXInterface::classificationItemToString(item)}"
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
                TodoXInterface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
            end
            if operation == "edit description" then
                tnode["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
                TodoXEstate::commitTNodeToDisk(Todo::pathToYmir(), tnode)
            end
            if operation == "dive targets" then
                TodoXInterface::diveTargets(tnode["uuid"], tnode["targets"])
            end
            if operation == "dive classification items" then
                TodoXInterface::diveClassificationItems(tnode["uuid"], tnode["classification"])
            end
            if operation == "destroy tnode" then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item? ") then
                    TodoXEstate::destroyTNode(tnode)
                    return
                end
            end
        }
    end

    # TodoXInterface::tNodesDive(tnodes)
    def self.tNodesDive(tnodes)
        loop {
            tnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("tnode: ", tnodes, lambda{|tnode| tnode["description"] })
            return if tnode.nil?
            TodoXInterface::tNodeDive(tnode["uuid"])
        }
    end

    # TodoXInterface::timelineDive(timeline)
    def self.timelineDive(timeline)
        loop {
            puts "Timeline: #{timeline}"
            tnodes = TodoXCoreData::getTimelineTNodesOrdered(timeline)
            tnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("tnode: ", tnodes, lambda{|tnode| tnode["description"] })
            return if tnode.nil?
            TodoXInterface::tNodeDive(tnode["uuid"])
        }
    end

    # TodoXInterface::timelinesDive()
    def self.timelinesDive()
        loop {
            timeline = TodoXTMakers::interactively2SelectTimelineOrNull(TodoXCoreData::timelinesInIncreasingActivityTime().reverse)
            return if timeline.nil?
            TodoXInterface::timelineDive(timeline)
        }
    end

    # TodoXInterface::timelineWalk(timeline)
    def self.timelineWalk(timeline)
        operationWithSpecifiedDefault = lambda {|default|
            operation = LucilleCore::askQuestionAnswerAsString("operation: (open, dive, destroy, next, exit) [default: #{default}]: ")
            if operation == "" then
                default
            else
                operation
            end
        }
        tnodes = TodoXCoreData::getTimelineTNodesOrdered(timeline)
        loop {
            tnode = tnodes.shift
            default = "open"
            loop {
                puts ""
                puts "-> #{tnode["description"]}"
                operation = operationWithSpecifiedDefault.call(default)
                if operation == "open" then
                    TodoXInterface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
                    default = "destroy"
                end
                if operation == "dive" then
                    TodoXInterface::tNodeDive(tnode["uuid"])
                    default = "open"
                end
                if operation == "next" then
                    break
                end
                if operation == "destroy" then
                    TodoXEstate::destroyTNode(tnode)
                    break
                end
                if operation == "exit" then
                    return
                end
            }
        }
    end

    # TodoXInterface::ui()
    def self.ui()
        loop {
            system("clear")
            puts "Todo 🗃️"
            operations = [
                "make new item",
                "search",
                "view most recent items",
                "timelines dive",
                "timeline walk",
                "numbers"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "make new item" then
                TodoXTMakers::makeNewTNode()
            end
            if operation == "search" then
                pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
                tnodes = TodoXCoreData::searchPatternToTNodes(pattern)
                if tnodes.size == 0 then
                    puts "Could not find tnodes for this pattern: '#{pattern}'"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                TodoXInterface::tNodesDive(tnodes)
            end
            if operation == "view most recent items" then
                tnodes = TodoXEstate::tNodesEnumerator(Todo::pathToYmir()).to_a.reverse.take(10)
                TodoXInterface::tNodesDive(tnodes)
            end
            if operation == "timelines dive" then
                TodoXInterface::timelinesDive()
            end
            if operation == "timeline walk" then
                timeline = TodoXTMakers::interactively2SelectTimelineOrNull(TodoXCoreData::timelinesInIncreasingActivityTime().reverse)
                next if timeline.nil?
                TodoXInterface::timelineWalk(timeline)
            end
            if operation == "numbers" then
                puts "timeline mapping:"
                timeStruct = TodoXWalksCore::timeline2TimeMapping()
                TodoXWalksCore::get2TNodesTimelines().each{|timeline|
                    if timeStruct[timeline].nil? then
                        timeStruct[timeline] = 0
                    end
                }
                timeStruct
                    .to_a
                    .sort{|p1, p2| p1[1] <=> p2[1] }
                    .each{|timeline, timespan|
                        puts "    -> #{timeline}: #{timespan}"
                    }
                LucilleCore::pressEnterToContinue()
            end
        }
    end

end

class TodoXNyxConverter
    # As it says on the tin, this class has the tools to convert a todo item into a Nyx item

    # TodoXNyxConverter::getNyxTimelines()
    def self.getNyxTimelines()
        JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/nyx-api-timelines`)
    end

    # TodoXNyxConverter::transmuteTodoTargetIntoNyxTarget(target, todoYmirFolderPath, nyxYmirFolderPath)
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
            foldername2 = TodoXUtils::l22()
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
            foldername2 = TodoXUtils::l22()
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

    # TodoXNyxConverter::interactivelymakeZeroOrMoreTags()
    def self.interactivelymakeZeroOrMoreTags()
        TodoXTMakers::interactivelymakeZeroOrMoreTags()
    end

    # TodoXNyxConverter::interactivelySelectAtLeastOneTimelinePossiblyNewOne(timelines)
    def self.interactivelySelectAtLeastOneTimelinePossiblyNewOne(timelines)
        TodoXTMakers::interactively2SelectAtLeastOneTimelinePossiblyNewOne(timelines)
    end

    # TodoXNyxConverter::transmuteTodoItemIntoNyxObject(todo, todoYmirFolderPath, nyxYmirFolderPath)
    def self.transmuteTodoItemIntoNyxObject(todo, todoYmirFolderPath, nyxYmirFolderPath)
        nyx = {}
        nyx["uuid"] = todo["uuid"]
        nyx["filename"] = todo["filename"]
        nyx["creationTimestamp"] = todo["creationTimestamp"]
        nyx["referenceDateTime"] = Time.new.utc.iso8601
        nyx["description"] = TodoXUtils::editTextUsingTextmate(todo["description"])
        nyx["targets"] = todo["targets"].map{|target| TodoXNyxConverter::transmuteTodoTargetIntoNyxTarget(target, todoYmirFolderPath, nyxYmirFolderPath) }
        tagObjects = TodoXNyxConverter::interactivelymakeZeroOrMoreTags()
                        .map{|tag|
                            {
                                "uuid" => SecureRandom.uuid,
                                "type" => "tag-18303A17",
                                "tag"  => tag
                            }
                        }
        timelineObjects = TodoXNyxConverter::interactivelySelectAtLeastOneTimelinePossiblyNewOne(TodoXNyxConverter::getNyxTimelines())
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

class TodoXWalksCore

    # TodoXWalksCore::walksDataStoreFolderpath()
    def self.walksDataStoreFolderpath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/todo-walks/dataset"
    end

    # TodoXWalksCore::walksSetuuid1()
    def self.walksSetuuid1()
        "CFCD19D8-A904-41C5-AE42-37EFE5ACF733"
    end

    # TodoXWalksCore::timeline2TimeMapping()
    def self.timeline2TimeMapping() # TimeStructure: Map[String # Timeline, Float # Timespan]
        BTreeSets::values(TodoXWalksCore::walksDataStoreFolderpath(), TodoXWalksCore::walksSetuuid1())
            .reduce({}){|mapping, point|
                if mapping[point["timeline"]].nil? then
                    mapping[point["timeline"]] = 0
                end
                mapping[point["timeline"]] = mapping[point["timeline"]] + point["timespan"]
                mapping
            }
    end

    # TodoXWalksCore::get2TNodesTimelines()
    def self.get2TNodesTimelines() # Array[String]
        TodoXEstate::tNodesEnumerator(Todo::pathToYmir())
            .map{|tnode|
                tnode["classification"]
                    .select{|item| item["type"] == "timeline-329D3ABD" }
                    .map{|item| item["timeline"] }
            }
            .flatten
            .uniq
    end

    # TodoXWalksCore::remove2FromDataset1ThePointsWithObsoleteTimelines()
    def self.remove2FromDataset1ThePointsWithObsoleteTimelines()
        datasetTimelines = BTreeSets::values(TodoXWalksCore::walksDataStoreFolderpath(), TodoXWalksCore::walksSetuuid1()).map{|point| point["timeline"] }.uniq
        aliveTimelines = TodoXWalksCore::get2TNodesTimelines()
        deadTimelines = datasetTimelines - aliveTimelines
        BTreeSets::values(TodoXWalksCore::walksDataStoreFolderpath(), TodoXWalksCore::walksSetuuid1()).each{|point|
            if deadTimelines.include?(point["timeline"]) then
                #puts "destroying point:"
                #puts JSON.pretty_generate(point)
                BTreeSets::destroy(TodoXWalksCore::walksDataStoreFolderpath(), TodoXWalksCore::walksSetuuid1(), point["uuid"])
            end
        }
    end

    # TodoXWalksCore::limit2SizeOfDataset1()
    def self.limit2SizeOfDataset1()
        points = BTreeSets::values(TodoXWalksCore::walksDataStoreFolderpath(), TodoXWalksCore::walksSetuuid1())
            .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
        while points.size > 100 do
            point = points.shift
            #puts "destroying point:"
            #puts JSON.pretty_generate(point)
            BTreeSets::destroy(TodoXWalksCore::walksDataStoreFolderpath(), TodoXWalksCore::walksSetuuid1(), point["uuid"])
        end
    end

    # TodoXWalksCore::get2TimelineWithLowestTimespan(timelines, timeStruct)
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

class Todo

    # Todo::pathToYmir()
    def self.pathToYmir()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/Ymir"
    end

    # Todo::pathToTodoInbox()
    def self.pathToTodoInbox()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/Inbox"
    end

    # Todo::todoInboxTimelineName()
    def self.todoInboxTimelineName()
        "[Inbox]"
    end

    # Todo::l22()
    def self.l22()
        Time.new.strftime("%Y%m%d-%H%M%S-%6N")
    end

    # Todo::starburstFolderPathToTodoItemPreserveSource(folderpath1)
    def self.starburstFolderPathToTodoItemPreserveSource(folderpath1)
        return if !File.exists?(folderpath1)
        foldername1 = File.basename(folderpath1)
        targetfoldername = Todo::l22()
        targetfolderpath = YmirEstate::makeNewYmirLocationForBasename(Todo::pathToYmir(), targetfoldername)
        FileUtils.mkpath(targetfolderpath)
        LucilleCore::copyContents(folderpath1, targetfolderpath)
        target = {
            "uuid"       => SecureRandom.uuid,
            "type"       => "perma-dir-11859659",
            "foldername" => targetfoldername
        }
        classificationItem = {
            "uuid"     => SecureRandom.uuid,
            "type"     => "timeline-329D3ABD",
            "timeline" => "[Inbox]"
        }
        tnodeFilename = "#{Todo::l22()}.json"
        tnode = {
            "uuid"              => SecureRandom.uuid,
            "filename"          => tnodeFilename,
            "creationTimestamp" => Time.new.to_f,
            "description"       => foldername1,
            "targets"           => [ target ],
            "classification"    => [ classificationItem ]
        }
        filepath = YmirEstate::makeNewYmirLocationForBasename(Todo::pathToYmir(), tnodeFilename)
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(tnode)) }
    end

end
