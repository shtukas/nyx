
# encoding: UTF-8

class NSNode1638NyxElementLocation

    # NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
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

    # NSNode1638NyxElementLocation::maintenance(showprogress)
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
                puts "NSNode1638NyxElementLocation::maintenance(#{showprogress}): searching for #{datapoint}"
                location = GalaxyFinder::nyxFileSystemElementNameToLocationOrNull(datapoint["name"])
                if location then
                    NyxFileSystemElementsMapping::register(datapoint["uuid"], datapoint["name"], location)
                else
                    puts "NSNode1638NyxElementLocation::maintenance(#{showprogress}): I can't locate #{datapoint}"
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
            next if !["NyxDirectory", "NyxFile"].include?(datapoint["type"])
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
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
