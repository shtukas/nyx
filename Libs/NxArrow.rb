
# encoding: UTF-8

class NxArrow

    # NxArrow::arrows()
    def self.arrows()
        Librarian::getObjectsByMikuType("NxArrow")
    end

    # NxArrow::issue(sourceuuid, targetuuid)
    def self.issue(sourceuuid, targetuuid)
        item = {
            "uuid"     => SecureRandom.uuid,
            "variant"  => SecureRandom.uuid,
            "mikuType" => "NxArrow",
            "source"   => sourceuuid,
            "target"   => targetuuid
        }
        Librarian::commit(item)
        item
    end

    # NxArrow::unlink(sourceuuid, targetuuid)
    def self.unlink(sourceuuid, targetuuid)
        NxArrow::arrows()
            .each{|item|
                if item["source"] == sourceuuid and item["target"] == targetuuid then
                    Librarian::destroyClique(item["uuid"])
                end
            }
    end

    # NxArrow::parents(uuid)
    def self.parents(uuid)
        items = []
        NxArrow::arrows()
            .each{|item|
                if item["target"] == uuid then
                    Librarian::getClique(item["source"]).each{|obj|
                        items << obj
                    }
                end
            }
        items.compact
    end

    # NxArrow::children(uuid)
    def self.children(uuid)
        items = []
        NxArrow::arrows()
            .each{|item|
                if item["source"] == uuid then
                    Librarian::getClique(item["target"]).each{|obj|
                        items << obj
                    }
                end
            }
        items.compact
    end
end
