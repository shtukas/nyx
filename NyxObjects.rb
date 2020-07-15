# encoding: UTF-8

NyxPrimaryObjectsObjectMapKey = "35a405c0-a862-4618-95d9-ff5f34c8919f"
NyxPrimaryObjectsSetMapKey    = "35a405c0-a862-4618-95d9-28fb6ce56042"

class NyxPrimaryObjects

    # NyxPrimaryObjects::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxSets
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5", # Cliques
            "6b240037-8f5f-4f52-841d-12106658171f", # Points
            "4643abd2-fec6-4184-a9ad-5ad3df3257d6", # Tags
            "c6fad718-1306-49cf-a361-76ce85e909ca", # Notes
            "4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f", # DescriptionZ
            "1bc9b712-09be-44da-9551-f22d70a3f15d", # DateTimeZ,
            "0f555c97-3843-4dfe-80c8-714d837eba69", # Fragment
            "7e99bb92-098d-4f84-a680-f158126aa3bf", # Comment
            "ab01a47c-bb91-4a15-93f5-b98cd3eb1866", # Text
            "d83a3ff5-023e-482c-8658-f7cfdbb6b738", # Arrow
        ]
    end

    # NyxPrimaryObjects::uuidToObjectFilepath(uuid)
    def self.uuidToObjectFilepath(uuid)
        hash1 = Digest::SHA256.hexdigest(uuid)
        fragment1 = hash1[0, 2]
        fragment2 = hash1[2, 2]
        filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-Objects/#{fragment1}/#{fragment2}/#{hash1}.json"
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
            Find.find("#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-Objects") do |path|
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

    # NyxObjects::getObjectsMap()
    def self.getObjectsMap()
        objectsmap = InMemoryValueCache::getOrNull(NyxPrimaryObjectsObjectMapKey)
        if objectsmap.nil? then
            puts "-> computing objectsmap from scratch"
            objectsmap = {}
            NyxPrimaryObjects::objects().each{|object|
                objectsmap[object["uuid"]] = object
            }
            InMemoryValueCache::set(NyxPrimaryObjectsObjectMapKey, objectsmap)
        end
        objectsmap
    end

    # NyxObjects::getSetsMap()
    def self.getSetsMap()
        setsmap = InMemoryValueCache::getOrNull(NyxPrimaryObjectsSetMapKey)
        if setsmap.nil? then
            puts "-> computing setsmap from scratch"
            setsmap = {}
            NyxPrimaryObjects::nyxNxSets().each{|setid|
                setsmap[setid] = {}
            }
            NyxPrimaryObjects::objects().each{|object|
                if setsmap[object["nyxNxSet"]].nil? then
                    setsmap[object["nyxNxSet"]] = {}
                end
                setsmap[object["nyxNxSet"]][object["uuid"]] = object
            }
            InMemoryValueCache::set(NyxPrimaryObjectsSetMapKey, setsmap)
        end
        setsmap
    end

    # NyxObjects::put(object)
    def self.put(object)
        NyxPrimaryObjects::put(object)

        objectsmap = NyxObjects::getObjectsMap()
        objectsmap[object["uuid"]] = object
        InMemoryValueCache::set(NyxPrimaryObjectsObjectMapKey, objectsmap)

        setsmap = NyxObjects::getSetsMap()
        if setsmap[object["nyxNxSet"]].nil? then
            setsmap[object["nyxNxSet"]] = {} # This happens when a set was intrduced after the last snapshot
        end
        setsmap[object["nyxNxSet"]][object["uuid"]] = object
        InMemoryValueCache::set(NyxPrimaryObjectsSetMapKey, setsmap)
    end

    # NyxObjects::objects()
    def self.objects()
        # NyxPrimaryObjects::objects()
        objectsmap = NyxObjects::getObjectsMap()
        objectsmap.values
    end

    # NyxObjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        # NyxPrimaryObjects::getOrNull(uuid)
        objectsmap = NyxObjects::getObjectsMap()
        objectsmap[uuid]
    end

    # NyxObjects::getSet(setid)
    def self.getSet(setid)
        #NyxObjects::objects().select{|object| object["nyxNxSet"] == setid }
        setsmap = NyxObjects::getSetsMap()
        return [] if setsmap[setid].nil? # This happens when a set was intrduced after the last snapshot
        setsmap[setid].values
    end

    # NyxObjects::destroy(uuid)
    def self.destroy(uuid)
        NyxPrimaryObjects::destroy(uuid)

        objectsmap = NyxObjects::getObjectsMap()
        objectsmap.delete(uuid)
        InMemoryValueCache::set(NyxPrimaryObjectsObjectMapKey, objectsmap)

        setsmap = NyxObjects::getSetsMap()
        NyxPrimaryObjects::nyxNxSets().each{|setid|
            next if setsmap[setid].nil?
            setsmap[setid].delete(uuid)
        }
        InMemoryValueCache::set(NyxPrimaryObjectsSetMapKey, setsmap)
    end
end
