# encoding: UTF-8

class NyxObjectsCore
    # NyxObjectsCore::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxSets
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "0f555c97-3843-4dfe-80c8-714d837eba69", # NSNode1638
        ]
    end
end

NyxObjectsDionysus1Filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Objects.sqlite3"

$NyxObjectsCache76DBF964 = {}
NyxObjectsCore::nyxNxSets().each{|setid|
    Dionysus1::sets_getObjects(NyxObjectsDionysus1Filepath, setid).each{|object|
        $NyxObjectsCache76DBF964[object["uuid"]] = object
    }
}

class NyxObjects2

    # NyxObjects2::put(object)
    def self.put(object)
        Dionysus1::sets_putObject(NyxObjectsDionysus1Filepath, object["nyxNxSet"], object["uuid"], object)
        $NyxObjectsCache76DBF964[object["uuid"]] = object
    end

    # NyxObjects2::getOrNull(uuid)
    def self.getOrNull(uuid)
        $NyxObjectsCache76DBF964[uuid]
    end

    # NyxObjects2::getSet(setid)
    def self.getSet(setid)
        Dionysus1::sets_getObjects(NyxObjectsDionysus1Filepath, setid)
    end

    # NyxObjects2::destroy(object)
    def self.destroy(object)
        NyxObjectsCore::nyxNxSets().each{|setid|
            Dionysus1::sets_destroy(NyxObjectsDionysus1Filepath, setid, object["uuid"])
        }
        $NyxObjectsCache76DBF964.delete(object["uuid"])
    end
end
