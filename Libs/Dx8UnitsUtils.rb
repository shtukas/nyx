
# encoding: UTF-8

class Dx8UnitsUtils
    # Dx8UnitsUtils::infinityRepository()
    def self.infinityRepository()
        "/Volumes/Infinity/Data/Pascal/Stargate-Central/Dx8Units"
    end

    # Dx8UnitsUtils::acquireUnit(dx8UnitId)
    def self.acquireUnit(dx8UnitId) # returns the location of the unit, or nil if it could not be acquired

        location1 = XCache::filepath("213a1c6e-df37-46ed-95b2-15ef742c5512:#{dx8UnitId}")
        if File.exists?(location1) then
            return location1
        end

        # We could not find the file in xcache, now looking in stargate central
        status = StargateCentral::askForInfinityReturnBoolean()

        if status then
            location2 = "#{Dx8UnitsUtils::infinityRepository()}/#{dx8UnitId}"
            if File.exists?(location2) then
                puts "copying Dx8Unit #{dx8UnitId} from Stargate Central to local (XCache)".green
                FileUtils.cp(location2, location1)
                location1
            else
                nil
            end
        else
            nil
        end
    end
end
