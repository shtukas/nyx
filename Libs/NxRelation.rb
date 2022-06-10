
# encoding: UTF-8

class NxRelation

    # NxRelation::links()
    def self.links()
        Librarian::getObjectsByMikuType("NxRelation")
    end

    # NxRelation::issue(node1uuid, node2uuid)
    def self.issue(node1uuid, node2uuid)
        item = {
            "uuid"      => Digest::SHA1.hexdigest("48450b41:#{[node1uuid, node2uuid].sort.join(":")}"), # This way of computing the uuid ensures that arrow creation is an idempotent operation
            "mikuType"  => "NxRelation",
            "node1uuid" => node1uuid,
            "node2uuid" => node2uuid
        }
        Librarian::commit(item)
        item
    end

    # NxRelation::unlink(node1uuid, node2uuid)
    def self.unlink(node1uuid, node2uuid)
        Librarian::getObjectsByMikuType("NxRelation")
            .each{|item|
                if item["node1uuid"] == node1uuid and item["node2uuid"] == node2uuid then
                    Librarian::destroy(item["uuid"])
                end
                if item["node1uuid"] == node2uuid and item["node2uuid"] == node1uuid then
                    Librarian::destroy(item["uuid"])
                end
            }
    end

    # NxRelation::related(uuid)
    def self.related(uuid)
        items = []
        Librarian::getObjectsByMikuType("NxRelation")
            .each{|item|
                if item["node1uuid"] == uuid then
                    items << Librarian::getObjectByUUIDOrNull(item["node2uuid"])
                end
                if item["node2uuid"] == uuid then
                    items << Librarian::getObjectByUUIDOrNull(item["node1uuid"])
                end
            }
        items.compact
    end
end
