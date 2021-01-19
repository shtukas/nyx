
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

    # VideoStream::metric(rdtih, indx)
    def self.metric(rdtih, indx)
        0.6 - 0.4*(1-Math.exp(-2*rdtih-indx.to_f/10))
    end

    # VideoStream::videoIsRunning(filepath)
    def self.videoIsRunning(filepath)
        uuid = "8410f77a-0624-442d-b413-f2be0fcce5ba:#{filepath}"
        Runner::isRunning?(uuid)
    end

    # VideoStream::catalystObjects()
    def self.catalystObjects()

        raise "[error: 61cb51f1-ad91-4a94-974b-c6c0bdb4d41f]" if !File.exists?(VideoStream::spaceFolderpath())

        recoveredDailyTimeInHours = BankExtended::recoveredDailyTimeInHours("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c02")

        makeObject = lambda{|filepath, rdtih, indx|
            isRunning = VideoStream::videoIsRunning(filepath)
            uuid = VideoStream::filepathToVideoUUID(filepath)
            metric = VideoStream::metric(rdtih, indx)
            metric = 1 if isRunning
            {
                "uuid"        => uuid,
                "body"        => "[VideoStream] #{File.basename(filepath)}#{isRunning ? " (running)" : ""}",
                "metric"      => metric,
                "landing"         => lambda { VideoStream::execute(filepath) },
                "nextNaturalStep" => lambda { VideoStream::execute(filepath) },
                "isRunning"   => isRunning,
                "x-video-stream" => true,
                "x-filepath"  => filepath
            }
        }

        objects = VideoStream::videoFolderpathsAtFolder(VideoStream::spaceFolderpath())
            .map
            .with_index{|filepath, indx| 
                {
                    "filepath" => filepath,
                    "index"    => indx
                }
            }
            .reduce([]){|items, item|
                if items.size >= 3 then
                    items
                else
                    uuid = VideoStream::filepathToVideoUUID(item["filepath"])
                    if DoNotShowUntil::isVisible(uuid) then
                        items + [item]
                    else
                        items
                    end
                end
            }
            .map{|item| 
                filepath = item["filepath"]
                indx     = item["index"]
                makeObject.call(filepath, recoveredDailyTimeInHours, indx) 
            }

        if objects.any?{|object| object["body"].include?("running") } then
            objects = objects.select{|object| object["body"].include?("running") }
        end

        objects
    end

    # VideoStream::playStopComplete(filepath)
    def self.playStopComplete(filepath)

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

    # VideoStream::execute(filepath)
    def self.execute(filepath)
        if filepath.include?("'") then
            filepath2 = filepath.gsub("'", ' ')
            FileUtils.mv(filepath, filepath2)
            filepath = filepath2
        end
        VideoStream::playStopComplete(filepath)
    end
end

