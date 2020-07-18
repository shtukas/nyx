
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
        if description then
            ns0type =
                if ns0s.size > 0 then
                    ns0type = " [#{ns0s.last["type"]}]"
                else
                    ""
                end
            return "[ns1]#{ns0type} #{description}"
        end
        if ns0s.size > 0 then
            return "[ns1] #{NSDataType0s::ns0ToString(ns0s[0])}"
        end
        return "[ns1] no description and no ns0"
    end

    # NSDataType1::getNSDataTypesParentsForNSDataType1(ns1)
    def self.getNSDataTypesParentsForNSDataType1(ns1)
        Arrows::getSourcesOfGivenSetsForTarget(ns1, ["6b240037-8f5f-4f52-841d-12106658171f", "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
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
            puts NSDataType1::ns1ToString(ns1)
            puts ""
            puts "uuid: #{ns1["uuid"]}"
            puts ""
            menuitems = LCoreMenuItemsNX1.new()
            menuitems.item(
                "open",
                lambda { NSDataType1::openLastNSDataType0(ns1) }
            )
            menuitems.item(
                "update description",
                lambda { NSDataType1::giveDescriptionToNSDataType1Interactively(ns1) }
            )
            menuitems.item(
                "destroy",
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns1 ? ") then
                        NyxObjects::destroy(ns1)
                    end
                }
            )
            puts ""
            NSDataType1::getNSDataTypesParentsForNSDataType1(ns1).each{|ns|
                if ns["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f" then
                    menuitems.item(
                        "parent (type2): #{NSDataType2::ns2ToString(ns)}",
                        lambda { NSDataType2::landing(ns) }
                    )
                end
                if ns["nyxNxSet"] == "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5" then
                    menuitems.item(
                        "parent (type3): #{NSDataType3::ns3ToString(ns)}",
                        lambda { NSDataType3::landing(ns) }
                    )
                end
            }

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
