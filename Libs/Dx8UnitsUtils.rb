
# encoding: UTF-8

class Dx8UnitsUtils
    # Dx8UnitsUtils::infinityRepository()
    def self.infinityRepository()
        "/Volumes/Infinity/Data/Pascal/Stargate-Central/Dx8Units"
    end

    # Dx8UnitsUtils::acquireUnit(dx8UnitId)
    def self.acquireUnit(dx8UnitId) # returns the location of the unit, or nil if it could not be acquired

        status = StargateCentral::askForInfinityReturnBoolean()
        if !status then
            puts "Could not access dx8UnitId #{dx8UnitId}"
            return nil
        end

        location2 = "#{Dx8UnitsUtils::infinityRepository()}/#{dx8UnitId}"
        return location2 if File.exists?(location2)

        nil
    end
end
