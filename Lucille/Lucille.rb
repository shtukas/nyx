
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

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

class LucilleClaims
    # LucilleClaims::pathToClaims()
    def self.pathToClaims()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Claims"
    end

    # LucilleClaims::claims()
    def self.claims()
        Dir.entries(LucilleClaims::pathToClaims())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{LucilleClaims::pathToClaims()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # LucilleClaims::getClaimByUUIDOrNUll(uuid)
    def self.getClaimByUUIDOrNUll(uuid)
        filepath = "#{LucilleClaims::pathToClaims()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # LucilleClaims::save(claim)
    def self.save(claim)
        uuid = claim["uuid"]
        File.open("#{LucilleClaims::pathToClaims()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
    end

    # LucilleClaims::destroy(claim)
    def self.destroy(claim)
        uuid = claim["uuid"]
        filepath = "#{LucilleClaims::pathToClaims()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # LucilleClaims::makeClaim(uuid, description, target, timeline)
    def self.makeClaim(uuid, description, target, timeline)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "target"       => target,
            "timeline"     => timeline
        }
    end

    # LucilleClaims::issueClaim(uuid, description, target, timeline)
    def self.issueClaim(uuid, description, target, timeline)
        claim = LucilleClaims::makeClaim(uuid, description, target, timeline)
        LucilleClaims::save(claim)
    end

    # LucilleClaims::selectClaimOrNull()
    def self.selectClaimOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("claim:", LucilleClaims::claims(), lambda {|claim| claim["description"] })
    end

    # LucilleClaims::isCurrentUUID(uuid)
    def self.isCurrentUUID(uuid)
        File.exists?("#{LucilleClaims::pathToClaims()}/#{uuid}.json")
    end
end

class LucilleSpecialOps

    # -----------------------------
    # Data

    # LucilleSpecialOps::timelines()
    def self.timelines()
        LucilleClaims::claims()
            .map{|claim| claim["timeline"] }
            .uniq
            .sort
    end

    # LucilleSpecialOps::getTimelineClaims(timeline)
    def self.getTimelineClaims(timeline)
        LucilleClaims::claims()
            .select{|claim| claim["timeline"] == timeline }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # -----------------------------
    # Operations

    # LucilleSpecialOps::twinAsIfcsItem(claim)
    def self.twinAsIfcsItem(claim)

    end

    # LucilleSpecialOps::recastAsNyxItem(claim)
    def self.recastAsNyxItem(claim)

    end

end

class LXCluster

    # LXCluster::selectClaimsForCluster()
    def self.selectClaimsForCluster()
        LucilleSpecialOps::timelines()
            .reject{|timeline| timeline == "Inbox"}
            .map{|timeline|
                LucilleSpecialOps::getTimelineClaims(timeline).first(10)
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
        cluster["claims"] = cluster["claims"].select{|claim| LucilleClaims::isCurrentUUID(claim["uuid"]) }
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
            timelines = LucilleSpecialOps::timelines().reject{|timeline| timeline == "Inbox" }
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
        LucilleClaims::save(claim)
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
                next if claim["target"].nil?
                CatalystCommon::openCatalystStandardTarget(claim["target"])
            end
            if option == "done" then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this claim? ") then
                    LucilleClaims::destroy(claim)
                end
                return
            end
            if option == "set description" then
                claim["description"] = CatalystCommon::editTextUsingTextmate(claim["description"])
                LucilleClaims::save(claim)
            end
            if option == "recast" then
                LXUserInterface::recastItem(claim)
            end
            if option == ">ifcs" then
                LucilleSpecialOps::twinAsIfcsItem(claim)
                return
            end
            if option == ">nyx" then
                LucilleSpecialOps::recastAsNyxItem(claim)
                return
            end
        }
    end

    # LXUserInterface::timelineDive(timeline)
    def self.timelineDive(timeline)
        puts "-> #{timeline}"
        loop {
            claims = LucilleSpecialOps::getTimelineClaims(timeline)
            claim = LucilleCore::selectEntityFromListOfEntitiesOrNull("items:", claims, lambda {|claim| claim["description"] })
            break if claim.nil?
            LXUserInterface::itemDive(claim)
        }
    end

    # LXUserInterface::selectTimeOrNull()
    def self.selectTimeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("timeline:", LucilleSpecialOps::timelines())
    end

    # LXUserInterface::selectTimelineExistingOrNewOrNull()
    def self.selectTimelineExistingOrNewOrNull()
        timeline = LXUserInterface::selectTimeOrNull()
        return timeline if timeline
        timeline = LucilleCore::askQuestionAnswerAsString("timeline: ")
        return nil if timeline == ""
        timeline
    end

end
