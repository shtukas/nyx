
# encoding: UTF-8

class Nx60s

    # ----------------------------------------------------------------------
    # IO

    # Nx60s::items()
    def self.items()
        LocalObjectsStore::getObjectsByMikuType("Nx60")
    end

    # Nx60s::getOrNull(uuid): null or Nx60
    def self.getOrNull(uuid)
        LocalObjectsStore::getObjectByUUIDOrNull(uuid)
    end

    # Nx60s::destroy(uuid)
    def self.destroy(uuid)
        LocalObjectsStore::logicaldelete(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx60s::issueClaim(owneruuid, targetuuid)
    def self.issueClaim(owneruuid, targetuuid)
        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        item = {
          "uuid"       => uuid,
          "mikuType"   => "Nx60",
          "unixtime"   => unixtime,
          "owneruuid"  => owneruuid,
          "targetuuid" => targetuuid
        }
        LocalObjectsStore::commit(item)
        item
    end
end