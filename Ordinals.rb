
# encoding: UTF-8

# ----------------------------------------------------------------------

# Ordinals::sortedDistribution()
# Ordinals::register(uuid, ordinal)
# Ordinals::unregister(uuid)
# Ordinals::uuids()
# Ordinals::getUUIDByOrdinalOrNull(ordinal)
# Ordinals::transform()

class Ordinals
    def self.sortedDistribution()
        JSON.parse(FKVStore::getOrDefaultValue("2f02529d-6ec3-453a-96e8-c900eb25b192", "[]"))
            .sort{|pair1, pair2| pair1[1]<=>pair2[1] }
    end
    def self.register(uuid, ordinal)
        distribution = Ordinals::sortedDistribution()
        # pairs are (uuid: String, ordinal: Float)
        distribution.reject!{|pair| pair[0]==uuid }
        distribution << [uuid, ordinal]
        FKVStore::set("2f02529d-6ec3-453a-96e8-c900eb25b192", JSON.generate(distribution))
    end
    def self.unregister(uuid)
        distribution = Ordinals::sortedDistribution()
        # pairs are (uuid: String, ordinal: Float)
        distribution.reject!{|pair| pair[0]==uuid }
        FKVStore::set("2f02529d-6ec3-453a-96e8-c900eb25b192", JSON.generate(distribution))
    end
    def self.uuids()
        Ordinals::sortedDistribution().map{|pair| pair[0] }
    end
    def self.getUUIDByOrdinalOrNull(ordinal)
        pair = Ordinals::sortedDistribution().select{|pair| pair[1].to_s == ordinal.to_s }.first
        return nil if pair.nil?
        pair[0]
    end
    def self.transform()
        uuids = Ordinals::uuids()
        TheFlock::flockObjects().each{|object|
            if uuids.include?(object["uuid"]) and object["metric"]<=1 then
                object["metric"] = 0
                TheFlock::addOrUpdateObject(object)
            end
        }
    end
end
