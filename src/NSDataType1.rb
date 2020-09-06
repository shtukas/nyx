
# encoding: UTF-8

class NSDataType1

    # NSDataType1::objects()
    def self.objects()
        NyxObjects2::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # NSDataType1::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects2::getOrNull(uuid)
    end

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

    # NSDataType1::issueDescriptionInteractivelyOrNothing(point)
    def self.issueDescriptionInteractivelyOrNothing(point)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        point["description"] = description
        NyxObjects2::put(point)
    end

    # NSDataType1::destroy(point)
    def self.destroy(point)
        NyxObjects2::destroy(point)
    end
end
