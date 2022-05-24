
# encoding: UTF-8

class InfinityDriveUtils

    # InfinityDriveUtils::driveIsPlugged()
    def self.driveIsPlugged()
        File.exists?("/Volumes/Infinity/Data/Pascal/TheLibrarian")
    end

    # InfinityDriveUtils::ensureInfinityDrive()
    def self.ensureInfinityDrive()
        if !InfinityDriveUtils::driveIsPlugged() then
            puts "I need Infinity. Please plug 🙏"
            LucilleCore::pressEnterToContinue()
            if !InfinityDriveUtils::driveIsPlugged() then
                puts "Could not find Infinity 😞 Exiting."
                exit
            end
        end
    end
end
