
# encoding: UTF-8

class NxRelation

    # NxRelation::links()
    def self.links()
        Librarian::getObjectsByMikuType("NxRelation")
    end

    # NxRelation::issue(node1uuid, node2uuid)
    def self.issue(node1uuid, node2uuid)
        item = {
            "uuid"      => SecureRandom.uuid,
            "variant"   => SecureRandom.uuid,
            "mikuType"  => "NxRelation",
            "node1uuid" => node1uuid,
            "node2uuid" => node2uuid
        }
        Librarian::commit(item)
        item
    end

    # NxRelation::unlink(node1uuid, node2uuid)
    def self.unlink(node1uuid, node2uuid)
        NxRelation::links()
            .each{|item|
                if item["node1uuid"] == node1uuid and item["node2uuid"] == node2uuid then
                    Librarian::destroyClique(item["uuid"])
                end
                if item["node1uuid"] == node2uuid and item["node2uuid"] == node1uuid then
                    Librarian::destroyClique(item["uuid"])
                end
            }
    end

    # NxRelation::related(uuid)
    def self.related(uuid)
        items = []
        NxRelation::links()
            .each{|item|
                if item["node1uuid"] == uuid then
                    Librarian::getClique(item["node2uuid"]).each{|obj|
                        items << obj
                    }
                end
                if item["node2uuid"] == uuid then
                    Librarian::getClique(item["node1uuid"]).each{|obj|
                        items << obj
                    }
                end
            }
        items.compact
    end
end
