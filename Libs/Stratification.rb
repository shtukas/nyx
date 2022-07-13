# --------------------------------------------------------------------------------------------
# stratification

#{
#    "mikuType"  : "NxStratificationItem"
#    "item"      : Item
#    "ordinal"   : Float
#    "DoNotDisplayUntilUnixtime" : nil or Unixtime
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
        stratification = Stratification::getStratificationFromDisk()
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
            "keepAlive" => true
        }
        stratification << nxStratificationItem

        Stratification::commitStratificationToDisk(stratification)
    end
end
