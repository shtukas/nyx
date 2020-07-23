
# encoding: UTF-8

class EstateServices

    # EstateServices::today()
    def self.today()
        DateTime.now.to_date.to_s
    end

    # EstateServices::getFirstDiveFirstLocationAtLocation(location)
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
                    EstateServices::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    # EstateServices::getLocationFileBiggerThan10MegaBytesOrNull(location)
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
            .map{|location_| EstateServices::getLocationFileBiggerThan10MegaBytesOrNull(location_) }
            .compact
            .first
    end

    # EstateServices::getFilepathAgeInDays(filepath)
    def self.getFilepathAgeInDays(filepath)
        (Time.new.to_i - File.mtime(filepath).to_i).to_f/86400
    end

    # -------------------------------------------

    # EstateServices::getArchiveT1mel1neSizeInMegaBytes()
    def self.getArchiveT1mel1neSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(Miscellaneous::binT1mel1neFolderpath()).to_f/(1024*1024)
    end

    # EstateServices::archivesT1mel1neGarbageCollectionCore(sizeEstimationInMegaBytes, verbose)
    def self.archivesT1mel1neGarbageCollectionCore(sizeEstimationInMegaBytes, verbose)
        if sizeEstimationInMegaBytes.nil? then
            sizeEstimationInMegaBytes = EstateServices::getArchiveT1mel1neSizeInMegaBytes()
        end
        return if sizeEstimationInMegaBytes <= 1024
        location = EstateServices::getFirstDiveFirstLocationAtLocation(Miscellaneous::binT1mel1neFolderpath())
        return if location == Miscellaneous::binT1mel1neFolderpath()
        if File.file?(location) then
            sizeEstimationInMegaBytes = sizeEstimationInMegaBytes - File.size(location).to_f/(1024*1024)
        end
        puts "garbage collection: #{location}" if verbose
        LucilleCore::removeFileSystemLocation(location)
        EstateServices::archivesT1mel1neGarbageCollectionCore(sizeEstimationInMegaBytes, verbose)
    end

    # EstateServices::binT1mel1neGarbageCollectionEnvelop(verbose)
    def self.binT1mel1neGarbageCollectionEnvelop(verbose)
        return if EstateServices::getArchiveT1mel1neSizeInMegaBytes() <= 1024
        loop {
            location = EstateServices::getLocationFileBiggerThan10MegaBytesOrNull(Miscellaneous::binT1mel1neFolderpath())
            break if location.nil?
            puts "garbage collection (big file): #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
        }
        EstateServices::archivesT1mel1neGarbageCollectionCore(nil, verbose)
    end

    # EstateServices::ensureReadiness()
    def self.ensureReadiness()
        realmConfig = Realms::getRealmConfig()
        realmConfig["exitIfNotExist"].each{|path|
            if !File.exists?(path) then
                puts "We are expecting this location to exists: #{path}. This is a non recoverable error. Exiting"
                exit
            end
        }
        realmConfig["createIfNotExist"].each{|path|
            if !File.exists?(path) then
                puts "Creating missing location: #{path}"
                FileUtils.mkdir(path)
            end
        }
    end

    # EstateServices::getDeskFolderpath()
    def self.getDeskFolderpath()
        "#{ENV['HOME']}/.catalyst/001-desk-85d03ad6-ba18-4b01-b9e3-8496eaab477f"
    end

end