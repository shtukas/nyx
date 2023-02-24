
class NxOpenCycles

    # NxOpenCycles::names()
    def self.names()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles")
            .map{|folderpath| File.basename(folderpath) }
            .select{|foldername| foldername[0, 1] != "." }
    end

    # NxOpenCycles::program()
    def self.program()
        NxOpenCycles::names().each{|foldername|
            unixtime = Lookups::getValueOrNull("NxOpenCyclesAcknowledgements", foldername) || 0
            if (Time.new.to_i - unixtime) > 86400 then
                puts "opencycles monitoring name: #{foldername.green}"
                LucilleCore::pressEnterToContinue()
                Lookups::commit("NxOpenCyclesAcknowledgements", foldername, Time.new.to_i)
            end
        }
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