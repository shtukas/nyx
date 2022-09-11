
# encoding: UTF-8

class Dx8UnitsUtils

    # Dx8UnitsUtils::repository()
    def self.repository()
        "/Volumes/EnergyGrid1/Data/Pascal/Galaxy/Dx8Units"
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
        return nil if !status
        folderpath1 = "#{Dx8UnitsUtils::repository()}/#{dx8UnitId}"
        folderpath2 = "#{Config::userHomeDirectory()}/Galaxy/Orbital/Multi-Instance/Dx8Units/#{dx8UnitId}"
        if File.exists?(folderpath1) and !File.exists?(folderpath2) then
            puts "Dx8Unit, move:"
            puts "    - #{folderpath1}"
            puts "    - #{folderpath2}"
            FileUtils.mv(folderpath1, folderpath2)
        end
        if File.exists?(folderpath2) then
            return folderpath2
        end
        nil
    end

    # Dx8UnitsUtils::destroyUnit(dx8UnitId)
    def self.destroyUnit(dx8UnitId)
        [
            "#{Config::userHomeDirectory()}/Galaxy/Orbital/Multi-Instance/Dx8Units/#{dx8UnitId}",
            "#{Dx8UnitsUtils::repository()}/#{dx8UnitId}"
        ].each{|folderpath|
            if File.exists?(folderpath) then
                puts "Dx8Unit, destroy, remove folder: #{folderpath}"
                LucilleCore::removeFileSystemLocation(folderpath)
            end
        }
    end
end
