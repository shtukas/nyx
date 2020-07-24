
class Type1Type2CommonInterface

    # Type1Type2CommonInterface::objectIsType1(ns)
    def self.objectIsType1(ns)
        ns["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04"
    end

    # Type1Type2CommonInterface::objectIsType2(ns)
    def self.objectIsType2(ns)
        ns["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f"
    end

    # Type1Type2CommonInterface::toString(ns)
    def self.toString(ns)
        if Type1Type2CommonInterface::objectIsType1(ns) then
            return NSDataType1::cubeToString(ns)
        end
        if Type1Type2CommonInterface::objectIsType2(ns) then
            return NSDataType2::conceptToString(ns)
        end
        raise "[error: dd0dce2a]"
    end

    # Type1Type2CommonInterface::navigationLambda(ns)
    def self.navigationLambda(ns)
        if Type1Type2CommonInterface::objectIsType1(ns) then
            return lambda { NSDataType1::landing(ns) }
        end
        if Type1Type2CommonInterface::objectIsType2(ns) then
            return lambda { NSDataType2::landing(ns) }
        end
        raise "[error: fd3c6cff]"
    end

    # Type1Type2CommonInterface::getUpstreamConcepts(ns)
    def self.getUpstreamConcepts(ns)
        Arrows::getSourcesOfGivenSetsForTarget(ns, ["6b240037-8f5f-4f52-841d-12106658171f"])
    end

    # Type1Type2CommonInterface::getDownstreamObjects(ns)
    def self.getDownstreamObjects(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["c18e8093-63d6-4072-8827-14f238975d04", "6b240037-8f5f-4f52-841d-12106658171f"])
    end

    # Type1Type2CommonInterface::getDownstreamObjectsType1(ns)
    def self.getDownstreamObjectsType1(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # Type1Type2CommonInterface::getDownstreamObjectsType2(ns)
    def self.getDownstreamObjectsType2(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["6b240037-8f5f-4f52-841d-12106658171f"])
    end
end
