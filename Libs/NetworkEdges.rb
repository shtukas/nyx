
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

    # Getters

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

    # NetworkEdges::parents(uuid)
    def self.parents(uuid)
        NetworkEdges::parentUUIDs(uuid)
            .map{|objectuuid| Items::getItemOrNull(objectuuid) }
            .compact
    end

    # NetworkEdges::relateds(uuid)
    def self.relateds(uuid)
        NetworkEdges::relatedUUIDs(uuid)
            .map{|objectuuid| Items::getItemOrNull(objectuuid) }
            .compact
    end

    # NetworkEdges::children(uuid)
    def self.children(uuid)
        NetworkEdges::childrenUUIDs(uuid)
            .map{|objectuuid| Items::getItemOrNull(objectuuid) }
            .compact
    end

    # Changes

    # NetworkEdges::relate(uuid1, uuids2)
    def self.relate(uuid1, uuids2)

    end

    # NetworkEdges::arrow(uuid1, uuids2)
    def self.arrow(uuid1, uuids2)

    end

    # NetworkEdges::detach(uuid1, uuid2)
    def self.detach(uuid1, uuid2)

    end
end

class NetworkEdgesOps

    # NetworkEdgesOps::selectOneRelatedAndDetach(item)
    def self.selectOneRelatedAndDetach(item)
        store = ItemStore.new()

        NetworkEdges::relatedUUIDs(item["uuid"]) # .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entityuuid|
                entity = Items::getItemOrNull(entityuuid)
                next if entity.nil?
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            NetworkEdges::detach(item["uuid"], entity["uuid"])
        end
    end

    # NetworkEdgesOps::architectureAndRelate(item)
    def self.architectureAndRelate(item)
        item2 = Nyx::architectOneOrNull()
        return if item2.nil?
        NetworkEdges::relate(item["uuid"], item2["uuid"])
    end

    # NetworkEdgesOps::interactivelySelectRelatedEntities(uuid)
    def self.interactivelySelectRelatedEntities(uuid)
        entities = NetworkEdges::relateds(uuid).sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("entity", [], entities, lambda{ |item| PolyFunctions::toString(item) })
        selected
    end
end
