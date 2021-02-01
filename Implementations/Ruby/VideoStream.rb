
# encoding: UTF-8

class VideoStream

    # VideoStream::spaceFolderpath()
    def self.spaceFolderpath()
        "/Users/pascal/x-space/VideoStream"
    end

    # VideoStream::videoFilepaths()
    def self.videoFilepaths()
        folderpath = VideoStream::spaceFolderpath()
        raise "[error: efd09076-971c-46e7-95cd-4923a72c0f04]" if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "#{folderpath}/#{filename}" }
            .sort
    end

    # VideoStream::displayItemsNS16()
    def self.displayItemsNS16()
        raise "[error: 61cb51f1-ad91-4a94-974b-c6c0bdb4d41f]" if !File.exists?(VideoStream::spaceFolderpath())
        return [] if BankExtended::recoveredDailyTimeInHours("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c02") > 1
        VideoStream::videoFilepaths()
            .reduce([]){|filepaths, filepath|
                if filepaths.size >= 3 then
                    filepaths
                else
                    if DoNotShowUntil::isVisible(filepath) then
                        filepaths + [filepath]
                    else
                        filepaths
                    end
                end
            }
            .map{|filepath| 
                {
                    "announce" => "[VideoStream] #{File.basename(filepath)}",
                    "lambda"   => lambda { VideoStream::access(filepath) },
                }
            }
    end

    # VideoStream::access(filepath)
    def self.access(filepath)
        if filepath.include?("'") then
            filepath2 = filepath.gsub("'", '-')
            FileUtils.mv(filepath, filepath2)
            filepath = filepath2
        end

        stopAndRecordTime = lambda {|uuid|
            timespan = Runner::stop(uuid)
            puts "Watched for #{timespan} seconds"
            timespan = [timespan, 3600*2].min
            timespan = [timespan, 300].max
            puts "Adding #{timespan} seconds to bank"
            Bank::put("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c02", timespan)
        }

        puts filepath

        if Runner::isRunning?(filepath) then
            if LucilleCore::askQuestionAnswerAsBoolean("-> completed? ", true) then
                FileUtils.rm(filepath)
                stopAndRecordTime.call(filepath)
            end
        else
            option = LucilleCore::askQuestionAnswerAsString("> play (default) ; completed : ")
            if option == "" then
                option = "play"
            end
            if option == "play" then
                Runner::start(filepath)
                system("open '#{filepath}'")
                if LucilleCore::askQuestionAnswerAsBoolean("completed ? ", true) then
                    FileUtils.rm(filepath)
                    stopAndRecordTime.call(filepath)
                end
            end
            if option == "completed" then
                FileUtils.rm(filepath)
            end
        end
    end
end

