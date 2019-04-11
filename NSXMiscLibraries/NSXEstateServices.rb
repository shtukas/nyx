
# encoding: UTF-8

class NSXEstateServices

    # NSXEstateServices::today()
    # NSXEstateServices::getFirstDiveFirstLocationAtLocation(location)
    # NSXEstateServices::getFilepathAgeInDays(filepath)

    def self.today()
        DateTime.now.to_date.to_s
    end

    def self.getFirstDiveFirstLocationAtLocation(location)
        if File.file?(location) then
            location
        else
            locations = Dir.entries(location)
                .select{|filename| filename!='.' and filename!='..' }
                .sort
                .map{|filename| "#{location}/#{filename}" }
            if locations.size==0 then
                location
            else
                locationsdirectories = locations.select{|location| File.directory?(location) }
                if locationsdirectories.size>0 then
                    NSXEstateServices::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    def self.getFilepathAgeInDays(filepath)
        (Time.new.to_i - File.mtime(filepath).to_i).to_f/86400
    end

    # -------------------------------------------
    # Archives

    # NSXEstateServices::getArchiveTimelineSizeInMegaBytes()
    def self.getArchiveTimelineSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH).to_f/(1024*1024)
    end

    # NSXEstateServices::archivesTimelineGarbageCollectionStandard(verbose): Array[String] 
    def self.archivesTimelineGarbageCollectionStandard(verbose)
        while NSXEstateServices::getArchiveTimelineSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = NSXEstateServices::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            puts "garbage collection: #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
        end
    end

    # NSXEstateServices::archivesTimelineGarbageCollectionFast(sizeEstimationInMegaBytes, verbose): Array[String] 
    def self.archivesTimelineGarbageCollectionFast(sizeEstimationInMegaBytes, verbose)
        while sizeEstimationInMegaBytes > 1024 do # Gigabytes of Archives
            location = NSXEstateServices::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            if File.file?(location) then
                sizeEstimationInMegaBytes = sizeEstimationInMegaBytes - File.size(location).to_f/(1024*1024)
            end
            puts "garbage collection: #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
        end
    end

    # NSXEstateServices::archivesTimelineGarbageCollection(verbose): Array[String]
    def self.archivesTimelineGarbageCollection(verbose)
        while NSXEstateServices::getArchiveTimelineSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = NSXEstateServices::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            NSXEstateServices::archivesTimelineGarbageCollectionFast(NSXEstateServices::getArchiveTimelineSizeInMegaBytes(), verbose)
        end
    end

    # -------------------------------------------
    # 

    # NSXEstateServices::locationHashRecursively(location)
    def self.locationHashRecursively(location)
        if File.file?(location) then
            Digest::SHA1.hexdigest("#{location}:#{Digest::SHA1.file(location).hexdigest}")
        else
            trace = Dir.entries(location)
                .reject{|filename| filename.start_with?(".") }
                .map{|filename| "#{location}/#{filename}" }
                .map{|location| NSXEstateServices::locationHashRecursively(location) }
                .join("::")
            Digest::SHA1.hexdigest(trace)
        end
    end

    # NSXEstateServices::collectInboxPackage()
    def self.collectInboxPackage()
        Dir.entries(CATALYST_INBOX_DROPOFF_FOLDERPATH)
            .select{|filename| filename[0, 1] != '.' }
            .map{|filename| "#{CATALYST_INBOX_DROPOFF_FOLDERPATH}/#{filename}" }
            .each{|sourcelocation|
                genericItem = NSXGenericContents::issueItemLocationMoveOriginal(sourcelocation)
                NSXStreamsUtils::issueNewStreamItem("03b79978bcf7a712953c5543a9df9047", genericItem, NSXMiscUtils::makeStreamItemOrdinal())
            }
    end

end