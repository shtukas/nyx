
# encoding: UTF-8

class NetworkEdges

    # SETTERS

    # NetworkEdges::relate(uuid1, uuid2)
    def self.relate(uuid1, uuid2)
        Phage::commit({
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => Time.new.to_f,
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
        Phage::commit({
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => Time.new.to_f,
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
        Phage::commit({
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => Time.new.to_f,
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

    # NetworkEdges::parentUUIDs(uuid)
    def self.parentUUIDs(uuid)
        parents = []
        PhageRefactoring::objectsForMikuType("NxGraphEdge1")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .each{|item|
                if item["uuid2"] == uuid and item["type"] == "arrow" then
                    parents = parents + [item["uuid1"]]
                end
                if item["uuid2"] == uuid and item["type"] == "none" then
                    parents = parents - [item["uuid1"]]
                end
            }
        parents.uniq
    end

    # NetworkEdges::relatedUUIDs(uuid)
    def self.relatedUUIDs(uuid)
        related = []
        PhageRefactoring::objectsForMikuType("NxGraphEdge1")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .each{|item|
                if item["uuid1"] == uuid and item["type"] == "bidirectional" then
                    related = related + [item["uuid2"]]
                end
                if item["uuid2"] == uuid and item["type"] == "bidirectional" then
                    related = related + [item["uuid2"]]
                end
                if item["uuid1"] == uuid and item["type"] == "none" then
                    related = related - [item["uuid2"]]
                end
                if item["uuid2"] == uuid and item["type"] == "none" then
                    related = related - [item["uuid1"]]
                end
            }
        related.uniq
    end

    # NetworkEdges::childrenUUIDs(uuid)
    def self.childrenUUIDs(uuid)
        children = []
        PhageRefactoring::objectsForMikuType("NxGraphEdge1")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .each{|item|
                if item["uuid1"] == uuid and item["type"] == "arrow" then
                    children = children + [item["uuid2"]]
                end
                if item["uuid1"] == uuid and item["type"] == "none" then
                    children = children - [item["uuid2"]]
                end
            }
        children.uniq
    end

    # NetworkEdges::parents(uuid)
    def self.parents(uuid)
        NetworkEdges::parentUUIDs(uuid)
            .map{|objectuuid| PhageRefactoring::getObjectOrNull(objectuuid) }
            .compact
    end

    # NetworkEdges::relateds(uuid)
    def self.relateds(uuid)
        NetworkEdges::relatedUUIDs(uuid)
            .map{|objectuuid| PhageRefactoring::getObjectOrNull(objectuuid) }
            .compact
    end

    # NetworkEdges::children(uuid)
    def self.children(uuid)
        NetworkEdges::childrenUUIDs(uuid)
            .map{|objectuuid| PhageRefactoring::getObjectOrNull(objectuuid) }
            .compact
    end


end
