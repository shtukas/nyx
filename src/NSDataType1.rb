
# encoding: UTF-8

class NSDataType1

    # NSDataType1::toString(node, useCachedValue = true)
    def self.toString(node, useCachedValue = true)
        cacheKey = "645001e0-dec2-4e7a-b113-5c5e93ec0e69:#{node["uuid"]}"
        if useCachedValue then
            str = KeyValueStore::getOrNull(nil, cacheKey)
            return str if str
        end
        objects = Arrows::getTargetsForSource(node)
        if node["description"] then
            str = "[node] [#{node["uuid"][0, 4]}] #{node["description"]}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if node["description"].nil? and objects.size > 0 then
            str = "[node] [#{node["uuid"][0, 4]}] #{GenericObjectInterface::toString(objects.first)}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if node["description"].nil? and objects.size == 0 then
            str = "[node] [#{node["uuid"][0, 4]}] {no description, no dataline}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        raise "[error: 2b22ddb3-62c4-4940-987a-7a50330dcd36]"
    end
end
