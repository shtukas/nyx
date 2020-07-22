
class NavigationPoint

    # NavigationPoint::points()
    def self.points()
        NSDataType1::cubes() + NSDataType2::pages()
    end

    # NavigationPoint::objectIsType1(ns)
    def self.objectIsType1(ns)
        ns["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04"
    end

    # NavigationPoint::objectIsType2(ns)
    def self.objectIsType2(ns)
        ns["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f"
    end

    # NavigationPoint::toString(ns)
    def self.toString(ns)
        if NavigationPoint::objectIsType1(ns) then
            return NSDataType1::cubeToString(ns)
        end
        if NavigationPoint::objectIsType2(ns) then
            return NSDataType2::pageToString(ns)
        end
        raise "[error: dd0dce2a]"
    end

    # NavigationPoint::ufn(type)
    def self.ufn(type)
        return "frame" if type == "Type0"
        return "cube"  if type == "Type1"
        return "page"  if type == "Type2"
        raise "[error: 8AFB8E5E]"
    end

    # NavigationPoint::userFriendlyName(nyxobject)
    def self.userFriendlyName(nyxobject)
        return NavigationPoint::ufn("Type0") if nyxobject["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69"
        return NavigationPoint::ufn("Type1") if nyxobject["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04"
        return NavigationPoint::ufn("Type2") if nyxobject["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f"
        raise "[error: 6C1B48C7]"
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

    # NavigationPoint::getUpstreamNavigationPoints(ns)
    def self.getUpstreamNavigationPoints(ns)
        Arrows::getSourcesOfGivenSetsForTarget(ns, ["c18e8093-63d6-4072-8827-14f238975d04", "6b240037-8f5f-4f52-841d-12106658171f"])
    end

    # NavigationPoint::getDownstreamNavigationPoints(ns)
    def self.getDownstreamNavigationPoints(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["c18e8093-63d6-4072-8827-14f238975d04", "6b240037-8f5f-4f52-841d-12106658171f"])
    end

    # NavigationPoint::getDownstreamNavigationPointsType1(ns)
    def self.getDownstreamNavigationPointsType1(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # NavigationPoint::getDownstreamNavigationPointsType2(ns)
    def self.getDownstreamNavigationPointsType2(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["6b240037-8f5f-4f52-841d-12106658171f"])
    end
end

class NavigationPointSelection

    # NavigationPointSelection::selectExistingPageOrNull_standard(pages)
    def self.selectExistingPageOrNull_standard(pages)
        cliquestrings = pages.map{|ns| NSDataType2::pageToString(ns) }
        cliquestring = Miscellaneous::chooseALinePecoStyle("navigation point:", [""]+cliquestrings)
        return nil if cliquestring == ""
        pages
            .select{|ns| NSDataType2::pageToString(ns) == cliquestring }
            .first
    end

    # NavigationPointSelection::selectExistingPageOrNull()
    def self.selectExistingPageOrNull()
        pages = NSDataType2::pages()
        if pages.size <= 1000 then
            return NavigationPointSelection::selectExistingPageOrNull_standard(pages)
        end
        puts "I am going to make you make that selection in several stages"
        LucilleCore::pressEnterToContinue()
        while pages.size > 0 do
            subset = pages.shift(1000)
            answer = NavigationPointSelection::selectExistingPageOrNull_standard(subset)
            return answer if answer
        end
        nil
    end

    # NavigationPointSelection::selectExistingPageOrMakeNewPageOrNull()
    def self.selectExistingPageOrMakeNewPageOrNull()
        ns2 = NavigationPointSelection::selectExistingPageOrNull()
        return ns2 if ns2
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("You did not select a ns2, would you like to make one ? : ")
        NSDataType2::issueNewPageInteractivelyOrNull()
    end

    # NavigationPointSelection::selectExistingCubeOrNull()
    def self.selectExistingCubeOrNull()
        points = NSDataType1::cubes()
        cliquestrings = points.map{|ns| NSDataType2::pageToString(ns) }
        cliquestring = Miscellaneous::chooseALinePecoStyle("navigation point:", [""]+cliquestrings)
        return nil if cliquestring == ""
        points
            .select{|ns| NSDataType2::pageToString(ns) == cliquestring }
            .first
    end

end
