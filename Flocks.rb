
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
        NyxObjects::getSet("4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f")
    end

    # Flocks::flockToString(flock)
    def self.flockToString(flock)
        fragments = Flocks::getFragmentsForFlock(flock)
        if fragments.size == 0 then
            return "[flock] no fragment"
        end
        "[flock] #{Fragments::fragmentToString(fragments[0])}"
    end

    # Flocks::getFlocksForSource(source)
    def self.getFlocksForSource(source)
        Arrows::getTargetOfGivenSetsForSource(source, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # Flocks::getFragmentsForFlock(flock)
    def self.getFragmentsForFlock(flock)
        Arrows::getTargetsForSourceUUID(flock["uuid"])
    end

    # Flocks::getFlockForFragment(fragment)
    def self.getFlockForFragment(fragment)
        # Technically we could have a fragment belonging to more than one Flock
        # We could also have a fragment belonging to zero Flock
        # We are going to blatently assume that will never happen that the set of Flocks for a Fragment is always only of size 1

        # We are not going to assume that the sources of a fragment are always a flock, because fragments used to be targetted by other things
        Arrows::getSourceOfGivenSetsForTarget(fragment, ["c18e8093-63d6-4072-8827-14f238975d04"]).first
    end

    # Flocks::getLastFlockFragmentOrNull(flock)
    def self.getLastFlockFragmentOrNull(flock)
        Flocks::getFragmentsForFlock(flock)
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
            .last
    end
end
