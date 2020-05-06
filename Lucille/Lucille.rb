
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
    # Data

    # LucilleThisCore::timelines()
    def self.timelines()
        LucilleNextGen::claims()
            .map{|claim| claim["timeline"] }
            .uniq
            .sort
    end

    # LucilleThisCore::getTimelineClaims(timeline)
    def self.getTimelineClaims(timeline)
        LucilleNextGen::claims()
            .select{|claim| claim["timeline"] == timeline }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # -----------------------------
    # Operations

    # LucilleThisCore::twinAsIfcsItem(claim)
    def self.twinAsIfcsItem(claim)

    end

    # LucilleThisCore::recastAsNyxItem(claim)
    def self.recastAsNyxItem(claim)

    end

end

class LXCluster

    # LXCluster::selectClaimsForCluster()
    def self.selectClaimsForCluster()
        LucilleThisCore::timelines()
            .reject{|timeline| timeline == "Inbox"}
            .map{|timeline|
                LucilleThisCore::getTimelineClaims(timeline).first(10)
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
        claims = LXCluster::selectClaimsForCluster()
        cluster = {
            "creationunixtime" => Time.new.to_i,
            "initialsize" => claims.size,
            "claims" => claims
        }
        LXCluster::commitClusterToDisk(cluster)
        cluster
    end

    # LXCluster::getWorkingCluster()
    def self.getWorkingCluster()
        cluster = LXCluster::getClusterFromDisk()
        cluster["claims"] = cluster["claims"].select{|claim| LucilleNextGen::isCurrentUUID(claim["uuid"]) }
        if cluster["claims"].size < 0.5*cluster["initialsize"] then
            cluster = LXCluster::issueNewCluster()
        end
        cluster
    end
end

class LXUserInterface

    # LXUserInterface::recastItem(claim)
    def self.recastItem(claim)
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
        claim["timeline"] = timeline
        LucilleNextGen::save(claim)
    end

    # LXUserInterface::itemDive(claim)
    def self.itemDive(claim)
        loop {
            system("clear")
            puts "uuid: #{claim["uuid"]}"
            puts "description: #{claim["description"]}"
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
                CatalystCommon::openCatalystStandardTarget(claim["target"])
            end
            if option == "done" then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this claim? ") then
                    LucilleNextGen::destroy(claim)
                end
                return
            end
            if option == "set description" then
                claim["description"] = CatalystCommon::editTextUsingTextmate(claim["description"])
                LucilleNextGen::save(claim)
            end
            if option == "recast" then
                LXUserInterface::recastItem(claim)
            end
            if option == ">ifcs" then
                LucilleThisCore::twinAsIfcsItem(claim)
                return
            end
            if option == ">nyx" then
                LucilleThisCore::recastAsNyxItem(claim)
                return
            end
        }
    end

    # LXUserInterface::timelineDive(timeline)
    def self.timelineDive(timeline)
        puts "-> #{timeline}"
        loop {
            claims = LucilleThisCore::getTimelineClaims(timeline)
            claim = LucilleCore::selectEntityFromListOfEntitiesOrNull("items:", claims, lambda {|claim| claim["description"] })
            break if claim.nil?
            LXUserInterface::itemDive(claim)
        }
    end

end


class LucilleNextGen
    # LucilleNextGen::pathToClaims()
    def self.pathToClaims()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Claims"
    end

    # LucilleNextGen::claims()
    def self.claims()
        Dir.entries(LucilleNextGen::pathToClaims())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{LucilleNextGen::pathToClaims()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # LucilleNextGen::getClaimByUUIDOrNUll(uuid)
    def self.getClaimByUUIDOrNUll(uuid)
        filepath = "#{LucilleNextGen::pathToClaims()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # LucilleNextGen::save(claim)
    def self.save(claim)
        uuid = claim["uuid"]
        File.open("#{LucilleNextGen::pathToClaims()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
    end

    # LucilleNextGen::destroy(claim)
    def self.destroy(claim)
        uuid = claim["uuid"]
        filepath = "#{LucilleNextGen::pathToClaims()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # LucilleNextGen::makeClaim(uuid, description, target, timeline)
    def self.makeClaim(uuid, description, target, timeline)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "target"       => target,
            "timeline"     => timeline
        }
    end

    # LucilleNextGen::issueClaim(uuid, description, target, timeline)
    def self.issueClaim(uuid, description, target, timeline)
        claim = LucilleNextGen::makeClaim(uuid, description, target, timeline)
        LucilleNextGen::save(claim)
    end

    # LucilleNextGen::selectClaimOrNull()
    def self.selectClaimOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("claim:", LucilleNextGen::claims(), lambda {|claim| claim["description"] })
    end

    # LucilleNextGen::isCurrentUUID(uuid)
    def self.isCurrentUUID(uuid)
        File.exists?("#{LucilleNextGen::pathToClaims()}/#{uuid}.json")
    end
end
