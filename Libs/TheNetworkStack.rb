
# encoding: UTF-8

# The stack fundamentally is an array of uuids

class TheNetworkStack

    # TheNetworkStack::getRawStack()
    def self.getRawStack()
        JSON.parse(XCache::getOrDefaultValue("fbde4879-28d4-4aa9-bfec-eae59134f210", "[]"))
    end

    # TheNetworkStack::setRawStack(rawstack)
    def self.setRawStack(rawstack)
        XCache::set("fbde4879-28d4-4aa9-bfec-eae59134f210", JSON.generate(rawstack))
    end

    # TheNetworkStack::getStack()
    def self.getStack()
        TheNetworkStack::getRawStack()
            .map{|uuid| Librarian20LocalObjectsStore::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # TheNetworkStack::queue(uuid)
    def self.queue(uuid)
        rawstack = (TheNetworkStack::getRawStack() + [uuid]).uniq
        TheNetworkStack::setRawStack(rawstack)
    end

    # TheNetworkStack::clear()
    def self.clear()
        TheNetworkStack::setRawStack([])
    end
end
