#!/usr/bin/ruby

# encoding: UTF-8

require 'find'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'time'

require 'colorize'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
# LucilleCore::askQuestionAnswerAsString(question)
# LucilleCore::askQuestionAnswerAsBoolean(announce, defaultValue = nil)

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

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

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

# --------------------------------------------------------------------

class NyxPermanodeOperator

    # ------------------------------------------
    # Integrity

    # NyxPermanodeOperator::objectIsPermanodeTarget(object)
    def self.objectIsPermanodeTarget(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["type"].nil?
        types = ["lstore-directory-mark-BEE670D0", "unique-name-C2BF46D6", "url-EFB8D55B", "perma-dir-11859659"]
        return false if !types.include?(object["type"])
        if object["type"] == "perma-dir-11859659" then
            return false if object["foldername"].nil?
        end
        true
    end

    # Return true if the passed object is a well formed permanode
    # NyxPermanodeOperator::objectIsPermanode(object)
    def self.objectIsPermanode(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["filename"].nil?
        return false if object["referenceDateTime"].nil?
        return false if DateTime.parse(object["referenceDateTime"]).to_time.utc.iso8601 != object["referenceDateTime"]
        return false if object["description"].nil?
        return false if object["description"].lines.to_a.size != 1
        return false if object["targets"].nil?
        return false if object["targets"].any?{|target| !NyxPermanodeOperator::objectIsPermanodeTarget(target) }
        return false if object["classification"].nil?
        true
    end

    # ------------------------------------------------------------------
    # To Strings

    # NyxPermanodeOperator::permanodeTargetToString(target)
    def self.permanodeTargetToString(target)
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return "mark      : #{target["mark"]}"
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return "uniquename: #{target["name"]}"
        end
        if target["type"] == "url-EFB8D55B" then
            return "url       : #{target["url"]}"
        end
        if target["type"] == "perma-dir-11859659" then
            return "PermaDir  : #{target["uuid"]}"
        end
        raise "[error: f84bb73d]"
    end

    # NyxPermanodeOperator::permanodeClassificationToString(item)
    def self.permanodeClassificationToString(item)
        if item["type"] == "tag-18303A17" then
            return "tag       : #{item["tag"]}"
        end
        if item["type"] == "timeline-329D3ABD" then
            return "timeline  : #{item["timeline"]}"
        end
        raise "[error: 071e4925]"
    end

    # ------------------------------------------
    # Opening

    # NyxPermanodeOperator::openPermanodeTarget(pathToYmir, target)
    def self.openPermanodeTarget(pathToYmir, target)
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(target["mark"])
            if location then
                puts "opening: #{File.dirname(location)}"
                system("open '#{File.dirname(location)}'")
            else
                puts "I could not determine the location of mark: #{target["mark"]}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            location = NyxMiscUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location then
                puts "opening: #{location}"
                system("open '#{location}'")
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "url-EFB8D55B" then
            url = target["url"]
            system("open '#{url}'")
            return
        end
        if target["type"] == "perma-dir-11859659" then
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, target["foldername"])
            if folderpath.nil? then
                puts "[error: dbd35b00] This should not have happened. Cannot find folder for permadir foldername '#{target["foldername"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{folderpath}'")
            return
        end
        raise "[error: 15c46fdd]"
    end

    # ------------------------------------------
    # IO Ops

    # NyxPermanodeOperator::makePermanodeFilename()
    def self.makePermanodeFilename()
        "#{NyxMiscUtils::l22()}.json"
    end

    # NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(pathToYmir, filename)
    def self.permanodeFilenameToFilepathOrNull(pathToYmir, filename)
        YmirEstate::ymirFilepathEnumerator(pathToYmir).each{|filepath|
            return filepath if ( File.basename(filepath) == filename )
        }
        nil
    end

    # NyxPermanodeOperator::destroyPermanode(pathToYmir, permanode)
    def self.destroyPermanode(pathToYmir, permanode)
        filepath = NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(pathToYmir, permanode["filename"])
        puts filepath
        return if filepath.nil?
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NyxPermanodeOperator::commitPermanodeToDisk(pathToYmir, permanode)
    def self.commitPermanodeToDisk(pathToYmir, permanode)
        raise "[error: not a permanode]" if !NyxPermanodeOperator::objectIsPermanode(permanode)
        filepath = NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(pathToYmir, permanode["filename"])
        if filepath.nil? then
            # probably a new permanode 
            filepath = YmirEstate::makeNewYmirLocationForBasename(pathToYmir, permanode["filename"])
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(permanode)) }
    end

    # NyxPermanodeOperator::getPermanodeByUUIDOrNull(pathToYmir, permanodeuuid)
    def self.getPermanodeByUUIDOrNull(pathToYmir, permanodeuuid)
        NyxPermanodeOperator::permanodesEnumerator(pathToYmir).each{|permanode|
            return permanode if ( permanode["uuid"] == permanodeuuid )
        }
        nil
    end

    # NyxPermanodeOperator::permanodesEnumerator(pathToYmir)
    def self.permanodesEnumerator(pathToYmir)
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

    # ------------------------------------------------------------------
    # To Strings

    # NyxPermanodeOperator::printPermanodeDetails(permanode)
    def self.printPermanodeDetails(permanode)
        puts "Permanode:"
        puts "    uuid: #{permanode["uuid"]}"
        puts "    filename: #{permanode["filename"]}"
        puts "    description: #{permanode["description"]}"
        puts "    datetime: #{permanode["referenceDateTime"]}"
        puts "    targets:"
        permanode["targets"].each{|permanodeTarget|
            puts "        #{NyxPermanodeOperator::permanodeTargetToString(permanodeTarget)}"
        }
        if permanode["classification"].empty? then
            puts "    classification: (empty set)"
        else
            puts "    classification"
            permanode["classification"].each{|item|
                puts "        #{NyxPermanodeOperator::permanodeClassificationToString(item)}"
            }
        end
    end

    # ------------------------------------------------------------------
    # Data Queries and Data Manipulations

    # NyxPermanodeOperator::timelines()
    def self.timelines()
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .reduce([]){|timelines, permanode|
                timelines + permanode["classification"].select{|permanodeTarget| permanodeTarget["type"] == "timeline-329D3ABD" }.map{|permanodeTarget| permanodeTarget["timeline"] }
            }
    end

    # NyxPermanodeOperator::timelinesInDecreasingActivityDateTime()
    def self.timelinesInDecreasingActivityDateTime()
        # struct1: Map[Timeline, DateTime]
        struct1 = NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .reduce({}){|datedTimelines, permanode|
                referenceDateTime = permanode["referenceDateTime"]
                timelines = permanode["classification"]
                                .select{|permanodeTarget| permanodeTarget["type"] == "timeline-329D3ABD" }
                                .map{|permanodeTarget| permanodeTarget["timeline"] }
                timelines.each{|timeline|
                    if datedTimelines[timeline].nil? then
                        datedTimelines[timeline] = referenceDateTime
                    else
                        datedTimelines[timeline] = [datedTimelines[timeline], referenceDateTime].max
                    end
                }
                datedTimelines
            }
            .map{|timeline, datetime| [timeline, datetime] }
            .sort{|p1, p2| p1[1]<=>p2[1] }
            .map{|i| i[0] }
            .reverse
    end

    # NyxPermanodeOperator::applyReferenceDateTimeOrderToPermanodes(permanodes)
    def self.applyReferenceDateTimeOrderToPermanodes(permanodes)
        permanodes.sort{|p1, p2| p1["referenceDateTime"] <=> p2["referenceDateTime"] }
    end

    # NyxPermanodeOperator::getTimelinePermanodes(timeline)
    def self.getTimelinePermanodes(timeline)
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .select{|permanode| permanode["classification"].any?{|item| item["type"] == "timeline-329D3ABD" and item["timeline"] == timeline}}
    end

    # NyxPermanodeOperator::getPermanodesCarryingThisDirectoryMark(mark)
    def self.getPermanodesCarryingThisDirectoryMark(mark)
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .select{|permanode|
                permanode["targets"].any?{|target| target["type"] == "lstore-directory-mark-BEE670D0" and target["mark"] == mark }
            }
    end

    # ------------------------------------------------------------------
    # Interactive Makers

    # NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
    def self.makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
        options = ["mark file already exists", "mark file should be created"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "mark file already exists" then
            mark = LucilleCore::askQuestionAnswerAsString("mark: ")
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "lstore-directory-mark-BEE670D0",
                "mark" => mark
            }
        end
        if option == "mark file should be created" then
            mark = nil
            loop {
                targetFolderLocation = LucilleCore::askQuestionAnswerAsString("Location to the target folder: ")
                if !File.exists?(targetFolderLocation) then
                    puts "I can't see location '#{targetFolderLocation}'"
                    puts "Let's try that again..."
                    next
                end
                mark = SecureRandom.uuid
                markFilepath = "#{targetFolderLocation}/Nyx-Directory-Mark.txt"
                File.open(markFilepath, "w"){|f| f.write(mark) }
                break
            }
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "lstore-directory-mark-BEE670D0",
                "mark" => mark
            }
        end
    end

    # NyxPermanodeOperator::selectOneExistingTimelineOrNull()
    def self.selectOneExistingTimelineOrNull()
        timeline = NyxMiscUtils::chooseALinePecoStyle("Timeline", [""] + NyxPermanodeOperator::timelinesInDecreasingActivityDateTime())
        return nil if timeline.size == 0
        timeline
    end

    # NyxPermanodeOperator::makeZeroOrMoreClassificationItemsTags()
    def self.makeZeroOrMoreClassificationItemsTags()
        items = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty for exit): ")
            break if tag.size == 0
            item = {
                "uuid" => SecureRandom.uuid,
                "type" => "tag-18303A17",
                "tag"  => tag
            }
            items << item
        }
        items
    end

    # NyxPermanodeOperator::makeZeroOrMoreClassificationItemsInteractive()
    def self.makeZeroOrMoreClassificationItemsInteractive()
        puts "-> specifiying classification: (1) tags, (2) timeline among existing, (3) new timelines"
        objects = []
        NyxPermanodeOperator::makeZeroOrMoreClassificationItemsTags()
            .each{|item| objects << item }
        loop {
            timeline = NyxPermanodeOperator::selectOneExistingTimelineOrNull()
            break if timeline.nil?
            object = {
                "uuid" => SecureRandom.uuid,
                "type" => "timeline-329D3ABD",
                "timeline"  => timeline
            }
            objects << object
        }
        loop {
            timeline = LucilleCore::askQuestionAnswerAsString("timeline (empty for exit): ")
            break if timeline.size == 0
            object = {
                "uuid" => SecureRandom.uuid,
                "type" => "timeline-329D3ABD",
                "timeline"  => NyxMiscUtils::formatTimeline(timeline)
            }
            objects << object
        }
        objects
    end

    # NyxPermanodeOperator::makePermanodeTargetInteractiveOrNull(type)
    # type = nil | "lstore-directory-mark-BEE670D0" | "unique-name-C2BF46D6" | "url-EFB8D55B"
    def self.makePermanodeTargetInteractiveOrNull(type)
        permanodeTargetType =
            if type.nil? then
                LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["lstore-directory-mark-BEE670D0", "url-EFB8D55B", "unique-name-C2BF46D6", "perma-dir-11859659"])
            else
                type
            end
        return nil if permanodeTargetType.nil?
        if permanodeTargetType == "lstore-directory-mark-BEE670D0" then
            return NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
        end
        if permanodeTargetType == "url-EFB8D55B" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url"  => LucilleCore::askQuestionAnswerAsString("url: ").strip
            }
        end
        if permanodeTargetType == "unique-name-C2BF46D6" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => LucilleCore::askQuestionAnswerAsString("uniquename: ").strip
            }
        end
        if permanodeTargetType == "perma-dir-11859659" then
            foldername1 = LucilleCore::askQuestionAnswerAsString("Desktop foldername: ")
            folderpath1 = "/Users/pascal/Desktop/#{foldername1}"
            foldername2 = NyxMiscUtils::l22()
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(Nyx::pathToYmir(), foldername2)
            FileUtils.mkdir(folderpath2)
            puts "Migrating '#{folderpath1}' to '#{folderpath2}'"
            LucilleCore::migrateContents(folderpath1, folderpath2)
            puts "'#{folderpath1}' has been emptied"
            LucilleCore::pressEnterToContinue()
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
        end
        nil
    end

    # NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
    def self.makePermanode2Interactive(description, permanodeTarget)
        permanode = {}
        permanode["uuid"] = SecureRandom.uuid
        permanode["filename"] = NyxPermanodeOperator::makePermanodeFilename()
        permanode["creationTimestamp"] = Time.new.to_f
        permanode["referenceDateTime"] = Time.now.utc.iso8601
        permanode["description"] = description
        permanode["targets"] = [ permanodeTarget ]
        permanode["classification"] = NyxPermanodeOperator::makeZeroOrMoreClassificationItemsInteractive()
        permanode
    end

    # NyxPermanodeOperator::makePermanodeInteractive()
    def self.makePermanodeInteractive()
        operations = [
            "Desktop files inside permadir",
            "url",
            "uniquename",
            "text file inside permadir",
            "create lstore-directory-mark"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)

        if operation == "create lstore-directory-mark" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            permanodeTarget = NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
            return if permanodeTarget.nil?
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
        end

        if operation == "text file inside permadir" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            text = NyxMiscUtils::editTextUsingTextmate("")
            foldername2 = NyxMiscUtils::l22()
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(Nyx::pathToYmir(), foldername2)
            FileUtils.mkdir(folderpath2)
            filepath3 = "#{folderpath2}/text.txt"
            File.open(filepath3, "w"){|f| f.puts(text) }
            permanodeTarget = {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            system("open '#{folderpath2}'")
        end

        if operation == "url" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            permanodeTarget = {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url" => url
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
        end

        if operation == "uniquename" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            permanodeTarget = {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => uniquename
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
        end

        if operation == "Desktop files inside permadir" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            locations = NyxMiscUtils::selectOneOrMoreFilesOnTheDesktopByLocation()

            foldername2 = NyxMiscUtils::l22()
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(Nyx::pathToYmir(), foldername2)
            FileUtils.mkdir(folderpath2)

            permanodeTarget = {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)

            locations.each{|location|
                puts "Copying '#{location}'"
                LucilleCore::copyFileSystemLocation(location, folderpath2)
            }
            locations.each{|location|
                LucilleCore::removeFileSystemLocation(location)
            }
            system("open '#{folderpath2}'")
        end
    end

    # ------------------------------------------------------------------
    # Dives

    # NyxPermanodeOperator::permanodeTargetDive(permanodeuuid, permanodeTarget)
    def self.permanodeTargetDive(permanodeuuid, permanodeTarget)
        puts "-> permanodeTarget:"
        puts JSON.pretty_generate(permanodeTarget)
        puts NyxPermanodeOperator::permanodeTargetToString(permanodeTarget)
        NyxPermanodeOperator::openPermanodeTarget(Nyx::pathToYmir(), permanodeTarget)
    end

    # NyxPermanodeOperator::permanodeTargetsDive(permanode)
    def self.permanodeTargetsDive(permanode)
        toStringLambda = lambda { |permanodeTarget| NyxPermanodeOperator::permanodeTargetToString(permanodeTarget) }
        permanodeTarget = LucilleCore::selectEntityFromListOfEntitiesOrNull("Choose target", permanode["targets"], toStringLambda)
        return if permanodeTarget.nil?
        NyxPermanodeOperator::permanodeTargetDive(permanode["uuid"], permanodeTarget)
    end

    # NyxPermanodeOperator::permanodeDive(permanode)
    def self.permanodeDive(permanode)
        loop {
            NyxPermanodeOperator::printPermanodeDetails(permanode)
            operations = [
                "edit description",
                "edit reference datetime",
                "targets dive",
                "targets (add new)",
                "targets (select and remove)",
                "tag (add new)",
                "timeline (add new as string)",
                "timeline (add new select from existing)",
                "classification (select and remove)",
                "edit permanode.json",
                "destroy permanode"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "edit description" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                newdescription = NyxMiscUtils::editTextUsingTextmate(permanode["description"]).strip
                if newdescription == "" or newdescription.lines.to_a.size != 1 then
                    puts "Descriptions should have one non empty line"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                permanode["description"] = newdescription
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "edit reference datetime" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                referenceDateTime = NyxMiscUtils::editTextUsingTextmate(permanode["referenceDateTime"]).strip
                if NyxMiscUtils::isProperDateTimeIso8601(referenceDateTime) then
                    permanode["referenceDateTime"] = referenceDateTime
                    NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
                else
                    puts "I could not validate #{referenceDateTime} as a proper iso8601 datetime"
                    puts "Aborting operation"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if operation == "target dive" then
                NyxPermanodeOperator::permanodeTargetDive(permanode["uuid"], permanode["targets"].first)
            end
            if operation == "targets dive" then
                NyxPermanodeOperator::permanodeTargetsDive(permanode)
            end
            if operation == "targets (add new)" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                target = NyxPermanodeOperator::makePermanodeTargetInteractiveOrNull(nil)
                next if target.nil?
                permanode["targets"] << target
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "targets (select and remove)" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                toStringLambda = lambda { |permanodeTarget| NyxPermanodeOperator::permanodeTargetToString(permanodeTarget) }
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", permanode["targets"], toStringLambda)
                next if target.nil?
                permanode["targets"] = permanode["targets"].reject{|t| t["uuid"]==target["uuid"] }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "tag (add new)" then
                tag = LucilleCore::askQuestionAnswerAsString("tag: ")
                next if tag.size == 0
                permanode["classification"] << {
                    "uuid" => SecureRandom.uuid,
                    "type" => "tag-18303A17",
                    "tag"  => tag
                }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "timeline (add new as string)" then
                timeline = LucilleCore::askQuestionAnswerAsString("timeline: ")
                next if timeline.size == 0
                permanode["classification"] << {
                    "uuid"     => SecureRandom.uuid,
                    "type"     => "timeline-329D3ABD",
                    "timeline" => timeline
                }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "timeline (add new select from existing)" then
                timeline = NyxPermanodeOperator::selectOneExistingTimelineOrNull()
                next if timeline.nil?
                permanode["classification"] << {
                    "uuid"     => SecureRandom.uuid,
                    "type"     => "timeline-329D3ABD",
                    "timeline" => timeline
                }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "classification (select and remove)" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("classification", permanode["classification"], lambda{|item| NyxPermanodeOperator::permanodeClassificationToString(item) } )
                next if item.nil?
                permanode["classification"] = permanode["classification"].reject{|i| i["uuid"]==item["uuid"] }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "edit permanode.json" then
                permanodeFilepath = NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(Nyx::pathToYmir(), permanode["filename"])
                if permanodeFilepath.nil? then
                    puts "Strangely I could not find the filepath for this:"
                    puts JSON.pretty_generate(permanode)
                    LucilleCore::pressEnterToContinue()
                    next
                end
                puts "permanode filepath: #{permanodeFilepath}"
                permanodeAsJSONString = NyxMiscUtils::editTextUsingTextmate(JSON.pretty_generate(JSON.parse(IO.read(permanodeFilepath))))
                permanode = JSON.parse(permanodeAsJSONString)
                if !NyxPermanodeOperator::objectIsPermanode(permanode) then
                    puts "I do not recognise the new object as a permanode. Aborting operation."
                    next
                end
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "destroy permanode" then
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanode["uuid"])
                    return
                end
            end
        }
    end

    # NyxPermanodeOperator::permanodeOpen(permanode)
    def self.permanodeOpen(permanode)
        NyxPermanodeOperator::printPermanodeDetails(permanode)
        puts "    -> Opening..."
        if permanode["targets"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find target for this permanode. Dive? ") then
                NyxPermanodeOperator::permanodeDive(permanode)
            end
            return
        end
        target = nil
        if permanode["targets"].size == 1 then
            target = permanode["targets"].first
        else
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target:", permanode["targets"], lambda{|target| NyxPermanodeOperator::permanodeTargetToString(target) })
        end
        puts JSON.pretty_generate(target)
        NyxPermanodeOperator::openPermanodeTarget(Nyx::pathToYmir(), target)
    end

    # ------------------------------------------------------------------
    # Destroy

    # NyxPermanodeOperator::destroyClassificationItem(item)
    def self.destroyClassificationItem(item)
        # Honorific
        return
    end

    # NyxPermanodeOperator::destroyPermanodeTargetAttempt(target)
    def self.destroyPermanodeTargetAttempt(target)
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(target["mark"])
            return if location.nil?
            if NyxPermanodeOperator::getPermanodesCarryingThisDirectoryMark(target["mark"]).size == 1 then
                puts "destroying mark file: #{location}"
                LucilleCore::removeFileSystemLocation(location)
            end
            return
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            return
        end
        if target["type"] == "url-EFB8D55B" then
            url = target["url"]
            return
        end
        if target["type"] == "perma-dir-11859659" then
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(Nyx::pathToYmir(), target["foldername"])
            return if folderpath.nil?
            LucilleCore::removeFileSystemLocation(folderpath)
            return
        end
        raise "[error: 15c46fdd]"
    end

    # NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
    def self.destroyPermanodeAttempt(permanode)
        permanode["targets"].all?{|target| NyxPermanodeOperator::destroyPermanodeTargetAttempt(target) }
        permanode["classification"].all?{|item| NyxPermanodeOperator::destroyClassificationItem(item) }
        NyxPermanodeOperator::destroyPermanode(Nyx::pathToYmir(), permanode)
        NyxMiscUtils::publishIndex2PermanodesAsOneObject()
    end

    # NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanodeuuid)
    def self.destroyPermanodeContentsAndPermanode(permanodeuuid)
        permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanodeuuid)
        return if permanode.nil?
        NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
        NyxMiscUtils::publishIndex2PermanodesAsOneObject()
    end

end
