
# encoding: UTF-8

class Dx8UnitsUtils
    # Dx8UnitsUtils::infinityRepository()
    def self.infinityRepository()
        "#{StargateCentral::pathToCentral()}/Dx8Units"
    end

    # Dx8UnitsUtils::acquireUnit(dx8UnitId)
    def self.acquireUnit(dx8UnitId)
        "#{Dx8UnitsUtils::infinityRepository()}/#{dx8UnitId}"
    end
end
