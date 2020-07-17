
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
        cubes = Flocks::getCubesForFlock(flock)
        description = DescriptionZ::getLastDescriptionForSourceOrNull(flock)
        if description then
            cubetype =
                if cubes.size > 0 then
                    cubetype = " [#{cubes.last["type"]}]"
                else
                    ""
                end
            return "[flock]#{cubetype} #{description}"
        end
        if cubes.size > 0 then
            return "[flock] #{Cubes::cubeToString(cubes[0])}"
        end
        return "[flock] no description and no cube"
    end

    # Flocks::getFlocksForSource(source)
    def self.getFlocksForSource(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["c18e8093-63d6-4072-8827-14f238975d04"])
    end

    # Flocks::getHypercubesForFlock(flock)
    def self.getHypercubesForFlock(flock)
        Arrows::getSourcesOfGivenSetsForTarget(flock, ["6b240037-8f5f-4f52-841d-12106658171f"])
    end

    # Flocks::getCubesForFlock(flock)
    def self.getCubesForFlock(flock)
        Arrows::getTargetsForSource(flock)
    end

    # Flocks::getLastFlockCubeOrNull(flock)
    def self.getLastFlockCubeOrNull(flock)
        Flocks::getCubesForFlock(flock)
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

    # Flocks::issueNewFlockAndItsFirstCubeInteractivelyOrNull()
    def self.issueNewFlockAndItsFirstCubeInteractivelyOrNull()
        puts "Making a new Flock..."
        cube = Cubes::issueNewCubeInteractivelyOrNull()
        return nil if cube.nil?
        flock = Flocks::issue()
        Arrows::issue(flock, cube)
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
                lambda { Flocks::openLastCube(flock) }
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

    # Flocks::openLastCube(flock)
    def self.openLastCube(flock)
        cube = Flocks::getLastFlockCubeOrNull(flock)
        if cube.nil? then
            puts "I could not find cubes for this flock. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        Cubes::openCube(flock, cube)
    end
end
