
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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, "SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

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

# --------------------------------------------------------------------

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

    # TodoXUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
    def self.uniqueNameResolutionLocationPathOrNull(uniquename)
        location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
        return nil if location.nil?
        location
    end

    # TodoXUtils::newBinArchivesFolderpath()
    def self.newBinArchivesFolderpath()
        time = Time.new
        folder1 = "/Users/pascal/Galaxy/DataBank/Catalyst/Bin-Timeline/#{time.strftime("%Y")}/#{time.strftime("%Y-%m")}/#{time.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(folder3)
        folder3
    end

    # TodoXUtils::copyLocationToCatalystBin(location)
    def self.copyLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        targetFolder = TodoXUtils::newBinArchivesFolderpath()
        LucilleCore::copyFileSystemLocation(location,targetFolder)
    end

    # TodoXUtils::selectOneOrMoreFilesOnTheDesktopByLocation()
    def self.selectOneOrMoreFilesOnTheDesktopByLocation() # Array[String]
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1]!='.' }
                            .sort
        puts "Select files:"
        locations, _ = LucilleCore::selectZeroOrMore("files:", [], desktopLocations, lambda{ |location| File.basename(location) })
        locations
    end

    # TodoXUtils::pathToItems()
    def self.pathToItems()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/Items"
    end

    # TodoXUtils::l22()
    def self.l22()
        Time.new.strftime("%Y%m%d-%H%M%S-%6N")
    end
end

class TodoXSoniaAionOperator

    def initialize(zetafilepath)
        @zetafilepath = zetafilepath
    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        Zeta::set(@zetafilepath, nhash, blob)
        nhash
    end

    def filepathToHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = Zeta::getOrNull(@zetafilepath, nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

class TodoXEstate

    # ------------------------------------------
    # Integrity

    # TodoXEstate::objectIsTNodeTarget(object)
    def self.objectIsTNodeTarget(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["type"].nil?
        types = [
            "url-EFB8D55B",
            "line-2A35BA23",
            "text-A9C3641C",
            "unique-name-C2BF46D6",
            "lstore-directory-mark-BEE670D0",
            "perma-dir-11859659",
        ]
        return false if !types.include?(object["type"])
        if object["type"] == "perma-dir-11859659" then
            return false if object["zetaKey"].nil?
        end
        if object["type"] == "text-A9C3641C" then
            return false if object["zetaKey"].nil?
        end
        true
    end

    # Return true if the passed object is a well formed TNode
    # TodoXEstate::objectIsTNode(object)
    def self.objectIsTNode(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["filename"].nil?
        return false if object["description"].nil?
        return false if object["description"].lines.to_a.size != 1
        return false if object["target"].nil?
        return false if !TodoXEstate::objectIsTNodeTarget(object["target"])
        return false if object["timeline"].nil?
        true
    end

    # ------------------------------------------
    # IO Ops (0)

    # TodoXEstate::repositoryFilenameToFilepath(filename)
    def self.repositoryFilenameToFilepath(filename)
        "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/Items/#{filename}"
    end

    # ------------------------------------------
    # IO Ops (1)

    # TodoXEstate::dumpTNodeIntoNewZetaFile(tnode)
    def self.dumpTNodeIntoNewZetaFile(tnode)
        filepath = TodoXEstate::repositoryFilenameToFilepath(tnode["filename"])
        Zeta::makeNewFile(filepath)
        Zeta::set(filepath, "uuid", tnode["uuid"])
        Zeta::set(filepath, "filename", tnode["filename"])
        Zeta::set(filepath, "creationTimestamp", tnode["creationTimestamp"])
        Zeta::set(filepath, "description", tnode["description"])
        Zeta::set(filepath, "target", JSON.generate(tnode["target"]))
        Zeta::set(filepath, "timeline", tnode["timeline"])
    end

    # TodoXEstate::dumpTNodeIntoExistingZetaFile(tnode)
    def self.dumpTNodeIntoExistingZetaFile(tnode)
        filepath = TodoXEstate::repositoryFilenameToFilepath(tnode["filename"])
        Zeta::set(filepath, "uuid", tnode["uuid"])
        Zeta::set(filepath, "filename", tnode["filename"])
        Zeta::set(filepath, "creationTimestamp", tnode["creationTimestamp"])
        Zeta::set(filepath, "description", tnode["description"])
        Zeta::set(filepath, "target", JSON.generate(tnode["target"]))
        Zeta::set(filepath, "timeline", tnode["timeline"])
    end

    # TodoXEstate::readZetaFileIntoTNode(filepath)
    def self.readZetaFileIntoTNode(filepath)
        tnode = {}
        tnode["uuid"] = Zeta::getOrNull(filepath, "uuid")
        tnode["filename"] = Zeta::getOrNull(filepath, "filename")
        tnode["creationTimestamp"] = Zeta::getOrNull(filepath, "creationTimestamp")
        tnode["description"] = Zeta::getOrNull(filepath, "description")
        tnode["target"] = JSON.parse(Zeta::getOrNull(filepath, "target"))
        tnode["timeline"] = Zeta::getOrNull(filepath, "timeline")
        tnode
    end

    # TodoXEstate::tNodesEnumeratorReadZetaFiles()
    def self.tNodesEnumeratorReadZetaFiles()
        filepaths = Dir.entries(TodoXUtils::pathToItems())
            .select{|filename| filename[-5, 5] == ".zeta" }
            .map{|filename| TodoXEstate::repositoryFilenameToFilepath(filename) }
        Enumerator.new do |tnodes|
            filepaths.each{|filepath|
                tnodes << TodoXEstate::readTNodeFromDisk(filepath)
            }
        end
    end

    # TodoXEstate::getTNodeByUUIDOrNullReadZetaFiles(uuid)
    def self.getTNodeByUUIDOrNullReadZetaFiles(uuid)
        TodoXEstate::tNodesEnumeratorReadZetaFiles()
            .each{|tnode| 
                if tnode["uuid"] == uuid then
                    return tnode
                end
            }
        nil
    end

    # ------------------------------------------
    # IO Ops (2)

    # TodoXEstate::firstTimeCommitTNodeToDisk(tnode)
    def self.firstTimeCommitTNodeToDisk(tnode)
        TodoXEstate::dumpTNodeIntoNewZetaFile(tnode)
        BTreeSets::set(nil, "dc533635-864f-4409-a888-14bfe872bc6d", tnode["uuid"], tnode)
    end

    # TodoXEstate::reCommitTNodeToDisk(tnode)
    def self.reCommitTNodeToDisk(tnode)
        TodoXEstate::dumpTNodeIntoExistingZetaFile(tnode)
        BTreeSets::set(nil, "dc533635-864f-4409-a888-14bfe872bc6d", tnode["uuid"], tnode)
    end

    # TodoXEstate::readTNodeFromDisk(filepath)
    def self.readTNodeFromDisk(filepath)
        TodoXEstate::readZetaFileIntoTNode(filepath)
    end

    # TodoXEstate::getTNodes()
    def self.getTNodes()
        BTreeSets::values(nil, "dc533635-864f-4409-a888-14bfe872bc6d")
    end

    # TodoXEstate::getTNodeByUUIDOrNull(uuid)
    def self.getTNodeByUUIDOrNull(uuid)
        BTreeSets::getOrNull(nil, "dc533635-864f-4409-a888-14bfe872bc6d", uuid)
    end

    # TodoXEstate::rebuildTNodesIndex()
    def self.rebuildTNodesIndex()
        BTreeSets::values(nil, "dc533635-864f-4409-a888-14bfe872bc6d")
        .each{|value|
            puts "removing: #{value["uuid"]}"
            BTreeSets::destroy(nil, "dc533635-864f-4409-a888-14bfe872bc6d", value["uuid"])
        }
        TodoXEstate::tNodesEnumeratorReadZetaFiles()
        .each{|tnode|
            puts "adding: #{tnode["uuid"]}"
            BTreeSets::set(nil, "dc533635-864f-4409-a888-14bfe872bc6d", tnode["uuid"], tnode)
        }
    end

    # TodoXEstate::tnodeUUIDToTNodeFilepathOrNull(tnodeuuid)
    def self.tnodeUUIDToTNodeFilepathOrNull(tnodeuuid)
        tnode = TodoXEstate::getTNodeByUUIDOrNull(tnodeuuid)
        return nil if tnode.nil?
        tnodefilename = tnode["filename"]
        TodoXEstate::repositoryFilenameToFilepath(tnodefilename)
    end

    # ------------------------------------------
    # IO Ops (3)

    # TodoXEstate::setKVAtZetaFileIdentifiedByTNodeUUID(uuid, key, value)
    def self.setKVAtZetaFileIdentifiedByTNodeUUID(uuid, key, value)
        tnode = TodoXEstate::getTNodeByUUIDOrNull(uuid)
        return if tnode.nil?
        filename = tnode["filename"]
        filepath = TodoXEstate::repositoryFilenameToFilepath(filename)
        return if filepath.nil?
        Zeta::set(filepath, key, value)
    end

    # TodoXEstate::getVAtZetaFileIdentifiedByTNodeUUIDOrNull(uuid, key)
    def self.getVAtZetaFileIdentifiedByTNodeUUIDOrNull(uuid, key)
        tnode = TodoXEstate::getTNodeByUUIDOrNull(uuid)
        return nil if tnode.nil?
        filename = tnode["filename"]
        filepath = TodoXEstate::repositoryFilenameToFilepath(filename)
        return nil if filepath.nil?
        Zeta::getOrNull(filepath, key)
    end

    # ------------------------------------------
    # Destroy TNodes

    # TodoXEstate::destroyTNode(tnode)
    def self.destroyTNode(tnode)
        # We try and preserve contents

        destroyTarget = lambda{|target|
            if target["type"] == "line-2A35BA23" then
                # Nothing
                return
            end
            if target["type"] == "text-A9C3641C" then
                # Nothing, the text is carried by the zeta file
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
                # Nothing, the data is carried by the zeta file
                return
            end
            raise "[error: e838105]"
        }

        destroyTarget.call(tnode["target"])

        tnodelocation = TodoXEstate::repositoryFilenameToFilepath(tnode["filename"])
        if tnodelocation.nil? then
            puts "[warning: 82d400d0] Interesting. This should not have hapenned."
            LucilleCore::pressEnterToContinue()
            return
        end
        TodoXUtils::copyLocationToCatalystBin(tnodelocation)
        LucilleCore::removeFileSystemLocation(tnodelocation)

        BTreeSets::destroy(nil, "dc533635-864f-4409-a888-14bfe872bc6d", tnode["uuid"])
    end

    # ------------------------------------------
    # Externals

    # TodoXEstate::pathToNyxYmir()
    def self.pathToNyxYmir()
        `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/nyx-path-to-Ymir`.strip
    end
end

class TodoXCoreData

    # TodoXCoreData::timelines()
    def self.timelines()
        TodoXEstate::getTNodes()
            .map{|tnode| tnode["timeline"] }
            .uniq
    end

    # TodoXCoreData::timelinesInIncreasingActivityTime()
    def self.timelinesInIncreasingActivityTime()
        map1 = TodoXEstate::getTNodes().reduce({}){|acc, tnode|
            timeline = tnode["timeline"]
            if acc[timeline].nil? then
                acc[timeline] = tnode["creationTimestamp"]
            else
                acc[timeline] = [acc[timeline], tnode["creationTimestamp"]].max
            end
            acc
        }
        map1
            .to_a
            .sort{|p1, p2| p1[1]<=>p2[1] }
            .map{|pair| pair[0] }
    end

    # TodoXCoreData::tNodeIsOnThisTimeline(tnode, timeline)
    def self.tNodeIsOnThisTimeline(tnode, timeline)
        tnode["timeline"] == timeline
    end

    # TodoXCoreData::getTimelineTNodesOrdered(tnodes, timeline)
    def self.getTimelineTNodesOrdered(tnodes, timeline)
        tnodes
            .select{|tnode| TodoXCoreData::tNodeIsOnThisTimeline(tnode, timeline) }
            .sort{|tn1, tn2| tn1["creationTimestamp"] <=> tn2["creationTimestamp"] }
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

    # TodoXTMakers::dummyTarget()
    def self.dummyTarget()
        {
            "uuid" => SecureRandom.uuid,
            "type" => "line-2A35BA23",
            "line" => "[dummy]"
        }
    end

    # TodoXTMakers::makeTNodeTargetPermadirUsingSourceDirectory(tnodeuuid, sourcefolderpath)
    def self.makeTNodeTargetPermadirUsingSourceDirectory(tnodeuuid, sourcefolderpath)
        tnodefilepath = TodoXEstate::tnodeUUIDToTNodeFilepathOrNull(tnodeuuid)
        return nil if tnodefilepath.nil?
        operator = TodoXSoniaAionOperator.new(tnodefilepath)
        nhash = AionCore::commitLocationReturnHash(operator, sourcefolderpath)
        zetaKey = SecureRandom.uuid
        TodoXEstate::setKVAtZetaFileIdentifiedByTNodeUUID(tnodeuuid, zetaKey, nhash)
        return {
            "uuid"    => SecureRandom.uuid,
            "type"    => "perma-dir-11859659",
            "zetaKey" => zetaKey
        }
    end

    # TodoXTMakers::makeTNodeTargetPermadirByCollectingFilesOnDesktopOrNull(tnodeuuid)
    def self.makeTNodeTargetPermadirByCollectingFilesOnDesktopOrNull(tnodeuuid)
        desktoplocations = TodoXUtils::selectOneOrMoreFilesOnTheDesktopByLocation()
        return nil if desktoplocations.empty?
        temporaryfoldername = "collected-files-#{TodoXUtils::l22()}"
        temporaryfolderpath = "/Users/pascal/Desktop/#{temporaryfoldername}"
        FileUtils.mkdir(temporaryfolderpath)
        desktoplocations.each{|loc|
            LucilleCore::copyFileSystemLocation(loc, temporaryfolderpath)
            LucilleCore::removeFileSystemLocation(loc)
        }
        target = TodoXTMakers::makeTNodeTargetPermadirUsingSourceDirectory(tnodeuuid, temporaryfolderpath)
        LucilleCore::removeFileSystemLocation(temporaryfolderpath)
        return target
    end

    # TodoXTMakers::makeTNodeTargetInteractivelyOrNull(tnodeuuid)
    def self.makeTNodeTargetInteractivelyOrNull(tnodeuuid)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", [
            "line", 
            "text", 
            "url", 
            "unique name", 
            "permadir (by copying existing directory)",
            "permadir (by collecting files on Desktop)"
        ])
        return nil if type.nil?
        if type == "line" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "line-2A35BA23",
                "line" => LucilleCore::askQuestionAnswerAsString("line: ")
            }
        end
        if type == "text" then
            text = TodoXUtils::editTextUsingTextmate("")
            zetaKey = SecureRandom.uuid
            TodoXEstate::setKVAtZetaFileIdentifiedByTNodeUUID(tnodeuuid, zetaKey, text)
            return {
                "uuid"    => SecureRandom.uuid,
                "type"    => "text-A9C3641C",
                "zetaKey" => zetaKey
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
        if type == "permadir (by copying existing directory)" then
            sourcefolderpath = LucilleCore::askQuestionAnswerAsString("location: ")
            return nil if !File.exist?(sourcefolderpath)
            return TodoXTMakers::makeTNodeTargetPermadirUsingSourceDirectory(tnodeuuid, sourcefolderpath)
        end
        if type == "permadir (by collecting files on Desktop)" then
            return TodoXTMakers::makeTNodeTargetPermadirByCollectingFilesOnDesktopOrNull(tnodeuuid)
        end
    end

    # TodoXTMakers::makeOneTNodeTarget(tnodeuuid)
    def self.makeOneTNodeTarget(tnodeuuid)
        loop {
            target = TodoXTMakers::makeTNodeTargetInteractivelyOrNull(tnodeuuid)
            return target if target
        }
    end

    # TodoXTMakers::makeNewTNode()
    def self.makeNewTNode()
        uuid = SecureRandom.uuid
        # we are not setting tags for TNodes
        tnode = {
            "uuid"              => uuid,
            "filename"          => "#{TodoXUtils::l22()}.zeta",
            "creationTimestamp" => Time.new.to_f,
            "description"       => "",
            "target"            => TodoXEstate::dummyTarget(),
            "timeline"          => "[Inbox]"
        }
        puts JSON.pretty_generate(tnode)
        TodoXEstate::firstTimeCommitTNodeToDisk(tnode)

        # ---------------------------------------------------------------
        # We can only create the target after the tnode has been commited
        # to disk because some targets require the zeta file to already
        # exist in order to be created since the data is stored inside the
        # zeta file.

        # We used to create the timeline above, but we are now doing 
        # it afer for a more natural workflow.
        # --------------------------------------------------------------

        tnode["target"] = TodoXTMakers::makeOneTNodeTarget(uuid)

        tnode["description"] = TodoXUserInterface::targetToString(target) 
        tnode["timeline"] = TodoXTMakers::interactively2SelectOneTimelinePossiblyNew(TodoXCoreData::timelinesInIncreasingActivityTime().reverse)

        TodoXEstate::reCommitTNodeToDisk(tnode)
    end
end

class TodoXNyxConverter
    # As it says on the tin, this class has the tools to convert a todo item into a Nyx item

    # TodoXNyxConverter::transmuteTodoTargetIntoNyxTarget(tnodeuuid, target, nyxYmirFolderPath)
    def self.transmuteTodoTargetIntoNyxTarget(tnodeuuid, target, nyxYmirFolderPath)
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
            raise "[error 1d933f03: not implemented yet]"
        end
        if target["type"] == "text-A9C3641C" then
            text = TodoXEstate::getVAtZetaFileIdentifiedByTNodeUUIDOrNull(tnodeuuid, target["zetaKey"])
            foldername2 = TodoXUtils::l22()
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(nyxYmirFolderPath, foldername2)
            FileUtils.mkdir(folderpath2)
            File.open("#{folderpath2}/text.txt", "w"){|f| f.puts(text) }
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

    # TodoXNyxConverter::makePermanodeTaxonomyInteractive()
    def self.makePermanodeTaxonomyInteractive()
        taxonomy = []
        loop {
            item = LucilleCore::askQuestionAnswerAsString("Node or Edge (empty to quit): ")
            break if item == ""
            taxonomy << item
        }
        taxonomy
    end

    # TodoXNyxConverter::transmuteTodoItemIntoNyxObject(todo, nyxYmirFolderPath)
    def self.transmuteTodoItemIntoNyxObject(todo, nyxYmirFolderPath)
        nyx = {}
        nyx["uuid"] = todo["uuid"]
        nyx["filename"] = todo["filename"]
        nyx["creationTimestamp"] = todo["creationTimestamp"]
        nyx["referenceDateTime"] = Time.new.utc.iso8601
        nyx["description"] = TodoXUtils::editTextUsingTextmate(todo["description"])
        nyx["targets"] = [ TodoXNyxConverter::transmuteTodoTargetIntoNyxTarget(todo["uuid"], todo["target"], nyxYmirFolderPath) ] 
        nyx["taxonomy"] = TodoXNyxConverter::makePermanodeTaxonomyInteractive()
        nyx
    end
end

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

    # TodoXWalksCore::get3TNodesTimelines(tnodes)
    def self.get3TNodesTimelines(tnodes) # Array[String]
        tnodes
            .map{|tnode| tnode["timeline"] }
            .uniq
    end

    # TodoXWalksCore::remove2FromDataset1ThePointsWithObsoleteTimelines()
    def self.remove2FromDataset1ThePointsWithObsoleteTimelines()
        datasetTimelines = BTreeSets::values(TodoXWalksCore::walksDataStoreFolderpath(), TodoXWalksCore::walksSetuuid1()).map{|point| point["timeline"] }.uniq
        aliveTimelines = TodoXWalksCore::get3TNodesTimelines(TodoXEstate::getTNodes())
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

    # TodoXWalksCore::getTimelineWithLowestTimespan(timelines, timeStruct)
    def self.getTimelineWithLowestTimespan(timelines, timeStruct)
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

    # TodoXWalksCore::issuePoint(timeline, timespan)
    def self.issuePoint(timeline, timespan)
        point = {
            "uuid"     => SecureRandom.uuid,
            "unixtime" => Time.new.to_i,
            "timeline" => timeline,
            "timespan" => timespan
        }
        BTreeSets::set(TodoXWalksCore::walksDataStoreFolderpath(), TodoXWalksCore::walksSetuuid1(), point["uuid"], point)
    end
end

class TodoRunsUtils

    # TodoRunsUtils::getRunStatus(todouuid)
    def self.getRunStatus(todouuid) # unixtime or null
        value = KeyValueStore::getOrNull(nil, "3f48e9d0-eb12-45c4-ab63-c1a27863f969:#{todouuid}")
        return nil if value.nil?
        value.to_i
    end

    # TodoRunsUtils::startTodo(todouuid)
    def self.startTodo(todouuid)
        status = TodoRunsUtils::getRunStatus(todouuid)
        return if status # already running
        KeyValueStore::set(nil, "3f48e9d0-eb12-45c4-ab63-c1a27863f969:#{todouuid}", Time.new.to_i)
    end

    # TodoRunsUtils::stopTodo(todouuid)
    def self.stopTodo(todouuid) # nil or unixtime
        tnode = TodoXEstate::getTNodeByUUIDOrNull(todouuid)
        return if tnode.nil?
        status = TodoRunsUtils::getRunStatus(todouuid)
        return if status.nil? # not running
        timespan = Time.new.to_i - status.to_i
        TodoXWalksCore::issuePoint(tnode["timeline"], timespan)
        KeyValueStore::destroy(nil, "3f48e9d0-eb12-45c4-ab63-c1a27863f969:#{todouuid}")
    end

    # TodoRunsUtils::isRunning(todouuid)
    def self.isRunning(todouuid)
        !TodoRunsUtils::getRunStatus(todouuid).nil?
    end
end

class TodoXUserInterface

    # TodoXUserInterface::recastTNodeIdentifiedByUUID(uuid)
    def self.recastTNodeIdentifiedByUUID(uuid)
        tnode = TodoXEstate::getTNodeByUUIDOrNull(uuid)
        return if tnode.nil?
        puts TodoXUserInterface::targetToString(tnode["target"])
        tnode["timeline"] = TodoXTMakers::interactively2SelectOneTimelinePossiblyNew(TodoXCoreData::timelinesInIncreasingActivityTime().reverse)
        puts JSON.pretty_generate(tnode)
        TodoXEstate::reCommitTNodeToDisk(tnode)
    end

    # TodoXUserInterface::targetToString(target)
    def self.targetToString(target)
        if target["type"] == "line-2A35BA23" then
            return "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            return "text"
        end
        if target["type"] == "url-EFB8D55B" then
            return "url: #{target["url"]}"
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return "unique name: #{target["name"]}"
        end
        if target["type"] == "perma-dir-11859659" then
            return "permadir"
        end
        raise "[error: 706ce2f5]"
    end

    # TodoXUserInterface::optimizedOpenTarget(tnodeuuid, target)
    def self.optimizedOpenTarget(tnodeuuid, target)
        if target["type"] == "line-2A35BA23" then
            puts "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            text = TodoXEstate::getVAtZetaFileIdentifiedByTNodeUUIDOrNull(tnodeuuid, target["zetaKey"])
            text = TodoXUtils::editTextUsingTextmate(text)
        end
        if target["type"] == "url-EFB8D55B" then
            system("open '#{target["url"]}'")
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            location = TodoXUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location.nil? then
                puts "I could not resolve unique name '#{uniquename}'"
                LucilleCore::pressEnterToContinue()
            else
                system("open '#{location}'")
            end
        end
        if target["type"] == "perma-dir-11859659" then
            nhash = TodoXEstate::getVAtZetaFileIdentifiedByTNodeUUIDOrNull(tnodeuuid, target["zetaKey"])
            return if nhash.nil?

            # We need to export the location to the Desktop
            tmpfilename = TodoXUtils::l22()
            tmpfoldername = "/Users/pascal/Desktop/#{tmpfilename}"
            FileUtils.mkdir(tmpfoldername)

            tnodefilepath = TodoXEstate::tnodeUUIDToTNodeFilepathOrNull(tnodeuuid)
            operator = TodoXSoniaAionOperator.new(tnodefilepath)
            AionCore::exportHashAtFolder(operator, nhash, tmpfoldername)

            system("open '#{tmpfoldername}'")

            puts "Exported at #{tmpfoldername}"
            LucilleCore::pressEnterToContinue()
        end
    end

    # TodoXUserInterface::getIFCSItems()
    def self.getIFCSItems()
        JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-items`)
    end

    # TodoXUserInterface::tNodeDive(tnodeuuid)
    def self.tNodeDive(tnodeuuid)
        loop {
            tnode = TodoXEstate::getTNodeByUUIDOrNull(tnodeuuid)
            if tnode.nil? then
                raise "[error: a151f422] tnodeuuid: #{tnodeuuid}"
            end
            puts "tnode:"
            puts "    uuid: #{tnode["uuid"]}"
            puts "    filename: #{tnode["filename"]}"
            puts "    description: #{tnode["description"]}"
            puts "    target: #{TodoXUserInterface::targetToString(target)}"
            puts "    timeline: #{tnode["timeline"]}"
            puts "    isRunning: #{TodoRunsUtils::isRunning(tnodeuuid)}"
            operations = [
                "quick open",
                "edit description",
                "recast",
                "publish as in flight control system item",
                "start",
                "stop",
                "done"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "quick open" then
                TodoXUserInterface::optimizedOpenTarget(tnode["uuid"], tnode["target"])
            end
            if operation == "edit description" then
                tnode["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
                TodoXEstate::reCommitTNodeToDisk(tnode)
            end
            if operation == "recast" then
                TodoXUserInterface::recastTNodeIdentifiedByUUID(tnodeuuid)
            end
            if operation == "publish as in flight control system item" then
                puts "Existing In Flight Control System items:"
                TodoXUserInterface::getIFCSItems()
                    .sort{|i1, i2| i1["position"] <=> i2["position"] }
                    .each{|item|
                        puts "    (#{"%5.3f" % item["position"]}) #{item["description"]}"
                    }
                uuid = SecureRandom.uuid
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                item = {
                  "uuid"        => uuid,
                  "description" => "Todo: #{tnode["description"]}",
                  "position"    => position,
                  "activation"  => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/start-tnode '#{tnode["uuid"]}'"
                }
                filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/items/#{uuid}.json"
                File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
                puts "Published new ifcs item:"
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end
            if operation == "start" then
                TodoRunsUtils::startTodo(tnodeuuid)
            end
            if operation == "stop" then
                TodoRunsUtils::stopTodo(tnodeuuid)
            end
            if operation == "done" then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item? ") then
                    TodoXEstate::destroyTNode(tnode)
                    return
                end
            end
        }
    end

    # TodoXUserInterface::tnodesDiveWithNodeSelector(nodeselector)
    def self.tnodesDiveWithNodeSelector(nodeselector)
        loop {
            tnodes = nodeselector.call()
            tnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("tnode: ", tnodes, lambda{|tnode| tnode["description"] })
            return if tnode.nil?
            TodoXUserInterface::tNodeDive(tnode["uuid"])
        }
    end

    # TodoXUserInterface::timelineDive(timeline)
    def self.timelineDive(timeline)
        TodoXUserInterface::tnodesDiveWithNodeSelector(lambda { TodoXCoreData::getTimelineTNodesOrdered(TodoXEstate::getTNodes(), timeline) })
    end

    # TodoXUserInterface::timelinesDive()
    def self.timelinesDive()
        loop {
            timeline = TodoXTMakers::interactively2SelectTimelineOrNull(TodoXCoreData::timelinesInIncreasingActivityTime().reverse)
            return if timeline.nil?
            TodoXUserInterface::timelineDive(timeline)
        }
    end

    # TodoXUserInterface::runTNode(tnode)
    def self.runTNode(tnode) # "continue", "exit"
        operationWithSpecifiedDefault = lambda {|default|
            operation = LucilleCore::askQuestionAnswerAsString("operation: (open, dive, done, next, exit) [default: #{default}]: ")
            if operation == "" then
                default
            else
                operation
            end
        }
        default = "open"
        loop {
            puts ""
            puts "-> #{tnode["description"]}"
            operation = operationWithSpecifiedDefault.call(default)
            if operation == "open" then
                TodoXUserInterface::optimizedOpenTarget(tnode["uuid"], tnode["target"])
                default = "done"
            end
            if operation == "dive" then
                TodoXUserInterface::tNodeDive(tnode["uuid"])
                default = "open"
            end
            if operation == "next" then
                return "continue"
            end
            if operation == "done" then
                TodoXEstate::destroyTNode(tnode)
                return "continue"
            end
            if operation == "exit" then
                return "exit"
            end
        }
    end

    # TodoXUserInterface::timelineWalk(timeline)
    def self.timelineWalk(timeline)
        tnodes = TodoXCoreData::getTimelineTNodesOrdered(TodoXEstate::getTNodes(), timeline)
        loop {
            tnode = tnodes.shift
            startTime = Time.new.to_i
            status = TodoXUserInterface::runTNode(tnode)
            TodoXWalksCore::issuePoint(timeline, Time.new.to_i - startTime)
            return if status == "exit"
        }
    end

    # TodoXUserInterface::ui()
    def self.ui()
        loop {
            system("clear")
            puts "Todo 🗃️"
            operations = [
                "make new item",
                "latest todos",
                "timelines dive",
                "timelines walk",
                "numbers",
                "rebuild index"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "make new item" then
                TodoXTMakers::makeNewTNode()
            end
            if operation == "latest todos" then
                nodeselector = lambda { TodoXEstate::getTNodes().sort{|t1, t2| t1["creationTimestamp"] <=> t2["creationTimestamp"] }.reverse.first(20) }
                TodoXUserInterface::tnodesDiveWithNodeSelector(nodeselector)
            end
            if operation == "timelines dive" then
                TodoXUserInterface::timelinesDive()
            end
            if operation == "timelines walk" then
                timeline = TodoXTMakers::interactively2SelectTimelineOrNull(TodoXCoreData::timelinesInIncreasingActivityTime().reverse)
                next if timeline.nil?
                TodoXUserInterface::timelineWalk(timeline)
            end
            if operation == "numbers" then
                puts "timeline mapping:"
                timeStruct = TodoXWalksCore::timeline2TimeMapping()
                TodoXWalksCore::get3TNodesTimelines(TodoXEstate::getTNodes()).each{|timeline|
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
            if operation == "rebuild index" then
                TodoXEstate::rebuildTNodesIndex()
            end
        }
    end
end
