
# encoding: UTF-8

class Dx8UnitsUtils

    # Dx8UnitsUtils::repository()
    def self.repository()
        "/Volumes/EnergyGrid1/Stargate-EnergyGrid/Dx8Units"
    end

    # Dx8UnitsUtils::attemptRepository()
    def self.attemptRepository() # Boolean # Indicates whether we got there or not
        return true if File.exists?(Dx8UnitsUtils::repository())
        puts "I need the EnergyGrid1 drive, please plug".green
        LucilleCore::pressEnterToContinue()
        File.exists?(Dx8UnitsUtils::repository())
    end

    # Dx8UnitsUtils::acquireUnitFolderPathOrNull(dx8UnitId)
    def self.acquireUnitFolderPathOrNull(dx8UnitId)

        status = Dx8UnitsUtils::attemptRepository()
        if !status then
            puts "Dx8Unit is not currently available (can't see EnergyGrid)"
            LucilleCore::pressEnterToContinue()
            return nil
        end

        location = "#{Dx8UnitsUtils::repository()}/#{dx8UnitId}"
        if File.exists?(location) then
            return location
        end

        return nil
    end
end
