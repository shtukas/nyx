
# encoding: UTF-8

class NxLink

    # NxLink::issue(node1uuid, node2uuid)
    def self.issue(node1uuid, node2uuid)
        Fx18Sets::add2(node1uuid, "network-link", node2uuid, node2uuid)
        Fx18Sets::add2(node2uuid, "network-link", node1uuid, node1uuid)
    end

    # NxLink::unlink(node1uuid, node2uuid)
    def self.unlink(node1uuid, node2uuid)
        Fx18Sets::remove2(node1uuid, "network-link", node2uuid)
        Fx18Sets::remove2(node2uuid, "network-link", node1uuid)
    end

    # NxLink::linkedUUIDs(uuid)
    def self.linkedUUIDs(uuid)
        Fx18Sets::items(uuid, "network-link")
    end

    # NxLink::linkedEntities(uuid)
    def self.linkedEntities(uuid)
        NxLink::linkedUUIDs(uuid)
            .select{|uuid| Fx18::objectIsAlive(uuid) }
            .map{|objectuuid| Fx18::itemOrNull(objectuuid) }
            .compact
    end

    # NxLink::interactivelySelectLinkedEntityOrNull(uuid)
    def self.interactivelySelectLinkedEntityOrNull(uuid)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("entity", NxLink::linkedEntities(uuid), lambda{ |item| LxFunction::function("toString", item) })
    end

    # NxLink::interactivelySelectLinkedEntities(uuid)
    def self.interactivelySelectLinkedEntities(uuid)
        selected, unselected = LucilleCore::selectZeroOrMore("entity", [], NxLink::linkedEntities(uuid), lambda{ |item| LxFunction::function("toString", item) })
        selected
    end

    # NxLink::networkMigration(item)
    def self.networkMigration(item)
        uuid = item["uuid"]
        entities = NxLink::interactivelySelectLinkedEntities(uuid)
        return if entities.empty?
        mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["from linked", "from entire network"])
        return if mode.nil?
        if mode == "from linked" then
            target = NxLink::interactivelySelectLinkedEntityOrNull(uuid)
        end
        if mode == "from entire network" then
            target = Nyx::selectExistingNetworkNodeOrNull()
        end
        return if target.nil?
        if target["uuid"] == item["uuid"] then
            puts "The target that you have chosen is equal to the current item"
            LucilleCore::pressEnterToContinue()
        end
        entities.each{|entity|
            NxLink::issue(target["uuid"], entity["uuid"])
        }
        entities.each{|entity|
            NxLink::unlink(item["uuid"], entity["uuid"])
        }
    end
end
