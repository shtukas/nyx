class Links

    # Links::link(uuid1, uuid2)
    def self.link(uuid1, uuid2)
        Solingen::addToSet2(uuid1, "linkeduuids", uuid2, uuid2)
        Solingen::addToSet2(uuid2, "linkeduuids", uuid1, uuid1)
    end

    # Links::nodes(uuid)
    def self.nodes(uuid) # Array[NxNode]
        Solingen::getSet2(uuid, "linkeduuids")
            .map{|u| Solingen::getItemOrNull(u) }
            .compact
    end
end