
# encoding: UTF-8

class InMemoryWithOnDiskPersistenceValueCache
    @@XHash61CDAB202D6 = {}

    # InMemoryWithOnDiskPersistenceValueCache::set(key, value)
    def self.set(key, value)
        @@XHash61CDAB202D6[key] = value
        KeyValueStore::set(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}", JSON.generate([value]))
    end

    # InMemoryWithOnDiskPersistenceValueCache::getOrNull(key)
    def self.getOrNull(key)
        if @@XHash61CDAB202D6[key] then
            return @@XHash61CDAB202D6[key]
        end
        box = KeyValueStore::getOrNull(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}")
        if box then
            value = JSON.parse(box)[0]
            @@XHash61CDAB202D6[key] = value
            return value
        end
        nil
    end

    # InMemoryWithOnDiskPersistenceValueCache::delete(key)
    def self.delete(key)
        @@XHash61CDAB202D6.delete(key)
        KeyValueStore::destroy(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}")
    end
end
