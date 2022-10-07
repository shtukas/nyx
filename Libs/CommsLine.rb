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
        locationsAtFolder = lambda {|folder|
            LucilleCore::locationsAtFolder(folder)
                .select{|location| !File.basename(location).start_with?(".") }
        }
        Machines::theOtherInstanceIds().each{|instanceId|
            stagingfolder = "#{CommsLine::pathToStaging()}/#{instanceId}"
            activefolder = "#{CommsLine::pathToActive()}/#{instanceId}"
            if locationsAtFolder.call(activefolder).size < 500 then
                locationsAtFolder.call(stagingfolder)
                    .first(1000)
                    .each{|filepath1|
                        filepath2 = "#{activefolder}/#{File.basename(filepath1)}"
                        if verbose then
                            puts "Moving #{File.basename(filepath1)} to #{instanceId}"
                        end
                        FileUtils.mv(filepath1, filepath2)
                    }
            end
        }
    end
end
