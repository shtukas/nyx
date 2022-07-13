
# encoding: UTF-8

class NxLink

    # NxLink::issue(node1uuid, node2uuid)
    def self.issue(node1uuid, node2uuid)
        fx18filepath = Fx18s::computeLocalFx18Filepath(node1uuid)
        if !File.exists?(fx18filepath) then
            Fx18s::constructNewFile(node1uuid)
        end
        Fx18s::setsAdd2(node1uuid, "network-link", node2uuid, node2uuid, false)

        fx18filepath = Fx18s::computeLocalFx18Filepath(node2uuid)
        if !File.exists?(fx18filepath) then
            Fx18s::constructNewFile(node2uuid)
        end
        Fx18s::setsAdd2(node2uuid, "network-link", node1uuid, node1uuid, false)
    end

    # NxLink::unlink(node1uuid, node2uuid)
    def self.unlink(node1uuid, node2uuid)
        fx18filepath = Fx18s::computeLocalFx18Filepath(node1uuid)
        if !File.exists?(fx18filepath) then
            Fx18s::constructNewFile(node1uuid)
        end
        Fx18s::setsRemove2(node1uuid, "network-link", node2uuid, false)

        fx18filepath = Fx18s::computeLocalFx18Filepath(node2uuid)
        if !File.exists?(fx18filepath) then
            Fx18s::constructNewFile(node2uuid)
        end
        Fx18s::setsRemove2(node2uuid, "network-link", node1uuid, false)
    end

    # NxLink::linkedUUIDs(uuid)
    def self.linkedUUIDs(uuid)
        fx18filepath = Fx18s::computeLocalFx18Filepath(uuid)
        if !File.exists?(fx18filepath) then
            Fx18s::constructNewFile(uuid)
        end
        Fx18s::setsItems(uuid, "network-link", false)
    end

    # NxLink::linkedItems(uuid)
    def self.linkedItems(uuid)
        NxLink::linkedUUIDs(uuid)
            .map{|linkeduuid| Librarian::getObjectByUUIDOrNullEnforceUnique(linkeduuid)}
            .compact
    end
end
