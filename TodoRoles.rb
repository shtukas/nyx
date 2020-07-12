
# encoding: UTF-8

class TodoRoles

    # TodoRoles::objectToString(object)
    def self.objectToString(object)
        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            return Waves::waveToString(object)
        end
        if object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398" then
            return Asteroids::asteroidToString(object)
        end
        puts object
        raise "Error: 056686f0"
    end

    # TodoRoles::objectDive(object)
    def self.objectDive(object)
        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            puts "There isn't currently a dive function for Waves"
            return
        end
        if object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398" then
            Asteroids::asteroidDive(object)
            return
        end
        puts object
        raise "Error: cf25ea33"
    end

    # TodoRoles::getRolesForTarget(targetuuid)
    def self.getRolesForTarget(targetuuid)
        [
            # We are not doing the Waves as they have no target
            Asteroids::getAsteroidsTypeQuarkByQuarkUUID(targetuuid)
        ].flatten
    end
end
