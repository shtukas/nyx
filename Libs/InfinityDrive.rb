
# encoding: UTF-8

class InfinityDrive

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
