
# encoding: UTF-8

class TxFlts

    # ----------------------------------------------------------------------
    # IO

    # TxFlts::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxFlt")
    end

    # TxFlts::getOrNull(uuid): null or TxFlt
    def self.getOrNull(uuid)
        Librarian::getObjectByUUIDOrNull(uuid)
    end

    # TxFlts::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxFlts::issue(flotilleuuid, itemuuid)
    def self.issue(flotilleuuid, itemuuid)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"     => uuid,
            "mikuType" => "TxFlt",
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

    # TxFlts::toString(item)
    def self.toString(item)
        target = Librarian::getObjectByUUIDOrNull(item["target"])
        if target.nil? then
            return "(flt) target not found (#{item["target"]})"
        end
        "(flt) #{LxFunction::function("toString", target)}"
    end

    # ------------------------------------------------
    # Operations


end
