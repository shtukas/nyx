
# encoding: UTF-8

class VideoStream

    # VideoStream::spaceFolderpath()
    def self.spaceFolderpath()
        "/Users/pascal/x-space/VideoStream"
    end

    # VideoStream::videoFolderpathsAtFolder(folderpath)
    def self.videoFolderpathsAtFolder(folderpath)
        return [] if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "#{folderpath}/#{filename}" }
            .sort
    end

    # VideoStream::filepathToVideoUUID(filepath)
    def self.filepathToVideoUUID(filepath)
        Digest::SHA1.hexdigest("cec985f2-3287-4d3a-b4f8-a05f30a6cc52:#{filepath}")
    end

    # VideoStream::getVideoFilepathByUUIDOrNull(uuid)
    def self.getVideoFilepathByUUIDOrNull(uuid)
        VideoStream::videoFolderpathsAtFolder(VideoStream::spaceFolderpath())
            .select{|filepath| VideoStream::filepathToVideoUUID(filepath) == uuid }
            .first
    end
    # VideoStream::videoIsRunning(filepath)
    def self.videoIsRunning(filepath)
        uuid = "8410f77a-0624-442d-b413-f2be0fcce5ba:#{filepath}"
        Runner::isRunning?(uuid)
    end

    # VideoStream::displayItemsNS16()
    def self.displayItemsNS16()
        raise "[error: 61cb51f1-ad91-4a94-974b-c6c0bdb4d41f]" if !File.exists?(VideoStream::spaceFolderpath())
        return [] if BankExtended::recoveredDailyTimeInHours("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c02") > 1
        VideoStream::videoFolderpathsAtFolder(VideoStream::spaceFolderpath())
            .reduce([]){|filepaths, filepath|
                if filepaths.size >= 3 then
                    filepaths
                else
                    uuid = VideoStream::filepathToVideoUUID(filepath)
                    if DoNotShowUntil::isVisible(uuid) then
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
            filepath2 = filepath.gsub("'", ' ')
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
        uuid = "8410f77a-0624-442d-b413-f2be0fcce5ba:#{filepath}"
        isRunning = Runner::isRunning?(uuid)
        if isRunning then
            if LucilleCore::askQuestionAnswerAsBoolean("-> completed? ", true) then
                FileUtils.rm(filepath)
            end
            stopAndRecordTime.call(uuid)
        else
            options = ["play", "completed"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            if option == "play" then
                Runner::start(uuid)
                system("open '#{filepath}'")
                if LucilleCore::askQuestionAnswerAsBoolean("completed ? ", false) then
                    FileUtils.rm(filepath)
                    stopAndRecordTime.call(uuid)
                end
            end
            if option == "completed" then
                FileUtils.rm(filepath)
            end
        end

    end
end

