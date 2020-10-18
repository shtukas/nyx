
# encoding: UTF-8

class NSNode1638_FileSystemElements

    # NSNode1638_FileSystemElements::getLocationByAllMeansOrNull(datapoint)
    def self.getLocationByAllMeansOrNull(datapoint)
        location = NyxFileSystemElementsMapping::getStoredLocationForObjectUUIDOrNull(datapoint["uuid"])
        if location then
            if File.exists?(location) then
                return location
            end
        end

        location = GalaxyFinder::nyxFilenameToLocationOrNull(datapoint["name"])
        if location then
            NyxFileSystemElementsMapping::register(datapoint["uuid"], datapoint["name"], location)
            return location
        end

        nil
    end

    # NSNode1638_FileSystemElements::maintenance(showprogress)
    def self.maintenance(showprogress)
        NyxFileSystemElementsMapping::records().each{|record|
            if showprogress then
                puts JSON.generate(record)
            end
            if NyxObjects2::getOrNull(record["objectuuid"]).nil? then
                NyxFileSystemElementsMapping::removeRecordByObjectUUID(record["objectuuid"])
                next
            end
            if !File.exists?(record["location"]) then
                datapoint = NyxObjects2::getOrNull(record["objectuuid"])
                puts "NSNode1638_FileSystemElements::maintenance(#{showprogress}): searching for #{datapoint}"
                location = GalaxyFinder::nyxFilenameToLocationOrNull(datapoint["name"])
                if location then
                    NyxFileSystemElementsMapping::register(datapoint["uuid"], datapoint["name"], location)
                else
                    puts "NSNode1638_FileSystemElements::maintenance(#{showprogress}): I can't locate #{datapoint}"
                    puts "Going to land"
                    LucilleCore::pressEnterToContinue()
                    NSNode1638::landing(datapoint)
                end
            end
        }
        NSNode1638::datapoints().each{|datapoint|
            if showprogress then
                puts JSON.generate(datapoint)
            end
            next if !["NyxDirectory", "NyxFile", "NyxFSPoint001"].include?(datapoint["type"])
            location = NSNode1638_FileSystemElements::getLocationByAllMeansOrNull(datapoint)
            if location then
                NyxFileSystemElementsMapping::register(datapoint["uuid"], datapoint["name"], location)
            else
                puts "Falling to find a location for this datapoint"
                puts JSON.pretty_generate(datapoint)
                puts "Going to land"
                LucilleCore::pressEnterToContinue()
                NSNode1638::landing(datapoint)
            end
        }
    end
end
