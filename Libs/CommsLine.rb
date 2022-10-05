# encoding: UTF-8

class CommsLine

    # CommsLine::pathToStaging()
    def self.pathToStaging()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataStaging/CommsLine"
    end

    # CommsLine::pathToActive()
    def self.pathToActive()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-ActiveCommsLine"
    end

    # CommsLine::moveCarefully(verbose)
    def self.moveCarefully(verbose)
        Machines::theOtherInstanceIds().each{|instanceId|
            stagingfolder = "#{CommsLine::pathToStaging()}/#{instanceId}"
            activefolder = "#{CommsLine::pathToActive()}/#{instanceId}"
            if LucilleCore::locationsAtFolder(activefolder).size < 500 then
                LucilleCore::locationsAtFolder(stagingfolder)
                    .first(1000)
                    .each{|filepath1|
                        filepath2 = "#{activefolder}/#{File.basename(filepath1)}"
                        if verbose then
                            puts "Moving:"
                            puts "    - #{filepath1}"
                            puts "    - #{filepath2}"
                        end
                        FileUtils.mv(filepath1, filepath2)
                    }
            end
        }
    end
end
