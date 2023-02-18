
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
end