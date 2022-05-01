
# encoding: UTF-8

class InfinityDrive

    # InfinityDrive::driveIsPlugged()
    def self.driveIsPlugged()
        File.exists?(Dx8UnitsUtils::infinityRepository())
    end

    # InfinityDrive::ensureInfinityDrive()
    def self.ensureInfinityDrive()
        if !File.exists?(InfinityFsckBlobsService::infinityDatablobsRepository()) then
            puts "I need Infinity. Please plug 🙏"
            LucilleCore::pressEnterToContinue()
            if !File.exists?(InfinityFsckBlobsService::infinityDatablobsRepository()) then
                puts "Could not find Infinity. Exiting"
                exit
            end
        end
    end
end
