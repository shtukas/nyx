
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
        frames = Flocks::getFramesForFlock(flock)
        description = DescriptionZ::getLastDescriptionForTargetOrNull(flock["uuid"])
        if description then
            frametype =
                if frames.size > 0 then
                    frametype = " [#{frames.last["type"]}]"
                else
                    ""
                end
            return "[flock]#{frametype} #{description}"
        end
        if frames.size > 0 then
            return "[flock] #{Frames::frameToString(frames[0])}"
        end
        return "[flock] no description and no frame"
    end

    # Flocks::getFlocksForSource(source)
    def self.getFlocksForSource(source)
        Arrows::getTargetOfGivenSetsForSource(source, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # Flocks::getFramesForFlock(flock)
    def self.getFramesForFlock(flock)
        Arrows::getTargetsForSourceUUID(flock["uuid"])
    end

    # Flocks::getFlockForFrame(frame)
    def self.getFlockForFrame(frame)
        # Technically we could have a frame belonging to more than one Flock
        # We could also have a frame belonging to zero Flock
        # We are going to blatently assume that will never happen that the set of Flocks for a Frame is always only of size 1

        # We are not going to assume that the sources of a frame are always a flock, because frames used to be targetted by other things
        Arrows::getSourceOfGivenSetsForTarget(frame, ["c18e8093-63d6-4072-8827-14f238975d04"]).first
    end

    # Flocks::getLastFlockFrameOrNull(flock)
    def self.getLastFlockFrameOrNull(flock)
        Flocks::getFramesForFlock(flock)
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
            .last
    end

    # Flocks::openFlock(flock)
    def self.openFlock(flock)
        frame = Flocks::getLastFlockFrameOrNull(flock)
        return if frame.nil?
        Frames::openFrame(flock, frame)
    end

    # Flocks::giveDescriptionToFlockInteractively(flock)
    def self.giveDescriptionToFlockInteractively(flock)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        DescriptionZ::issue(flock["uuid"], description)
    end

    # Flocks::issueNewFlockAndItsFirstFrameInteractivelyOrNull()
    def self.issueNewFlockAndItsFirstFrameInteractivelyOrNull()
        puts "Making a new Flock..."
        frame = Frames::issueNewFrameInteractivelyOrNull()
        return nil if frame.nil?
        flock = Flocks::issue()
        Arrows::issue(flock, frame)
        Flocks::giveDescriptionToFlockInteractively(flock)
        flock
    end

    # Flocks::dive(flock)
    def self.dive(flock)
        loop {
            system("clear")
            puts Flocks::flockToString(flock)
            menuitems = LCoreMenuItemsNX1.new()
            menuitems.item(
                "update name",
                lambda { Flocks::giveDescriptionToFlockInteractively(flock) }
            )
            menuitems.item(
                "open",
                lambda { Flocks::openFlock(flock) }
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
end
