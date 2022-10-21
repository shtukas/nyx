
# encoding: UTF-8

class NetworkEdges

    # SPECIFIC IO

    # NetworkEdges::commitVariant(variant)
    def self.commitVariant(variant)
        return if variant["mikuType"] != "NxGraphEdge1"

        FileSystemCheck::fsck_PhageItem(variant, SecureRandom.hex, false)

        uuid1 = variant["uuid1"]
        filepath1 = "#{Config::pathToDataCenter()}/NxGraphEdge1/#{uuid1[0, 3]}/#{variant["uuid1"]}/#{variant["phage_uuid"]}.json"
        
        uuid2 = variant["uuid2"]
        filepath2 = "#{Config::pathToDataCenter()}/NxGraphEdge1/#{uuid2[0, 3]}/#{variant["uuid2"]}/#{variant["phage_uuid"]}.json"

        [filepath1, filepath2].each{|filepath|
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(variant)) }
        }
    end

    # NetworkEdges::variantsForUUID(nodeuuid)
    def self.variantsForUUID(nodeuuid)
        folderpath = "#{Config::pathToDataCenter()}/NxGraphEdge1/#{nodeuuid[0, 3]}/#{nodeuuid}"
        return [] if !File.exists?(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NetworkEdges::objectsForUUID(nodeuuid)
    def self.objectsForUUID(nodeuuid)
        PhageInternals::variantsToObjects(NetworkEdges::variantsForUUID(nodeuuid))
    end

    # SETTERS

    # NetworkEdges::relate(uuid1, uuid2)
    def self.relate(uuid1, uuid2)
        NetworkEdges::commitVariant({
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxGraphEdge1",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "uuid1"       => uuid1,
            "uuid2"       => uuid2,
            "type"        => "bidirectional" # "bidirectional" | "arrow" | "none"
        })
    end

    # NetworkEdges::arrow(uuid1, uuid2)
    def self.arrow(uuid1, uuid2)
        NetworkEdges::commitVariant({
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxGraphEdge1",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "uuid1"       => uuid1,
            "uuid2"       => uuid2,
            "type"        => "arrow" # "bidirectional" | "arrow" | "none"
        })
    end

    # NetworkEdges::detach(uuid1, uuid2)
    def self.detach(uuid1, uuid2)
        NetworkEdges::commitVariant({
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxGraphEdge1",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "uuid1"       => uuid1,
            "uuid2"       => uuid2,
            "type"        => "none" # "bidirectional" | "arrow" | "none"
        })
    end

    # GETTERS

    # NetworkEdges::parentUUIDs(nodeuuid)
    def self.parentUUIDs(nodeuuid)
        parents = []
        NetworkEdges::objectsForUUID(nodeuuid)
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .each{|item|
                if item["uuid2"] == nodeuuid and item["type"] == "arrow" then
                    parents = parents + [item["uuid1"]]
                end
                if item["uuid2"] == nodeuuid and item["type"] == "none" then
                    parents = parents - [item["uuid1"]]
                end
            }
        parents.uniq
    end

    # NetworkEdges::relatedUUIDs(nodeuuid)
    def self.relatedUUIDs(nodeuuid)
        related = []
        NetworkEdges::objectsForUUID(nodeuuid)
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .each{|item|
                if item["uuid1"] == nodeuuid and item["type"] == "bidirectional" then
                    related = related + [item["uuid2"]]
                end
                if item["uuid2"] == nodeuuid and item["type"] == "bidirectional" then
                    related = related + [item["uuid2"]]
                end
                if item["uuid1"] == nodeuuid and item["type"] == "none" then
                    related = related - [item["uuid2"]]
                end
                if item["uuid2"] == nodeuuid and item["type"] == "none" then
                    related = related - [item["uuid1"]]
                end
            }
        (related - [nodeuuid]).uniq
    end

    # NetworkEdges::childrenUUIDs(nodeuuid)
    def self.childrenUUIDs(nodeuuid)
        children = []
        NetworkEdges::objectsForUUID(nodeuuid)
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .each{|item|
                if item["uuid1"] == nodeuuid and item["type"] == "arrow" then
                    children = children + [item["uuid2"]]
                end
                if item["uuid1"] == nodeuuid and item["type"] == "none" then
                    children = children - [item["uuid2"]]
                end
            }
        children.uniq
    end

    # NetworkEdges::parents(uuid)
    def self.parents(uuid)
        NetworkEdges::parentUUIDs(uuid)
            .map{|objectuuid| NyxNodes::getItemOrNull(objectuuid) }
            .compact
    end

    # NetworkEdges::relateds(uuid)
    def self.relateds(uuid)
        NetworkEdges::relatedUUIDs(uuid)
            .map{|objectuuid| NyxNodes::getItemOrNull(objectuuid) }
            .compact
    end

    # NetworkEdges::children(uuid)
    def self.children(uuid)
        NetworkEdges::childrenUUIDs(uuid)
            .map{|objectuuid| NyxNodes::getItemOrNull(objectuuid) }
            .compact
    end


end
