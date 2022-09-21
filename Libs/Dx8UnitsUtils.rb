
# encoding: UTF-8

class Dx8UnitsUtils

    # Dx8UnitsUtils::energyGridRepository()
    def self.repository()
        "/Volumes/EnergyGrid1/Data/Pascal/Galaxy/Stargate/Dx8Units"
    end

    # Dx8UnitsUtils::orbitalMultiInstnceRepository()
    def self.orbitalMultiInstnceRepository()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Dx8Units"
    end

    # Dx8UnitsUtils::attemptRepository()
    def self.attemptRepository() # Boolean # Indicates whether we got there or not
        return true if File.exists?(Dx8UnitsUtils::energyGridRepository())
        puts "I need the EnergyGrid1 drive, please plug".green
        LucilleCore::pressEnterToContinue()
        File.exists?(Dx8UnitsUtils::energyGridRepository())
    end

    # Dx8UnitsUtils::acquireUnitFolderPathOrNull(dx8UnitId)
    def self.acquireUnitFolderPathOrNull(dx8UnitId)
        location = "#{Dx8UnitsUtils::orbitalMultiInstnceRepository()}/#{dx8UnitId}"
        return location if File.exists?(location)

        status = Dx8UnitsUtils::attemptRepository()
        if !status then
            puts "Dx8Unit is not currently available (can't see EnergyGrid)"
            LucilleCore::pressEnterToContinue()
            return nil
        end

        location = "#{Dx8UnitsUtils::energyGridRepository()}/#{dx8UnitId}"
        return location if File.exists?(location)

        puts "Dx8Unit is not currently (neither on local nor EnergyGrid)"
        LucilleCore::pressEnterToContinue()
        return nil
    end
end
