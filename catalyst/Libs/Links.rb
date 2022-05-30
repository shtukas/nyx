
# encoding: UTF-8

class LinkCache

    # LinkCache::getPointer(uuid)
    def self.getPointer(uuid)
        pointer = XCache::getOrNull("93c6fa61-bb04-4115-8823-980d47eca494:#{uuid}")
        return pointer if pointer
        pointer = SecureRandom.hex
        XCache::set("93c6fa61-bb04-4115-8823-980d47eca494:#{uuid}", pointer)
        pointer
    end

    # LinkCache::resetPointer(uuid)
    def self.resetPointer(uuid)
        XCache::set("93c6fa61-bb04-4115-8823-980d47eca494:#{uuid}", SecureRandom.hex)
    end
end

class Links

    # Links::link(sourceuuid: String, targetuuid: String, isBidirectional: Boolean)
    def self.link(sourceuuid, targetuuid, isBidirectional)
        return if (sourceuuid == targetuuid)

        Links::unlink(sourceuuid, targetuuid)

        item = {
            "uuid"          => SecureRandom.uuid,
            "mikuType"      => "Lx21",
            "sourceuuid"    => sourceuuid,
            "targetuuid"    => targetuuid,
            "bidirectional" => isBidirectional
        }
        #puts JSON.pretty_generate(item)
        Librarian::commit(item)

        LinkCache::resetPointer(sourceuuid)
        LinkCache::resetPointer(targetuuid)
    end

    # Links::unlink(uuid1, uuid2)
    def self.unlink(uuid1, uuid2)
        Librarian::getObjectsByMikuType("Lx21")
            .select{|item|
                b1 = (item["sourceuuid"] == uuid1 and item["targetuuid"] == uuid2)
                b2 = (item["sourceuuid"] == uuid2 and item["targetuuid"] == uuid1)
                b1 or b2
            }
            .each{|item| Librarian::logicaldelete(item["uuid"]) }

        LinkCache::resetPointer(uuid1)
        LinkCache::resetPointer(uuid2)
    end

    # ------------------------------------------------
    # Relations UUIDs

    # Links::relatedUUIDs(uuid)
    def self.relatedUUIDs(uuid)

        pointer = LinkCache::getPointer(uuid)
        data = XCache::getOrNull("9ae2a347-954e-45ff-8171-30452e594101:#{pointer}")
        if data then
            return JSON.parse(data)
        end

        uuids1 = Librarian::getObjectsByMikuType("Lx21")
                    .select{|item| item["sourceuuid"] == uuid and item["bidirectional"] }
                    .map{|item| item["targetuuid"] }

        uuids2 = Librarian::getObjectsByMikuType("Lx21")
                    .select{|item| item["targetuuid"] == uuid and item["bidirectional"] }
                    .map{|item| item["sourceuuid"] }
        data = uuids1 + uuids2

        XCache::set("9ae2a347-954e-45ff-8171-30452e594101:#{pointer}", JSON.generate(data))

        data
    end

    # Links::parentUUIDs(uuid)
    def self.parentUUIDs(uuid)

        pointer = LinkCache::getPointer(uuid)
        data = XCache::getOrNull("7e6cd588-bef8-4f48-b282-3e87fa98fb22:#{pointer}")
        if data then
            return JSON.parse(data)
        end

        data = Librarian::getObjectsByMikuType("Lx21")
            .select{|item| item["targetuuid"] == uuid and !item["bidirectional"] }
            .map{|item| item["sourceuuid"] }

        XCache::set("7e6cd588-bef8-4f48-b282-3e87fa98fb22:#{pointer}", JSON.generate(data))

        data
    end

    # Links::childrenUUIDs(uuid)
    def self.childrenUUIDs(uuid)

        pointer = LinkCache::getPointer(uuid)
        data = XCache::getOrNull("cb32d910-cf11-466b-8f08-eacf361a0195:#{pointer}")
        if data then
            return JSON.parse(data)
        end

        data = Librarian::getObjectsByMikuType("Lx21")
            .select{|item| item["sourceuuid"] == uuid and !item["bidirectional"] }
            .map{|item| item["targetuuid"] }

        XCache::set("cb32d910-cf11-466b-8f08-eacf361a0195:#{pointer}", JSON.generate(data))

        data
    end

    # ------------------------------------------------
    # Relations Objects

    # Links::related(uuid)
    def self.related(uuid)
        Links::relatedUUIDs(uuid)
            .map{|uuid| Librarian::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # Links::parents(uuid)
    def self.parents(uuid)
        Links::parentUUIDs(uuid)
            .map{|uuid| Librarian::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # Links::children(uuid)
    def self.children(uuid)
        Links::childrenUUIDs(uuid)
            .map{|uuid| Librarian::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # Links::linked(uuid)
    def self.linked(uuid)
         Links::parents(uuid) + Links::related(uuid) + Links::children(uuid)
    end

    # ------------------------------------------------
    # Data

    # Links::linkTypeOrNull(itemuuid, otheruuid)
    def self.linkTypeOrNull(itemuuid, otheruuid)
        if Links::relatedUUIDs(itemuuid).include?(otheruuid) then
            return "related"
        end
        if Links::parentUUIDs(itemuuid).include?(otheruuid) then
            return "parent"
        end
        if Links::childrenUUIDs(itemuuid).include?(otheruuid) then
            return "child"
        end
        nil
    end
end
