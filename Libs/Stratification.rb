# --------------------------------------------------------------------------------------------
# stratification

#{
#    "mikuType"  : "NxStratificationItem"
#    "item"      : Item
#    "ordinal"   : Float
#    "DoNotDisplayUntilUnixtime" : nil or Unixtime
#    "createdAt" : Unixtime
#}

# stratification : Array[NxStratificationItem]

class Stratification

    # Stratification::getStratificationFromDisk()
    def self.getStratificationFromDisk()
        JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Stargate/catalyst-stratification.json"))
    end

    # Stratification::commitStratificationToDisk(stratification)
    def self.commitStratificationToDisk(stratification)
        File.open("/Users/pascal/Galaxy/DataBank/Stargate/catalyst-stratification.json", "w") {|f| f.puts(JSON.pretty_generate(stratification)) }
    end

    # Stratification::replaceIfPresent(stratification, item) # stratification
    def self.replaceIfPresent(stratification, item)
        stratification
            .map{|i|
                if i["item"]["uuid"] == item["uuid"] then
                    i["item"] = item
                end
                i
            }
    end

    # Stratification::reduce(listing, stratification) # stratification
    def self.reduce(listing, stratification)
        listing.reduce(stratification) {|strat, item|
            Stratification::replaceIfPresent(strat, item)
        }
    end

    # Stratification::orderByOrdinal(stratification)
    def self.orderByOrdinal(stratification)
        stratification.sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end

    # Stratification::applyDoNotDisplayUntilUnixtime(itemuuid, unixtime)
    def self.applyDoNotDisplayUntilUnixtime(itemuuid, unixtime)
        stratification = 
            Stratification::getStratificationFromDisk()
                .map{|i|
                    if i["item"]["uuid"] == itemuuid then
                        i["DoNotDisplayUntilUnixtime"] = unixtime
                    end
                    i
                }
        Stratification::commitStratificationToDisk(stratification)
    end

    # Stratification::nextOrdinal()
    def self.nextOrdinal()
        stratification = JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Stargate/catalyst-stratification.json"))
        ([0] + stratification.map{|nx| nx["ordinal"]}).max + 1
    end

    # Stratification::injectItemAtOrdinal(item, ordinal)
    def self.injectItemAtOrdinal(item, ordinal)
        stratification = Stratification::getStratificationFromDisk()
        nxStratificationItem = {
            "mikuType"  => "NxStratificationItem",
            "item"      => item,
            "ordinal"   => ordinal,
            "createdAt" => Time.new.to_f
        }
        stratification << nxStratificationItem
        Stratification::commitStratificationToDisk(stratification)
    end

    # Stratification::removeItemByUUID(itemuuid)
    def self.removeItemByUUID(itemuuid)
        stratification = Stratification::getStratificationFromDisk()
        stratification = stratification.select{|i| i["item"]["uuid"] != itemuuid }
        Stratification::commitStratificationToDisk(stratification)
    end

    # Stratification::publishAverageAgeInDays()
    def self.publishAverageAgeInDays()
        numbers = Stratification::getStratificationFromDisk()
            .select{|i| !i["createdAt"].nil?  }
            .map{|i| Time.new.to_i-i["createdAt"] }
        return if numbers.empty?
        average = numbers.inject(0, :+).to_f/86400
        XCache::set("6ee981a4-315f-4f82-880f-5806424c904f", average)
    end
end
