
class NxTriages

    # NxTriages::items()
    def self.items()
        ObjectStore2::objects("NxTriages")
    end

    # NxTriages::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(DatablobStoreElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}" 
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field2"      => "triage",
            "field11"     => coredataref
        }
        ObjectStore2::commit("NxTriages", item)
        item
    end

    # NxTriages::viennaUrlForToday(url)
    def self.viennaUrlForToday(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{DatablobStore::put(url)}"
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTriage",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field2"      => "ondate",
            "field11"     => coredataref,
        }
        ObjectStore2::commit("NxTriages", item)
        item
    end

    # NxTriages::listingItems()
    def self.listingItems()
        NxTriages::items()
    end

    # NxTriages::toString(item)
    def self.toString(item)
        "(triage) #{item["description"]} (coredataref: #{item["field11"]})"
    end
end