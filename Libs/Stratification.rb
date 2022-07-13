# --------------------------------------------------------------------------------------------
# stratification

#{
#    "mikuType"  : "NxStratificationItem"
#    "item"      : Item
#    "ordinal"   : Float
#    "keepAlive" : Boolean # reset to false at start of replacement process and then to true indicating that the item has been replaced.
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

    # Stratification::replaceIfPresentWithKeepALiveUpdate(stratification, item) # stratification
    def self.replaceIfPresentWithKeepALiveUpdate(stratification, item)
        stratification
            .map{|i|
                if i["item"]["uuid"] == item["uuid"] then
                    i["item"] = item
                    i["keepAlive"] = true
                end
                i
            }
    end

    # Stratification::setAllKeepALiveToFalse(stratification) # stratification
    def self.setAllKeepALiveToFalse(stratification)
        stratification
            .map{|item|
                item["keepAlive"] = false
                item
            }
    end

    # Stratification::reduce(listing, stratification) # stratification
    def self.reduce(listing, stratification)
        listing.reduce(stratification) {|strat, item|
            Stratification::replaceIfPresentWithKeepALiveUpdate(strat, item)
        }
    end

    # Stratification::keepKeepAlive(stratification)
    def self.keepKeepAlive(stratification)
        stratification.select{|item| item["keepAlive"]}
    end

    # Stratification::orderByOrdinal(stratification)
    def self.orderByOrdinal(stratification)
        stratification.sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end
end
