
class NxTriages

    # ------------------
    # IO

    # NxTriages::items()
    def self.items()
        ObjectStore2::objects("NxTriages")
    end

    # NxTriages::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxTriages", item)
    end

    # NxTriages::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxTriages", uuid)
    end

    # ------------------
    # Makers

    # NxTriages::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(DatablobStoreElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}" 
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTriage",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref
        }
        ObjectStore2::commit("NxTriages", item)
        item
    end

    # ------------------
    # Data

    # NxTriages::toString(item)
    def self.toString(item)
        "(triage) #{item["description"]} (coredataref: #{item["field11"]})"
    end

    # NxTriages::listingItems()
    def self.listingItems()
        NxTriages::items()
    end

    # ------------------
    # Ops

    # NxTriages::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
