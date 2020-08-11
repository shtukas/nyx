# encoding: UTF-8

class NyxPrimaryObjects

    # NyxPrimaryObjects::nyxNxSets()
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

    # NyxPrimaryObjects::uuidToObjectFilepath(uuid)
    def self.uuidToObjectFilepath(uuid)
        hash1 = Digest::SHA256.hexdigest(uuid)
        ns01 = hash1[0, 2]
        ns02 = hash1[2, 2]
        filepath = "#{Realms::primaryDataStoreFolderPath()}/Nyx-Objects/#{ns01}/#{ns02}/#{hash1}.json"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        return filepath
    end

    # NyxPrimaryObjects::put(object)
    def self.put(object)
        if object["uuid"].nil? then
            raise "[NyxPrimaryObjects::put 8d58ee87] #{object}"
        end
        if object["nyxNxSet"].nil? then
            raise "[NyxPrimaryObjects::put d781f18f] #{object}"
        end
        if !NyxPrimaryObjects::nyxNxSets().include?(object["nyxNxSet"]) then
            raise "[NyxPrimaryObjects::nyxNxSets 50229c3e] #{object}"
        end
        filepath = NyxPrimaryObjects::uuidToObjectFilepath(object["uuid"])
        if File.exists?(filepath) then
            raise "[NyxPrimaryObjects::nyxNxSets 5e710d51] objects on disk are immutable"
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(object)) }
        object
    end

    # NyxPrimaryObjects::objectsEnumerator()
    def self.objectsEnumerator()
        Enumerator.new do |objects|
            Find.find("#{Realms::primaryDataStoreFolderPath()}/Nyx-Objects") do |path|
                next if !File.file?(path)
                next if path[-5, 5] != ".json"
                object = JSON.parse(IO.read(path))
                objects << object
            end
        end
    end

    # NyxPrimaryObjects::objects()
    def self.objects()
        NyxPrimaryObjects::objectsEnumerator().to_a
    end

    # NyxPrimaryObjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NyxPrimaryObjects::uuidToObjectFilepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxPrimaryObjects::destroy(uuid)
    def self.destroy(uuid)
        filepath = NyxPrimaryObjects::uuidToObjectFilepath(uuid)
        return nil if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end

# ------------------------------------------------------------------------------
# The rest of Catalyst should not know anything of what happens before this line
# ------------------------------------------------------------------------------

class NyxObjects

    # NyxObjects::getCacheKeySynchronizationMovingFragment()
    def self.getCacheKeySynchronizationMovingFragment()
        filepath = "#{Realms::personalSpaceFolderPath()}/006-nyx-objects-moving-cache-key-c7598b3d-d56a-4b97-b435-69649fc6fe94"
        if !File.exists?(filepath) then
            File.open(filepath, "w"){|f| f.write(SecureRandom.hex) }
        end
        IO.read(filepath).strip
    end

    # NyxObjects::resetCacheKeySynchronizationMovingFragment()
    def self.resetCacheKeySynchronizationMovingFragment()
        filepath = "#{Realms::personalSpaceFolderPath()}/006-nyx-objects-moving-cache-key-c7598b3d-d56a-4b97-b435-69649fc6fe94"
        File.open(filepath, "w"){|f| f.write(SecureRandom.hex) }
    end

    # NyxObjects::cachingKeyPrefix()
    def self.cachingKeyPrefix()
        "E28D1A03-C8B8-4FE2-81F3-48FEF9E476EE:#{NyxObjects::getCacheKeySynchronizationMovingFragment()}"
    end

    # NyxObjects::put(object)
    def self.put(object)
        NyxPrimaryObjects::put(object)

        uuid = object["uuid"]
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("#{NyxObjects::cachingKeyPrefix()}:object:#{uuid}", object)

        # Then we put the object into its cached set
        setid = object["nyxNxSet"]
        set = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("#{NyxObjects::cachingKeyPrefix()}:set:#{setid}")
        return if set.nil?
        set = set.reject{|o| o["uuid"] == object["uuid"] }
        set << object
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("#{NyxObjects::cachingKeyPrefix()}:set:#{setid}", set)
    end

    # NyxObjects::reput(object)
    # Only used by asteroids for recasting business stuff
    def self.reput(object)
        NyxObjects::destroy(object)
        NyxObjects::put(object)
    end

    # NyxObjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        object = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("#{NyxObjects::cachingKeyPrefix()}:object:#{uuid}")
        return object if object 

        object = NyxPrimaryObjects::getOrNull(uuid)

        if object then
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("#{NyxObjects::cachingKeyPrefix()}:object:#{uuid}", object)
        end

        object
    end

    # NyxObjects::getSet(setid)
    def self.getSet(setid)
        set = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("#{NyxObjects::cachingKeyPrefix()}:set:#{setid}")
        return set if set
        puts "-> loading set #{setid} from disk"
        set = NyxPrimaryObjects::objectsEnumerator().select{|object| object["nyxNxSet"] == setid }
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("#{NyxObjects::cachingKeyPrefix()}:set:#{setid}", set)
        set
    end

    # NyxObjects::destroy(object)
    def self.destroy(object)
        NyxPrimaryObjects::destroy(object["uuid"])

        uuid = object["uuid"]
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("#{NyxObjects::cachingKeyPrefix()}:object:#{uuid}")

        setid = object["nyxNxSet"]
        set = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("#{NyxObjects::cachingKeyPrefix()}:set:#{setid}")
        return if set.nil?
        set = set.reject{|o| o["uuid"] == object["uuid"] }

        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("#{NyxObjects::cachingKeyPrefix()}:set:#{setid}", set)
    end
end
