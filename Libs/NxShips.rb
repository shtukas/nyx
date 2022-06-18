
# encoding: UTF-8

class NxShips

    # ----------------------------------------------------------------------
    # IO

    # NxShips::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxShip")
    end

    # NxShips::getOrNull(uuid): null or NxShip
    def self.getOrNull(uuid)
        Librarian::getObjectByUUIDOrNull(uuid)
    end

    # NxShips::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxShips::issue(flotilleuuid, itemuuid)
    def self.issue(flotilleuuid, itemuuid)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxShip",
            "unixtime" => unixtime,
            "datetime" => datetime,
            "flotille" => flotilleuuid,
            "target"   => itemuuid,
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxShips::toString(item)
    def self.toString(item)
        target = Librarian::getObjectByUUIDOrNull(item["target"])
        if target.nil? then
            return "(ship) target not found (#{item["target"]})"
        end
        "(ship) #{LxFunction::function("toString", target)}"
    end

    # ------------------------------------------------
    # Operations


end
