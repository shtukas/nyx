# encoding: UTF-8

class NxIceds

    # NxIceds::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxIced")
    end

    # NxIceds::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxIceds::toString(item)
    def self.toString(item)
        "(iced) #{item["description"]}#{Cx::uuidToString(item["nx112"])}"
    end

    # NxIceds::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(iced) #{item["description"]}"
    end

    # NxIceds::cacheduuidsForSection2()
    def self.cacheduuidsForSection2()
        key = "21b5bf59-2fee-4ed3-b04a-5059fa8ea8fb"
        itemuuids = XCacheValuesWithExpiry::getOrNull(key)
        return itemuuids if itemuuids

        itemuuids = TheIndex::mikuTypeToObjectuuids("NxIced").reduce([]){|selected, itemuuid|
            echoIfValid = lambda{|itemuuid|
                # Default implementation, copied from NxTask, for future use.
                itemuuid
            }
            if selected.size >= 16 then
                selected
            else
                ix = echoIfValid.call(itemuuid)
                if ix then
                    selected + [ix]
                else
                    selected
                end
            end
        }

        XCacheValuesWithExpiry::set(key, itemuuids, 86400)

        itemuuids
    end

    # NxIceds::listingItems()
    def self.listingItems()
        NxIceds::cacheduuidsForSection2()
        .map{|itemuuid| TheIndex::getItemOrNull(itemuuid) }
        .compact
    end
end
