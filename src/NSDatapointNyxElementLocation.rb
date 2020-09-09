
# encoding: UTF-8

class NSDatapointNyxElementLocation

    # NSDatapointNyxElementLocation::getLocationByAllMeansOrNull(datapoint)
    def self.getLocationByAllMeansOrNull(datapoint)
        location = NyxFileSystemElementsMapping::getStoredLocationForObjectUUIDOrNull(datapoint["uuid"])
        if location then
            if File.exists?(location) then
                return location
            end
        end

        location = GalaxyFinder::nyxFileSystemElementNameToLocationOrNull(datapoint["name"])
        if location then
            NyxFileSystemElementsMapping::register(datapoint["uuid"], datapoint["name"], location)
            return location
        end

        nil
    end

    # NSDatapointNyxElementLocation::automaintenance(showprogress)
    def self.automaintenance(showprogress)
        NyxFileSystemElementsMapping::records().each{|record|
            if showprogress then
                puts JSON.pretty_generate(record)
            end
            if NyxObjects2::getOrNull(record["objectuuid"]).nil? then
                NyxFileSystemElementsMapping::removeRecordByObjectUUID(record["objectuuid"])
                next
            end
            if !File.exists?(record["location"]) then
                datapoint = NyxObjects2::getOrNull(record["objectuuid"])
                system("clear")
                puts "NSDatapointNyxElementLocation::automaintenance(#{showprogress}): searching for #{datapoint}"
                location = GalaxyFinder::nyxFileSystemElementNameToLocationOrNull(datapoint["name"])
                if location then
                    NyxFileSystemElementsMapping::register(datapoint["uuid"], datapoint["name"], location)
                else
                    puts "NSDatapointNyxElementLocation::automaintenance(#{showprogress}): I can't locate #{datapoint}"
                    puts "Going to land"
                    LucilleCore::pressEnterToContinue()
                    NSDataPoint::landing(datapoint)
                end
            end
        }
        NSDataPoint::datapoints().each{|datapoint|
            if showprogress then
                puts JSON.pretty_generate(datapoint)
            end
            next if !["NyxDirectory", "NyxFile"].include?(datapoint["type"])
            location = NSDatapointNyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location then
                NyxFileSystemElementsMapping::register(datapoint["uuid"], datapoint["name"], location)
            else
                system("clear")
                puts "Falling to find a location for this datapoint nyx element"
                puts JSON.pretty_generate(datapoint)
                puts "Going to land"
                LucilleCore::pressEnterToContinue()
                NSDataPoint::landing(datapoint)
            end
        }
    end
end
