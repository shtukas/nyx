
# encoding: UTF-8

class Dx8UnitsUtils
    # Dx8UnitsUtils::infinityRepository()
    def self.infinityRepository()
        "/Users/pascal/Galaxy/DataBank/Dx8Units"
    end

    # Dx8UnitsUtils::dx8UnitFolder(dx8UnitId)
    def self.dx8UnitFolder(dx8UnitId)
        raise "(error: 75b81666-3dc7-4907-9a26-9288af966d6e) incorrect argument for Dx8UnitsUtils::dx8UnitFolder" if (dx8UnitId.nil? or dx8UnitId == "")
        "#{Dx8UnitsUtils::infinityRepository()}/#{dx8UnitId}"
    end
end
