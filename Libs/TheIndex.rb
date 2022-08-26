# encoding: UTF-8

class Fx256AtLevel2WithCache

    # Fx256AtLevel2WithCache::objectuuids(name1, name2)
    def self.objectuuids(name1, name2)
        #puts "Fx256AtLevel2WithCache::objectuuids(#{name1}, #{name2})"

        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}/cache-objectuuids.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::objectuuidsAtLevel2(name1, name2)

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256AtLevel2WithCache::mikuTypeToObjectuuids(mikuType, name1, name2)
    def self.mikuTypeToObjectuuids(mikuType, name1, name2)
        #puts "Fx256AtLevel2WithCache::mikuTypeToObjectuuids(#{mikuType}, #{name1}, #{name2})"

        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}/cache-mikuTypeToObjectuuids-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256AtLevel2WithCache::objectuuids(name1, name2)
                        .select{|objectuuid| Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") == mikuType }

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256AtLevel2WithCache::mikuTypeCount(mikuType, name1, name2)
    def self.mikuTypeCount(mikuType, name1, name2)
        #puts "Fx256AtLevel2WithCache::mikuTypeCount(#{mikuType}, #{name1}, #{name2})"
        Fx256AtLevel2WithCache::mikuTypeToObjectuuids(mikuType, name1, name2).size
    end

    # Fx256AtLevel2WithCache::mikuTypeToItems(mikuType, name1, name2)
    def self.mikuTypeToItems(mikuType, name1, name2)
        #puts "Fx256AtLevel2WithCache::mikuTypeToItems(#{mikuType}, #{name1}, #{name2})"
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}/cache-mikuTypeToItems-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        items = Fx256AtLevel2WithCache::mikuTypeToObjectuuids(mikuType, name1, name2)
                .map{|objectuuid| Fx256::getAliveProtoItemOrNull(objectuuid) }
                .compact

        Fx256X::fileput(cache, JSON.pretty_generate(items))
        items
    end

    # Fx256AtLevel2WithCache::nx20s(name1, name2)
    def self.nx20s(name1, name2)
        #puts "Fx256AtLevel2WithCache::nx20s(#{name1}, #{name2})"
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}/cache-nx20s.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        nx20s = Fx256AtLevel2WithCache::objectuuids(name1, name2)
                    .map {|objectuuid|
                        item = Fx256::getAliveProtoItemOrNull(objectuuid)
                        if item then
                            description = LxFunction::function("generic-description", item)
                            {
                                "announce"   => "(#{item["mikuType"]}) #{description}",
                                "unixtime"   => item["unixtime"],
                                "objectuuid" => item["uuid"]
                            }
                        else
                            nil
                        end
                    }
                    .compact

        Fx256X::fileput(cache, JSON.pretty_generate(nx20s))
        nx20s
    end

    # Fx256AtLevel2WithCache::flushCache(name1, name2)
    def self.flushCache(name1, name2)
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}"
        return if !File.exists?(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| File.basename(filepath).start_with?("cache-") }
            .each{|filepath| FileUtils.rm(filepath) }
    end
end

class Fx256AtLevel1WithCache

    # Fx256AtLevel1WithCache::objectuuids(name1)
    def self.objectuuids(name1)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/cache-objectuuids.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::level2Foldernames()
                        .map{|name2| Fx256AtLevel2WithCache::objectuuids(name1, name2)}
                        .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256AtLevel1WithCache::mikuTypeToObjectuuids(mikuType, name1)
    def self.mikuTypeToObjectuuids(mikuType, name1)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/cache-mikuTypeToObjectuuids-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::level2Foldernames()
                        .map{|name2| Fx256AtLevel2WithCache::mikuTypeToObjectuuids(mikuType, name1, name2)}
                        .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256AtLevel1WithCache::mikuTypeCount(mikuType, name1)
    def self.mikuTypeCount(mikuType, name1)
        Fx256AtLevel1WithCache::mikuTypeToObjectuuids(mikuType, name1).size
    end

    # Fx256AtLevel1WithCache::mikuTypeToItems(mikuType, name1)
    def self.mikuTypeToItems(mikuType, name1)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/cache-mikuTypeToItems-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        items = Fx256::level2Foldernames()
                    .map{|name2| Fx256AtLevel2WithCache::mikuTypeToItems(mikuType, name1, name2)}
                    .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(items))
        items
    end

    # Fx256AtLevel1WithCache::nx20s(name1)
    def self.nx20s(name1)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/cache-nx20s.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        nx20s =  Fx256::level2Foldernames()
                    .map{|name2| Fx256AtLevel2WithCache::nx20s(name1, name2)}
                    .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(nx20s))
        nx20s
    end

    # Fx256AtLevel1WithCache::flushCache(name1)
    def self.flushCache(name1)
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}"
        return if !File.exists?(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| File.basename(filepath).start_with?("cache-") }
            .each{|filepath| FileUtils.rm(filepath) }
    end
end

class Fx256WithCache

    # Fx256WithCache::objectuuids()
    def self.objectuuids()
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/cache-objectuuids.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::level1Foldernames()
                        .map{|name1| Fx256AtLevel1WithCache::objectuuids(name1) }
                        .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256WithCache::mikuTypeToObjectuuids(mikuType)
    def self.mikuTypeToObjectuuids(mikuType)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/cache-mikuTypeToObjectuuids-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::level1Foldernames()
                        .map{|name1| Fx256AtLevel1WithCache::mikuTypeToObjectuuids(mikuType, name1) }
                        .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256WithCache::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        Fx256WithCache::mikuTypeToObjectuuids(mikuType).size
    end

    # Fx256WithCache::mikuTypeToItems(mikuType)
    def self.mikuTypeToItems(mikuType)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/cache-mikuTypeToItems-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        items = Fx256::level1Foldernames()
                    .map{|name1| Fx256AtLevel1WithCache::mikuTypeToItems(mikuType, name1) }
                    .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(items))
        items
    end

    # Fx256WithCache::nx20s()
    def self.nx20s()
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/cache-nx20s.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        nx20s =  Fx256::level1Foldernames()
                    .map{|name1| Fx256AtLevel1WithCache::nx20s(name1) }
                    .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(nx20s))
        nx20s
    end

    # Fx256AtLevel1WithCache::flushCache()
    def self.flushCache()
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| File.basename(filepath).start_with?("cache-") }
            .each{|filepath| FileUtils.rm(filepath) }
    end
end

class Fx256X

    # Fx256X::fileput(filepath, content)
    def self.fileput(filepath, content)
        parent = File.dirname(filepath)
        if !File.exists?(parent) then
            FileUtils.mkpath(parent)
        end
        File.open(filepath, "w") {|f| f.write(content) }
    end

    # Fx256X::flushCacheBranch(name1, name2)
    def self.flushCacheBranch(name1, name2)
        Fx256AtLevel2WithCache::flushCache(name1, name2)
        Fx256AtLevel1WithCache::flushCache(name1)
        Fx256WithCache::flushCache()
    end

    # Fx256X::flashCacheBranchAtObjectuuid(objectuuid)
    def self.flashCacheBranchAtObjectuuid(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        name1 = sha1[0, 1]
        name2 = sha1[1, 1]
        Fx256X::flushCacheBranch(name1, name2)
    end
end

class TheIndex

end
