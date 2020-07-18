
# encoding: UTF-8

class NSDataType1

    # NSDataType1::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "c18e8093-63d6-4072-8827-14f238975d04",
            "unixtime" => Time.new.to_f
        }
        NyxObjects::put(object)
        object
    end

    # NSDataType1::ns1s()
    def self.ns1s()
        NyxObjects::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # NSDataType1::ns1ToString(ns1)
    def self.ns1ToString(ns1)
        ns0s = NSDataType1::getNSDataType0sForNSDataType1InTimeOrder(ns1)
        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns1)
        if description and ns0s.size > 0 then
            return "[ns1] [#{ns1["uuid"][0, 4]}] [#{ns0s.last["type"]}] #{description}"
        end
        if description and ns0s.size == 0 then
            return "[ns1] [#{ns1["uuid"][0, 4]}] #{description}"
        end
        if description.nil? and ns0s.size > 0 then
            return "[ns1] [#{ns1["uuid"][0, 4]}] #{NSDataType0s::ns0ToString(ns0s.last)}"
        end
        if description.nil? and ns0s.size == 0 then
            return "[ns1] [#{ns1["uuid"][0, 4]}] no description and no frame"
        end
    end

    # NSDataType1::getNSDataType1ForSource(source)
    def self.getNSDataType1ForSource(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # NSDataType1::getNSDataType0sForNSDataType1InTimeOrder(ns1)
    def self.getNSDataType0sForNSDataType1InTimeOrder(ns1)
        Arrows::getTargetsOfGivenSetsForSource(ns1, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataType1::getLastNSDataType1NSDataType0OrNull(ns1)
    def self.getLastNSDataType1NSDataType0OrNull(ns1)
        NSDataType1::getNSDataType0sForNSDataType1InTimeOrder(ns1)
            .last
    end

    # NSDataType1::giveDescriptionToNSDataType1Interactively(ns1)
    def self.giveDescriptionToNSDataType1Interactively(ns1)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        descriptionz = DescriptionZ::issue(description)
        Arrows::issue(ns1, descriptionz)
    end

    # NSDataType1::issueNewNSDataType1AndItsFirstNSDataType0InteractivelyOrNull()
    def self.issueNewNSDataType1AndItsFirstNSDataType0InteractivelyOrNull()
        puts "Making a new NSDataType1..."
        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
        return nil if ns0.nil?
        ns1 = NSDataType1::issue()
        Arrows::issue(ns1, ns0)
        NSDataType1::giveDescriptionToNSDataType1Interactively(ns1)
        ns1
    end

    # NSDataType1::landing(ns1)
    def self.landing(ns1)
        loop {
            break if NyxObjects::getOrNull(ns1["uuid"]).nil?
            system("clear")

            Miscellaneous::horizontalRule(false)

            puts NSDataType1::ns1ToString(ns1)

            puts ""

            puts "uuid: #{ns1["uuid"]}"
            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns1)
            if description then
                puts "description: #{description}"
            end
            puts "date: #{NavigationPoint::getReferenceDateTime(ns1)}"
            notetext = Notes::getMostRecentTextForSourceOrNull(ns1)
            if notetext then
                puts ""
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            puts ""

            menuitems = LCoreMenuItemsNX1.new()

            ns0 = NSDataType1::getLastNSDataType1NSDataType0OrNull(ns1)
            if ns0 then
                menuitems.item(
                    "open: #{NSDataType0s::ns0ToString(ns0)}",
                    lambda { NSDataType1::openLastNSDataType0(ns1) }
                )
            else
                puts "No frame found"
                menuitems.item(
                    "create ns0|frame",
                    lambda {
                        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
                        return if ns0.nil?
                        Arrows::issue(ns1, ns0)
                    }
                )
            end

            puts ""

            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns1)
            if description then
                menuitems.item(
                    "description (update)",
                    lambda{
                        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns1)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issue(ns1, descriptionz)
                    }
                )
            else
                menuitems.item(
                    "description (set)",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issue(ns1, descriptionz)
                    }
                )
            end
            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(NavigationPoint::getReferenceDateTime(ns1)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    datetimez = DateTimeZ::issue(datetime)
                    Arrows::issue(ns1, datetimez)
                }
            )
            menuitems.item(
                "top note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForSourceOrNull(ns1) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    note = Notes::issue(text)
                    Arrows::issue(ns1, note)
                }
            )
            menuitems.item(
                "destroy",
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns1 ? ") then
                        NyxObjects::destroy(ns1)
                    end
                }
            )

            Miscellaneous::horizontalRule(false)

            NavigationPoint::navigationComingFrom(ns1).each{|ns|
                menuitems.item(
                    NavigationPoint::toString("upstream   : ", ns),
                    NavigationPoint::navigationLambda(ns)
                )
            }

            puts ""

            NavigationPoint::navigationGoingTo(ns1).each{|ns|
                menuitems.item(
                    NavigationPoint::toString("downstream : ", ns),
                    NavigationPoint::navigationLambda(ns)
                )
            }

            puts ""

            menuitems.item(
                "add upstream",
                lambda {
                    ns = NavigationPoint::selectExistingNavigationPointOrNull()
                    return if ns.nil?
                    Arrows::issue(ns, ns1)
                }
            )

            menuitems.item(
                "add downstream",
                lambda {
                    ns = NavigationPoint::selectExistingNavigationPointOrNull()
                    return if ns.nil?
                    Arrows::issue(ns1, ns)
                }
            )

            menuitems.item(
                "remove upstream",
                lambda {
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", NavigationPoint::navigationComingFrom(ns1), lambda{|ns| NavigationPoint::toString("", ns) })
                    return if ns.nil?
                    Arrows::remove(ns, ns1)
                }
            )

            menuitems.item(
                "remove downstream",
                lambda {
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", NavigationPoint::navigationGoingTo(ns1), lambda{|ns| NavigationPoint::toString("", ns) })
                    return if ns.nil?
                    Arrows::remove(ns1, ns)
                }
            )

            puts ""

            status = menuitems.prompt()
            break if !status
        }
    end

    # NSDataType1::openLastNSDataType0(ns1)
    def self.openLastNSDataType0(ns1)
        ns0 = NSDataType1::getLastNSDataType1NSDataType0OrNull(ns1)
        if ns0.nil? then
            puts "I could not find ns0s for this ns1. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::openNSDataType0(ns1, ns0)
    end
end
