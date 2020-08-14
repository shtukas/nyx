# encoding: UTF-8

class NyxObjectsCore
    # NyxObjectsCore::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxSets
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "0f555c97-3843-4dfe-80c8-714d837eba69", # NSDataPoint
            "ab01a47c-bb91-4a15-93f5-b98cd3eb1866", # Text
            "d83a3ff5-023e-482c-8658-f7cfdbb6b738", # Arrow
            "c18e8093-63d6-4072-8827-14f238975d04", # NSDataType1
            "5c99134b-2b61-4750-8519-49c1d896556f", # NSDataTypeX, attributes
            "d319513e-1582-4c78-a4c4-bf3d72fb5b2d", # NSDataLine
        ]
    end
end

NyxObjectsDionysus2Filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/nyx-objects.sqlite3"

$DBD8C53F77 = Dionysus2::getDatabaseProxy(NyxObjectsDionysus2Filepath)

class NyxObjects2

    # NyxObjects2::put(object)
    def self.put(object)
        Dionysus2::sets_putObject($DBD8C53F77, object["nyxNxSet"], object["uuid"], object)
    end

    # NyxObjects2::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjectsCore::nyxNxSets().each{|setid|
            object = Dionysus2::sets_getObjectOrNull($DBD8C53F77, setid, uuid)
            if object then
                return object
            end
        }
        nil
    end

    # NyxObjects2::getSet(setid)
    def self.getSet(setid)
        objects = Dionysus2::sets_getObjects($DBD8C53F77, setid)
        objects
    end

    # NyxObjects2::destroy(object)
    def self.destroy(object)
        NyxObjectsCore::nyxNxSets().each{|setid|
            Dionysus2::sets_destroy($DBD8C53F77, setid, object["uuid"])
        }
    end
end
