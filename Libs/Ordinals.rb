# encoding: UTF-8

class Ordinals
    # Ordinals::smallOrdinalForToday(id)
    def self.smallOrdinalForToday(id)
        ordinal = KeyValueStore::getOrNull(nil, "0bafab19-22b7-4270-9a45-3f03c5d91df3:#{Utils::today()}:#{id}")
        return ordinal.to_f if ordinal
        ordinal = rand
        KeyValueStore::set(nil, "0bafab19-22b7-4270-9a45-3f03c5d91df3:#{Utils::today()}:#{id}", ordinal)
        ordinal
    end
end
