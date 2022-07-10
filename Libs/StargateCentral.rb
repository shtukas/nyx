class StargateCentral

    # StargateCentral::pathToCentral()
    def self.pathToCentral()
        "/Volumes/Infinity/Data/Pascal/Stargate-Central"
    end

    # StargateCentral::askForInfinityReturnBoolean()
    def self.askForInfinityReturnBoolean()
        if !File.exists?(StargateCentral::pathToCentral()) then
            puts "Please plug the Infinity drive"
            LucilleCore::pressEnterToContinue()
        end
        File.exists?(StargateCentral::pathToCentral())
    end

    # StargateCentral::askForInfinityAndFailIfNot()
    def self.askForInfinityAndFailIfNot()
        status = StargateCentral::askForInfinityReturnBoolean()
        if !status then
            puts "Could not find the Infinity drive. Exiting."
            exit
        end
    end
end

class StargateCentralData

    # StargateCentralData::propagateDataFromLocalToCentral()
    def self.propagateDataFromLocalToCentral()
        Find.find("#{Config::pathToDataBankStargate()}/Data") do |path|
            next if File.directory?(path)
            next if File.basename(path)[0, 1] == "."

            filename = File.basename(path)

            fragment = (lambda {|filename|
                if filename.start_with?("SHA256-") then
                    filename[7, 2] # datablob (.data), aion-points (.data-island.sqlite3)
                else
                    filename[0, 2] # primitive file (.primitive-file-island.sqlite3)
                end
            }).call(filename)

            filepath2 = "#{StargateCentral::pathToCentral()}/Data/#{fragment}/#{filename}"

            if File.exists?(filepath2) then
                next
            end

            if !File.exists?(File.dirname(filepath2)) then
                FileUtils.mkdir(File.dirname(filepath2))
            end

            puts "copying file: #{path}"
            FileUtils.cp(path, filepath2)
        end
    end
end
