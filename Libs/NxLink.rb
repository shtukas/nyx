
# encoding: UTF-8

class NxLink

    # NxLink::links()
    def self.links()
        Librarian::getObjectsByMikuType("NxLink")
    end

    # NxLink::issue(node1uuid, node2uuid)
    def self.issue(node1uuid, node2uuid)
        item = {
            "uuid"      => SecureRandom.uuid,
            "variant"   => SecureRandom.uuid,
            "mikuType"  => "NxLink",
            "node1uuid" => node1uuid,
            "node2uuid" => node2uuid
        }
        Librarian::commit(item)
        item
    end

    # NxLink::unlink(node1uuid, node2uuid)
    def self.unlink(node1uuid, node2uuid)
        NxLink::links()
            .each{|item|
                if item["node1uuid"] == node1uuid and item["node2uuid"] == node2uuid then
                    Librarian::destroyClique(item["uuid"])
                end
                if item["node1uuid"] == node2uuid and item["node2uuid"] == node1uuid then
                    Librarian::destroyClique(item["uuid"])
                end
            }
    end

    # NxLink::linkedUUIDs(uuid)
    def self.linkedUUIDs(uuid)
        uuids = []
        NxLink::links()
            .each{|item|
                if item["node1uuid"] == uuid then
                    uuids << item["node2uuid"]
                end
                if item["node2uuid"] == uuid then
                    uuids << item["node1uuid"]
                end
            }
        uuids
    end

    # NxLink::linkedItems(uuid)
    def self.linkedItems(uuid)
        items = []
        NxLink::links()
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
