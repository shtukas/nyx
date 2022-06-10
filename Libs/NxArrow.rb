
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
end
