
# encoding: UTF-8

class NSDataType2

    # NSDataType2::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType2::nodeToString(node)
    def self.nodeToString(node)
        cacheKey = "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{Miscellaneous::today()}:#{node["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(node)
        if description then
            str = "[node] [#{node["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end

        NavigationTypes::getDownstreamNavigationTypes(node).each{|ns1|
            str = "[node] [#{node["uuid"][0, 4]}] #{NSDataType1::pointToString(ns1)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        }

        str = "[node] [#{node["uuid"][0, 4]}] [no description]"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
        str
    end

    # NSDataType2::nodeMatchesPattern(node, pattern)
    def self.nodeMatchesPattern(node, pattern)
        return true if node["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2::nodeToString(node).downcase.include?(pattern.downcase)
        false
    end
end
