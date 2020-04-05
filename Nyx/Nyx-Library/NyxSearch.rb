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

class NyxSearch

    # NyxSearch::permanodeTargetHasSearchPattern(target, searchPattern)
    def self.permanodeTargetHasSearchPattern(target, searchPattern)
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return true if target["mark"].downcase == searchPattern.downcase
            return false
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return true if target["name"].downcase == searchPattern.downcase
            return false
        end
        if target["type"] == "url-EFB8D55B" then
            return true if target["url"].downcase == searchPattern.downcase
            return false
        end
        if target["type"] == "perma-dir-11859659" then
            return true if target["foldername"].downcase == searchPattern.downcase
            return false
        end
        raise "[error: ab44ef72]"
    end

    # NyxSearch::permanodeTargetIncludeSearchPattern(target, searchPattern)
    def self.permanodeTargetIncludeSearchPattern(target, searchPattern)
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return true if target["mark"].downcase.include?(searchPattern.downcase)
            return false
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return true if target["name"].downcase.include?(searchPattern.downcase)
            return false
        end
        if target["type"] == "url-EFB8D55B" then
            return true if target["url"].downcase.include?(searchPattern.downcase)
            return false
        end
        if target["type"] == "perma-dir-11859659" then
            return true if target["foldername"].downcase.include?(searchPattern.downcase)
            return false
        end
        raise "[error: 1113716b]"
    end

    # NyxSearch::permanodeSearchScore(permanode, searchPattern)
    def self.permanodeSearchScore(permanode, searchPattern)
        # 1.50 : Description is identical to search pattern
        # 1.00 : Descriprion contains search pattern as distinct word

        # 0.95 : target payload is identical to search pattern
        # 0.90 : uuid contains search pattern
        # 0.80 : Description contains search pattern

        # 0.75 : target payload is contains to search pattern
        # 0.70 : referenceDateTime contains search pattern
        # 0.60 : Timeline is identical to search pattern
        # 0.50 : Tag is identical to search pattern
        # 0.40 : Timeline contains search pattern
        # 0.30 : Tag contains search pattern
        return 1.50 if permanode["description"].downcase == searchPattern.downcase
        return 1.00 if permanode["description"].downcase.include?(" #{searchPattern.downcase} ")
        return 0.95 if permanode["targets"].any?{|target| NyxSearch::permanodeTargetHasSearchPattern(target, searchPattern) }
        return 0.90 if permanode["uuid"].downcase.include?(searchPattern.downcase)
        return 0.80 if permanode["description"].downcase.include?(searchPattern.downcase)
        return 0.75 if permanode["targets"].any?{|target| NyxSearch::permanodeTargetIncludeSearchPattern(target, searchPattern) }
        return 0.70 if permanode["referenceDateTime"].downcase.include?(searchPattern.downcase)
        return 0.60 if permanode["classification"].select{|item| item["type"] == "timeline-329D3ABD" }.any?{|item| item["timeline"].downcase == searchPattern.downcase }
        return 0.50 if permanode["classification"].select{|item| item["type"] == "tag-18303A17"      }.any?{|item| item["tag"].downcase == searchPattern.downcase }
        return 0.40 if permanode["classification"].select{|item| item["type"] == "timeline-329D3ABD" }.any?{|item| item["timeline"].downcase.include?(searchPattern.downcase) }
        return 0.30 if permanode["classification"].select{|item| item["type"] == "tag-18303A17"      }.any?{|item| item["tag"].downcase.include?(searchPattern.downcase) }
        0
    end

    # NyxSearch::permanodeSearchScorePacket(permanode, searchPattern):
    def self.permanodeSearchScorePacket(permanode, searchPattern)
        {
            "permanode" => permanode,
            "score" => NyxSearch::permanodeSearchScore(permanode, searchPattern)
        }
    end

    # NyxSearch::searchPatternToScorePacketsInDecreasingScore(searchPattern)
    def self.searchPatternToScorePacketsInDecreasingScore(searchPattern) # Array[ScorePackets]
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .map{|permanode| NyxSearch::permanodeSearchScorePacket(permanode, searchPattern) }
            .sort{|p1, p2| p1["score"]<=>p2["score"] }
            .reverse
    end

end
