
# encoding: UTF-8

class Flocks

    # Flocks::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "c18e8093-63d6-4072-8827-14f238975d04",
            "unixtime" => Time.new.to_f
        }
        NyxObjects::put(object)
        object
    end

    # Flocks::flocks()
    def self.flocks()
        NyxObjects::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # Flocks::flockToString(flock)
    def self.flockToString(flock)
        ns0s = Flocks::getNSDataType0sForFlock(flock)
        description = DescriptionZ::getLastDescriptionForSourceOrNull(flock)
        if description then
            ns0type =
                if ns0s.size > 0 then
                    ns0type = " [#{ns0s.last["type"]}]"
                else
                    ""
                end
            return "[flock]#{ns0type} #{description}"
        end
        if ns0s.size > 0 then
            return "[flock] #{NSDataType0s::ns0ToString(ns0s[0])}"
        end
        return "[flock] no description and no ns0"
    end

    # Flocks::getFlocksForSource(source)
    def self.getFlocksForSource(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # Flocks::getNSDataType0sForFlock(flock)
    def self.getNSDataType0sForFlock(flock)
        Arrows::getTargetsForSource(flock)
    end

    # Flocks::getLastFlockNSDataType0OrNull(flock)
    def self.getLastFlockNSDataType0OrNull(flock)
        Flocks::getNSDataType0sForFlock(flock)
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
            .last
    end

    # Flocks::giveDescriptionToFlockInteractively(flock)
    def self.giveDescriptionToFlockInteractively(flock)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        descriptionz = DescriptionZ::issue(description)
        Arrows::issue(flock, descriptionz)
    end

    # Flocks::issueNewFlockAndItsFirstNSDataType0InteractivelyOrNull()
    def self.issueNewFlockAndItsFirstNSDataType0InteractivelyOrNull()
        puts "Making a new Flock..."
        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
        return nil if ns0.nil?
        flock = Flocks::issue()
        Arrows::issue(flock, ns0)
        Flocks::giveDescriptionToFlockInteractively(flock)
        flock
    end

    # Flocks::landing(flock)
    def self.landing(flock)
        loop {
            system("clear")
            puts Flocks::flockToString(flock)
            puts "uuid: #{flock["uuid"]}"
            menuitems = LCoreMenuItemsNX1.new()
            menuitems.item(
                "update description",
                lambda { Flocks::giveDescriptionToFlockInteractively(flock) }
            )
            menuitems.item(
                "open",
                lambda { Flocks::openLastNSDataType0(flock) }
            )
            menuitems.item(
                "destroy",
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this flock ? ") then
                        NyxObjects::destroy(flock["uuid"])
                    end
                }
            )
            status = menuitems.prompt()
            break if !status
        }
    end

    # Flocks::openLastNSDataType0(flock)
    def self.openLastNSDataType0(flock)
        ns0 = Flocks::getLastFlockNSDataType0OrNull(flock)
        if ns0.nil? then
            puts "I could not find ns0s for this flock. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::openNSDataType0(flock, ns0)
    end
end
