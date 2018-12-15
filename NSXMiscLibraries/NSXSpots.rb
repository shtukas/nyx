
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

# We store the starting unixtime

NSXSPOTS_DATAFILEPATH = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Spots/data.json"

class NSXSpots

    # NSXSpots::getData()
    def self.getData()
        JSON.parse(IO.read(NSXSPOTS_DATAFILEPATH))
    end

    # NSXSpots::commitDataToDisk(data)
    def self.commitDataToDisk(data)
        File.open(NSXSPOTS_DATAFILEPATH, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end

    # NSXSpots::issueSpotClaim(spotname, objectuuid)
    def self.issueSpotClaim(spotname, objectuuid)
        data = NSXSpots::getData()
        data << [spotname, objectuuid]
        NSXSpots::commitDataToDisk(data)
    end

    # NSXSpots::getObjectUUIDs()
    def self.getObjectUUIDs()
        NSXSpots::getData().map{|spotname, objectuuid| objectuuid }
    end

    # NSXSpots::getNames()
    def self.getNames()
        NSXSpots::getData().map{|spotname, objectuuid| spotname }.uniq
    end

    # NSXSpots::removeNameForData(spotname)
    def self.removeNameForData(spotname)
        data = NSXSpots::getData()
        data = data.reject{|pair| pair[0]==spotname }
        NSXSpots::commitDataToDisk(data)  
    end

end




