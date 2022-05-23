
# encoding: UTF-8

class InfinityDriveUtils

    # InfinityDriveDidactUtils::driveIsPlugged()
    def self.driveIsPlugged()
        File.exists?(Config::pathToInfinityLibrarian())
    end

    # InfinityDriveDidactUtils::ensureInfinityDrive()
    def self.ensureInfinityDrive()
        if !InfinityDriveDidactUtils::driveIsPlugged() then
            puts "I need Infinity. Please plug 🙏"
            LucilleCore::pressEnterToContinue()
            if !InfinityDriveDidactUtils::driveIsPlugged() then
                puts "Could not find Infinity 😞 Exiting."
                exit
            end
        end
    end
end
