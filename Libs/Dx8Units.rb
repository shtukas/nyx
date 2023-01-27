
# encoding: UTF-8

class Dx8Units

    # Dx8Units::repository()
    def self.repository()
        "/Volumes/Orbital1/Data/Pascal/Galaxy/Dx8Units"
    end

    # Dx8Units::attemptRepository()
    def self.attemptRepository() # Boolean # Indicates whether we got there or not
        return true if File.exist?(Dx8Units::repository())
        puts "I need Orbital1. Please plug".green
        LucilleCore::pressEnterToContinue()
        File.exist?(Dx8Units::repository())
    end

    # Dx8Units::acquireUnitFolderPathOrNull(dx8UnitId)
    def self.acquireUnitFolderPathOrNull(dx8UnitId)

        status = Dx8Units::attemptRepository()
        if !status then
            puts "Dx8Unit is not currently available (can't see Orbital1)"
            LucilleCore::pressEnterToContinue()
            return nil
        end

        location = "#{Dx8Units::repository()}/#{dx8UnitId}"
        if File.exist?(location) then
            return location
        end

        return nil
    end

    # Dx8Units::access(unitId)
    def self.access(unitId)
        location = Dx8Units::acquireUnitFolderPathOrNull(unitId)
        if location.nil? then
            puts "I could not acquire the Dx8Unit. Aborting operation."
            LucilleCore::pressEnterToContinue()
            return
        end
        puts "location: #{location}"
        if LucilleCore::locationsAtFolder(location).size == 1 and LucilleCore::locationsAtFolder(location).first[-5, 5] == ".webm" then
            location2 = LucilleCore::locationsAtFolder(location).first
            if File.basename(location2).include?("'") then
                location3 = "#{File.dirname(location2)}/#{File.basename(location2).gsub("'", "-")}"
                FileUtils.mv(location2, location3)
                location2 = location3
            end
            location = location2
        end
        system("open '#{location}'")
        LucilleCore::pressEnterToContinue()
    end
end
