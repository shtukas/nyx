
# encoding: UTF-8

class InMemoryValueCache
    @@XHash61CDAB202D6 = {}

    # InMemoryValueCache::set(key, value)
    def self.set(key, value)
        @@XHash61CDAB202D6[key] = value
    end

    # InMemoryValueCache::getOrNull(key)
    def self.getOrNull(key)
        if @@XHash61CDAB202D6[key] then
            return @@XHash61CDAB202D6[key]
        end
        nil
    end

    # InMemoryValueCache::delete(key)
    def self.delete(key)
        @@XHash61CDAB202D6.delete(key)
    end
end
