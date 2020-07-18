
# encoding: UTF-8

class KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore
    @@XHash61CDAB202D6 = {}

    # KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(key, value)
    def self.set(key, value)
        @@XHash61CDAB202D6[key] = value
        KeyToStringOnDiskStore::set(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}", JSON.generate([value]))
    end

    # KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(key)
    def self.getOrNull(key)
        if @@XHash61CDAB202D6[key] then
            return @@XHash61CDAB202D6[key]
        end
        box = KeyToStringOnDiskStore::getOrNull(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}")
        if box then
            value = JSON.parse(box)[0]
            @@XHash61CDAB202D6[key] = value
            return value
        end
        nil
    end

    # KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete(key)
    def self.delete(key)
        @@XHash61CDAB202D6.delete(key)
        KeyToStringOnDiskStore::destroy(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}")
    end
end
