
# encoding: UTF-8

class NxArrow

    # NxArrow::arrows()
    def self.arrows()
        Librarian::getObjectsByMikuType("NxArrow")
    end

    # NxArrow::issue(sourceuuid, targetuuid)
    def self.issue(sourceuuid, targetuuid)
        item = {
            "uuid"     => Digest::SHA1.hexdigest("6102800c:#{sourceuuid}-#{targetuuid}"), # This way of computing the uuid ensures that arrow creation is an idempotent operation
            "mikuType" => "NxArrow",
            "source"   => sourceuuid,
            "target"   => targetuuid
        }
        Librarian::commit(item)
        item
    end

    # NxArrow::unlink(sourceuuid, targetuuid)
    def self.unlink(sourceuuid, targetuuid)
        Librarian::getObjectsByMikuType("NxArrow")
            .each{|item|
                if item["source"] == sourceuuid and item["target"] == targetuuid then
                    Librarian::destroy(item["uuid"])
                end
            }
    end

    # NxArrow::parents(uuid)
    def self.parents(uuid)
        items = []
        Librarian::getObjectsByMikuType("NxArrow")
            .each{|item|
                if item["target"] == uuid then
                    items << Librarian::getObjectByUUIDOrNull(item["source"])
                end
            }
        items.compact
    end

    # NxArrow::children(uuid)
    def self.children(uuid)
        items = []
        Librarian::getObjectsByMikuType("NxArrow")
            .each{|item|
                if item["source"] == uuid then
                    items << Librarian::getObjectByUUIDOrNull(item["target"])
                end
            }
        items.compact
    end
end
