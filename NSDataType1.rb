
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
        ns0s = NSDataType1::getNSDataType0sForNSDataType1(ns1)
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

    # NSDataType1::getNSDataType1ForSource(source)
    def self.getNSDataType1ForSource(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # NSDataType1::getNSDataType0sForNSDataType1(ns1)
    def self.getNSDataType0sForNSDataType1(ns1)
        Arrows::getTargetsForSource(ns1)
    end

    # NSDataType1::getLastNSDataType1NSDataType0OrNull(ns1)
    def self.getLastNSDataType1NSDataType0OrNull(ns1)
        NSDataType1::getNSDataType0sForNSDataType1(ns1)
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
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
            system("clear")
            puts NSDataType1::ns1ToString(ns1)
            puts "uuid: #{ns1["uuid"]}"
            menuitems = LCoreMenuItemsNX1.new()
            menuitems.item(
                "update description",
                lambda { NSDataType1::giveDescriptionToNSDataType1Interactively(ns1) }
            )
            menuitems.item(
                "open",
                lambda { NSDataType1::openLastNSDataType0(ns1) }
            )
            menuitems.item(
                "destroy",
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns1 ? ") then
                        NyxObjects::destroy(ns1["uuid"])
                    end
                }
            )
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
