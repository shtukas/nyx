
# encoding: UTF-8

=begin

{
    "mikuType" : "PrimaryStructure.v1:NetworkEdges"
    "edges"    : Array[NxGraphEdge1]
}

NxGraphEdge1 {
    "mikuType" : "NxGraphEdge1"
    "unixtime" : Float
    "uuid1"    : String
    "uuid2"    : String
    "type"     : "bidirectional" | "arrow" | "none"
}

=end

class NetworkEdges

    # NetworkEdges::parentUUIDs(uuid)
    def self.parentUUIDs(uuid)
        networkEdges = TheLibrarian::getNetworkEdges()
        networkEdges["edges"]
            .select{|item| item["type"] == "arrow" }
            .select{|item| item["uuid2"] == uuid }
            .map{|item| item["uuid1"] }
    end

    # NetworkEdges::relatedUUIDs(uuid)
    def self.relatedUUIDs(uuid)
        networkEdges = TheLibrarian::getNetworkEdges()
        uuids1 = networkEdges["edges"]
            .select{|item| item["type"] == "bidirectional" }
            .select{|item| item["uuid1"] == uuid }
            .map{|item| item["uuid2"] }
        uuids2 = networkEdges["edges"]
            .select{|item| item["type"] == "bidirectional" }
            .select{|item| item["uuid2"] == uuid }
            .map{|item| item["uuid1"] }
        (uuids1 + uuids2).uniq
    end

    # NetworkEdges::childrenUUIDs(uuid)
    def self.childrenUUIDs(uuid)
        networkEdges = TheLibrarian::getNetworkEdges()
        networkEdges["edges"]
            .select{|item| item["type"] == "arrow" }
            .select{|item| item["uuid1"] == uuid }
            .map{|item| item["uuid2"] }
    end
end
