
# encoding: UTF-8

class VideoStream

    # VideoStream::spaceFolderpath()
    def self.spaceFolderpath()
        "/Users/pascal/Galaxy/Open-Projects/YouTube Videos"
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

    # VideoStream::metric(indx)
    def self.metric(indx)
        0.2 + 0.7*Math.exp(-BankExtended::recoveredDailyTimeInHours("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c01")) - indx.to_f/1000000
    end

    # VideoStream::catalystObjects()
    def self.catalystObjects()

        raise "[error: 61cb51f1-ad91-4a94-974b-c6c0bdb4d41f]" if !File.exists?(VideoStream::spaceFolderpath())

        objects = []

        VideoStream::videoFolderpathsAtFolder(VideoStream::spaceFolderpath())
            .first(3)
            .map
            .with_index{|filepath, indx|
                uuid = VideoStream::filepathToVideoUUID(filepath)
                objects << {
                    "uuid"        => uuid,
                    "body"        => "[VideoStream] #{File.basename(filepath)}",
                    "metric"      => VideoStream::metric(indx),
                    "execute"     => lambda { |input| VideoStream::execute(filepath) },
                    "x-video-stream" => true,
                    "x-filepath"  => filepath
                }
            }

        objects
    end

    # VideoStream::play(filepath)
    def self.play(filepath)
        startTime = Time.new.to_f
        puts filepath
        if filepath.include?("'") then
            filepath2 = filepath.gsub("'", ',')
            FileUtils.mv(filepath, filepath2)
            filepath = filepath2
        end
        system("open '#{filepath}'")
        if LucilleCore::askQuestionAnswerAsBoolean("-> completed? ", true) then
            FileUtils.rm(filepath)
            sleep 1
        end
        watchTime = Time.new.to_f - startTime
        puts "Watched for #{watchTime} seconds"
        Bank::put("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c01", watchTime)
    end

    # VideoStream::execute(filepath)
    def self.execute(filepath)
        options = ["play", "completed"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        if option == "play" then
            VideoStream::play(filepath)
        end
        if option == "completed" then
            exit if filepath.nil?
            puts filepath
            FileUtils.rm(filepath)
        end
    end

end

