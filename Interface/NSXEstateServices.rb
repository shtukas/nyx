
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

class NSXEstateServices

    # NSXEstateServices::today()
    def self.today()
        DateTime.now.to_date.to_s
    end

    # NSXEstateServices::getFirstDiveFirstLocationAtLocation(location)
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

    # NSXEstateServices::getLocationFileBiggerThan10MegaBytesOrNull(location)
    def self.getLocationFileBiggerThan10MegaBytesOrNull(location)
        if File.file?(location) then
            if File.size(location) > 1024*1024*10 then
                return location
            else
                return nil
            end
        end
        Dir.entries(location)
            .select{|filename| filename != '.' and filename != '..' }
            .sort
            .map{|filename| "#{location}/#{filename}" }
            .map{|location_| NSXEstateServices::getLocationFileBiggerThan10MegaBytesOrNull(location_) }
            .compact
            .first
    end

    # NSXEstateServices::getFilepathAgeInDays(filepath)
    def self.getFilepathAgeInDays(filepath)
        (Time.new.to_i - File.mtime(filepath).to_i).to_f/86400
    end

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

    # -------------------------------------------
    # Timeline management

    # NSXEstateServices::getArchiveTimelineSizeInMegaBytes()
    def self.getArchiveTimelineSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_BIN_TIMELINE_FOLDERPATH).to_f/(1024*1024)
    end

    # NSXEstateServices::archivesTimelineGarbageCollectionCore(sizeEstimationInMegaBytes, verbose)
    def self.archivesTimelineGarbageCollectionCore(sizeEstimationInMegaBytes, verbose)
        if sizeEstimationInMegaBytes.nil? then
            sizeEstimationInMegaBytes = NSXEstateServices::getArchiveTimelineSizeInMegaBytes()
        end
        return if sizeEstimationInMegaBytes <= 1024
        location = NSXEstateServices::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_TIMELINE_FOLDERPATH)
        return if location == CATALYST_COMMON_BIN_TIMELINE_FOLDERPATH
        if File.file?(location) then
            sizeEstimationInMegaBytes = sizeEstimationInMegaBytes - File.size(location).to_f/(1024*1024)
        end
        puts "garbage collection: #{location}" if verbose
        LucilleCore::removeFileSystemLocation(location)
        NSXEstateServices::archivesTimelineGarbageCollectionCore(sizeEstimationInMegaBytes, verbose)
    end

    # NSXEstateServices::binTimelineGarbageCollectionEnvelop(verbose)
    def self.binTimelineGarbageCollectionEnvelop(verbose)
        return if NSXEstateServices::getArchiveTimelineSizeInMegaBytes() <= 1024
        loop {
            location = NSXEstateServices::getLocationFileBiggerThan10MegaBytesOrNull(CATALYST_COMMON_BIN_TIMELINE_FOLDERPATH)
            break if location.nil?
            puts "garbage collection (big file): #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
        }
        NSXEstateServices::archivesTimelineGarbageCollectionCore(nil, verbose)
    end

end