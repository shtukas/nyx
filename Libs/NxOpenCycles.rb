
class NxOpenCycles

    # NxOpenCycles::names()
    def self.names()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles")
            .map{|folderpath| File.basename(folderpath) }
            .select{|foldername| foldername[0, 1] != "." }
    end

    # NxOpenCycles::listingItems()
    def self.listingItems()
        [{
            "uuid" => "1057b16e-d486-4451-a165-67c92dfd5268", # same account a the scheduler1
            "mikuType" => "NxOpenCycles",
            "description" => "open cycles (general) [discard for day if nothing]"
        }]
    end
end