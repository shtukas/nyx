
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
        if frames.size == 0 then
            return "[flock] no frame"
        end
        "[flock] #{Frames::frameToString(frames[0])}"
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
end
