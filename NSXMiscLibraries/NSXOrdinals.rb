
# encoding: UTF-8

# ----------------------------------------------------------------------

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

class NSXOrdinals

    # NSXOrdinals::setOrdinal(objectuuid, value)
    def self.setOrdinal(objectuuid, value)
        KeyValueStore::set("/Galaxy/DataBank/Catalyst/OrdinalsKVStoreRepository", "3a3d1af7-477a-41c3-8f1f-7d8d4eb1fafd:#{objectuuid}", value)
    end

    # NSXOrdinals::getOrdinalOrNull(objectuuid)
    def self.getOrdinalOrNull(objectuuid)
        value = KeyValueStore::getOrNull("/Galaxy/DataBank/Catalyst/OrdinalsKVStoreRepository", "3a3d1af7-477a-41c3-8f1f-7d8d4eb1fafd:#{objectuuid}")
        return nil if value.nil?
        value.to_f
    end

    # NSXOrdinals::unsetOrdinal(objectuuid)
    def self.unsetOrdinal(objectuuid)
        KeyValueStore::destroy("/Galaxy/DataBank/Catalyst/OrdinalsKVStoreRepository", "3a3d1af7-477a-41c3-8f1f-7d8d4eb1fafd:#{objectuuid}")
    end

    # NSXOrdinals::ordinalToMetric(ordinal)
    def self.ordinalToMetric(ordinal)
        0.2*(Math.atan(ordinal).to_f/2) + 1.30
    end

    # NSXOrdinals::ordinalTransform(object)
    def self.ordinalTransform(object)
        ordinal = NSXOrdinals::getOrdinalOrNull(object["uuid"])
        return object if ordinal.nil?
        object[":meta:ordinal-257ca225"] = ordinal
        object[":meta:metric-before-ordinal-6d8a07af"] = object["metric"]
        object[":meta:is-ordinal-d5522ec9"] = true
        object["metric"] = NSXOrdinals::ordinalToMetric(ordinal)
        object["announce"] = "{ ordinal: #{ordinal} } #{object["announce"]}"
        if object["body"] then
            object["body"] = "{ ordinal: #{ordinal} } #{object["body"]}"
        end
        object
    end

end


