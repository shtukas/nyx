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

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(5) #=> "eb693"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

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

# --------------------------------------------------------------------

class NyxUserInterface

    # ------------------------------------------
    # Workflows

    # NyxUserInterface::permanodesDive(permanodes)
    def self.permanodesDive(permanodes)
        loop {
            permanode = NyxUserInterface::selectPermanodeOrNull(permanodes)
            break if permanode.nil?
            NyxPermanodeOperator::permanodeDive(permanode)
        }
    end

    # NyxUserInterface::searchDive(searchPattern)
    def self.searchDive(searchPattern)
        loop {
            scorePackets = NyxSearch::searchPatternToScorePacketsInDecreasingScore(searchPattern).select{|scorePacket| scorePacket["score"] > 0 }
            scorePacket = NyxUserInterface::selectScorePacketOrNull(scorePackets)
            break if scorePacket.nil?
            NyxPermanodeOperator::permanodeDive(scorePacket["permanode"])
        }
    end

    # NyxUserInterface::searchOpen(searchPattern)
    def self.searchOpen(searchPattern)
        loop {
            scorePackets = NyxSearch::searchPatternToScorePacketsInDecreasingScore(searchPattern).select{|scorePacket| scorePacket["score"] > 0 }
            scorePacket = NyxUserInterface::selectScorePacketOrNull(scorePackets)
            break if scorePacket.nil?
            NyxPermanodeOperator::permanodeOptimisticOpen(scorePacket["permanode"])
        }
    end

    # NyxUserInterface::selectPermanodeOrNull(permanodes)
    def self.selectPermanodeOrNull(permanodes)
        descriptionXp = lambda { |permanode|
            "#{permanode["description"]} (#{permanode["uuid"][0,4]})"
        }
        descriptionsxp = permanodes.map{|permanode| descriptionXp.call(permanode) }
        selectedDescriptionxp = NyxMiscUtils::chooseALinePecoStyle("select permanode (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        permanode = permanodes.select{|permanode| descriptionXp.call(permanode) == selectedDescriptionxp }.first
        return nil if permanode.nil?
        permanode
    end

    # NyxUserInterface::selectScorePacketOrNull(scorePackets)
    def self.selectScorePacketOrNull(scorePackets)
        descriptionXp = lambda { |scorePacket|
            permanode = scorePacket["permanode"]
            "[#{scorePacket["score"]}] #{permanode["description"]} (#{permanode["uuid"][0,4]})"
        }
        descriptionsxp = scorePackets.map{|scorePacket| descriptionXp.call(scorePacket) }
        selectedDescriptionxp = NyxMiscUtils::chooseALinePecoStyle("select scored permanode (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        scorePacket = scorePackets.select{|scorePacket| descriptionXp.call(scorePacket) == selectedDescriptionxp }.first
        return nil if scorePacket.nil?
        scorePacket
    end

    # NyxUserInterface::uimainloop()
    def self.uimainloop()
        loop {
            system("clear")
            puts "Nyx 🗺️"
            operations = [
                # Search
                "search",

                # View
                "permanode dive (uuid)",
                "show newly created permanodes",
                "select and dive timeline",

                # Make or modify
                "make new permanode",
                "rename tag or timeline",
                "repair permanode (uuid)",

                # Special operations
                "publish dump for Night",
                "curation",

                # Destroy
                "permanode destroy (uuid)",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "search" then
                searchPattern = LucilleCore::askQuestionAnswerAsString("search: ")
                NyxUserInterface::searchDive(searchPattern)
            end
            if operation == "permanode dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), uuid)
                if permanode then
                    NyxPermanodeOperator::permanodeDive(permanode)
                else
                    puts "Could not find permanode for uuid (#{uuid})"
                end
            end
            if operation == "repair permanode (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), uuid)
                next if permanode.nil?
                filepath = NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(Nyx::pathToYmir(), permanode["filename"])
                next if filepath.nil?
                system("open '#{filepath}'")
                LucilleCore::pressEnterToContinue()
            end

            if operation == "make new permanode" then
                NyxPermanodeOperator::makePermanodeInteractive()
            end
            if operation == "publish dump for Night" then
                NyxMiscUtils::publishIndex2PermanodesAsOneObject()
            end
            if operation == "show newly created permanodes" then
                permanodes = NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
                NyxPermanodeOperator::applyReferenceDateTimeOrderToPermanodes(permanodes)
                    .reverse
                    .first(20)
                NyxUserInterface::permanodesDive(permanodes)
            end
            if operation == "select and dive timeline" then
                timeline = NyxMiscUtils::chooseALinePecoStyle("timeline:", [""] + NyxPermanodeOperator::timelinesInDecreasingActivityDateTime())
                next if timeline.size == 0
                permanodes = NyxPermanodeOperator::getTimelinePermanodes(timeline)
                NyxUserInterface::permanodesDive(permanodes)
            end
            if operation == "curation" then
                NyxCuration::curate()
            end
            if operation == "rename tag or timeline" then
                renameClassificationValue = lambda{|value, oldName, newName|
                    if value.downcase == oldName.downcase then
                        value = newName
                    end
                    value
                }
                transformClassificationTagObject = lambda{|object, oldName, newName|
                    object["tag"] = renameClassificationValue.call(object["tag"], oldName, newName)
                    object
                }
                transformClassificationTimelineObject = lambda{|object, oldName, newName|
                    object["timeline"] = renameClassificationValue.call(object["timeline"], oldName, newName)
                    object
                }
                transformClassificationItem = lambda{|item, oldName, newName|
                    if item["type"] == "tag-18303A17" then
                        item = transformClassificationTagObject.call(item.clone, oldName, newName)
                    end
                    if item["type"] == "timeline-329D3ABD" then
                        item = transformClassificationTimelineObject.call(item.clone, oldName, newName)
                    end
                    item
                }
                transformPermanode = lambda{|permanode, oldName, newName|
                    permanode["classification"] = permanode["classification"]
                                                    .map{|classificationItem|
                                                        transformClassificationItem.call(classificationItem.clone, oldName, newName) 
                                                    }
                    permanode
                }
                oldName = LucilleCore::askQuestionAnswerAsString("old name: ")
                newName = LucilleCore::askQuestionAnswerAsString("new name: ")
                NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
                    .each{|permanode| 
                        permanode2 = transformPermanode.call(permanode.clone, oldName, newName)
                        if permanode.to_s != permanode2.to_s then
                            puts JSON.pretty_generate(permanode)
                            puts "I am running on empty, you need to check visually and uncomment the line"
                            puts JSON.pretty_generate(permanode2)
                            #NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode2)
                        end
                    }
                NyxMiscUtils::publishIndex2PermanodesAsOneObject()
            end
            if operation == "permanode destroy (uuid)" then
                permanodeuuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanodeuuid)
                end
            end
        }
    end
end

# ----------------------------------------------------------------
