
$InMemoryStore = {}

class InMemoryStore

    # InMemoryStore::set(key, value)
    def self.set(key, value)
        $InMemoryStore[key] = value
    end

    # InMemoryStore::getOrNull(key)
    def self.getOrNull(key)
        $InMemoryStore[key]
    end
end
