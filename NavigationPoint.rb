
class NavigationPoint

    # NavigationPoint::points()
    def self.points()
        NSDataType1::ns1s() + NSDataType2::ns2s()
    end

    # NavigationPoint::objectIsType1(ns)
    def self.objectIsType1(ns)
        ns["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04"
    end

    # NavigationPoint::objectIsType2(ns)
    def self.objectIsType2(ns)
        ns["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f"
    end

    # NavigationPoint::toString(prefix, ns)
    def self.toString(prefix, ns)
        if NavigationPoint::objectIsType1(ns) then
            return "#{prefix}#{NSDataType1::ns1ToString(ns)}"
        end
        if NavigationPoint::objectIsType2(ns) then
            return "#{prefix}#{NSDataType2::ns2ToString(ns)}"
        end
        raise "[error: dd0dce2a]"
    end

    # NavigationPoint::navigationLambda(ns)
    def self.navigationLambda(ns)
        if NavigationPoint::objectIsType1(ns) then
            return lambda { NSDataType1::landing(ns) }
        end
        if NavigationPoint::objectIsType2(ns) then
            return lambda { NSDataType2::landing(ns) }
        end
        raise "[error: fd3c6cff]"
    end

    # NavigationPoint::navigationComingFrom(ns)
    def self.navigationComingFrom(ns)
        Arrows::getSourcesOfGivenSetsForTarget(ns, ["c18e8093-63d6-4072-8827-14f238975d04", "6b240037-8f5f-4f52-841d-12106658171f"])
    end

    # NavigationPoint::navigationGoingTo(ns)
    def self.navigationGoingTo(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["c18e8093-63d6-4072-8827-14f238975d04", "6b240037-8f5f-4f52-841d-12106658171f"])
    end

    # NavigationPoint::navigationGoingToType1(ns)
    def self.navigationGoingToType1(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # NavigationPoint::picoStyleSelectOrNull()
    def self.picoStyleSelectOrNull()
        points = NSDataType2::ns2s()
        cliquestrings = points.map{|ns| NSDataType2::ns2ToString(ns) }
        cliquestring = Miscellaneous::chooseALinePecoStyle("navigation point:", [""]+cliquestrings)
        return nil if cliquestring == ""
        points
            .select{|ns| NSDataType2::ns2ToString(ns) == cliquestring }
            .first
    end

    # NavigationPoint::selectExistingNavigationPointOrNull()
    def self.selectExistingNavigationPointOrNull()
        NavigationPoint::picoStyleSelectOrNull()
    end

    # NavigationPoint::getReferenceDateTime(ns)
    def self.getReferenceDateTime(ns)
        datetime = DateTimeZ::getLastDateTimeISO8601ForSourceOrNull(ns)
        return datetime if datetime
        Time.at(ns["unixtime"]).utc.iso8601
    end

    # NavigationPoint::getReferenceUnixtime(ns)
    def self.getReferenceUnixtime(ns)
        DateTime.parse(NavigationPoint::getReferenceDateTime(ns)).to_time.to_f
    end

end
