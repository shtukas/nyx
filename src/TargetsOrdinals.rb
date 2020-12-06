
# encoding: UTF-8

class TargetOrdinals

    # TargetOrdinals::setTargetOrdinal(source, target, ordinal)
    def self.setTargetOrdinal(source, target, ordinal)
        KeyValueStore::set(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{source["uuid"]}:#{target["uuid"]}", ordinal)
    end

    # TargetOrdinals::getTargetOrdinal(source, target)
    def self.getTargetOrdinal(source, target)
        ordinal = KeyValueStore::getOrNull(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{source["uuid"]}:#{target["uuid"]}")
        if ordinal then
            return ordinal.to_f
        end
        ordinals = Arrows::getTargetsForSource(source)
                    .map{|t| KeyValueStore::getOrNull(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{source["uuid"]}:#{t["uuid"]}") }
                    .compact
                    .map{|o| o.to_f }
        ordinal = ([0] + ordinals).max + 1
        KeyValueStore::set(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{source["uuid"]}:#{target["uuid"]}", ordinal)
        ordinal
    end

    # TargetOrdinals::getSourceTargetsInOrdinalOrder(source)
    def self.getSourceTargetsInOrdinalOrder(source)
        Arrows::getTargetsForSource(source)
            .sort{|t1, t2| TargetOrdinals::getTargetOrdinal(source, t1) <=> TargetOrdinals::getTargetOrdinal(source, t2) }
    end
end
