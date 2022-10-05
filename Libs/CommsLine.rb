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

    # CommsLine::processIncoming(verbose)
    def self.processIncoming(verbose)
        # New style. Keep while we process the remaining items
        # We are reading from the instance folder

        instanceId = Config::get("instanceId")

        folderpath = "#{CommsLine::pathToActive()}/#{instanceId}"

        LucilleCore::locationsAtFolder(folderpath)
            .each{|filepath1|

                next if !File.exists?(filepath1)
                next if File.basename(filepath1).start_with?(".")
                next if File.basename(filepath1).include?("sync-conflict")

                if CommonUtils::ends_with?(filepath1, ".system-events.jsonlines") then

                    if verbose then
                        puts "CommsLine::processIncoming: reading: #{File.basename(filepath1)}"
                    end

                    IO.read(filepath1)
                        .lines
                        .each{|line|
                            data = line.strip
                            next if data == ""
                            event = JSON.parse(data)
                            if verbose then
                                puts "event from system events: #{JSON.pretty_generate(event)}"
                            end
                            SystemEvents::internal(event)
                        }

                    FileUtils.rm(filepath1)
                    next
                end

                if CommonUtils::ends_with?(filepath1, ".file-datastore1") then
                    DataStore1::putDataByFilepathNoCommLine(filepath1)
                    FileUtils.rm(filepath1)
                    next
                end

                raise "(error: 600967d9-e9d4-4612-bf62-f8cc4f616fd1) I do not know how to process file: #{filepath1}"
            }
    end

    # CommsLine::moveCarefully()
    def self.moveCarefully()
        Machines::theOtherInstanceIds().each{|instanceId|
            stagingfolder = "#{CommsLine::pathToStaging()}/#{instanceId}"
            activefolder = "#{CommsLine::pathToActive()}/#{instanceId}"
            if LucilleCore::locationsAtFolder(activefolder).size < 500 then
                LucilleCore::locationsAtFolder(stagingfolder)
                    .first(1000)
                    .each{|filepath1|
                        filepath2 = "#{activefolder}/#{File.basename(filepath1)}"
                        puts "Moving:"
                        puts "    - #{filepath1}"
                        puts "    - #{filepath2}"
                        FileUtils.mv(filepath1, filepath2)
                    }
            end
        }
    end
end
