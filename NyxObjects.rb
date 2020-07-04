# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

# ------------------------------------------------------------------------

class NyxObjects

    # NyxObjects::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxSets
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5", # Cliques
            "6b240037-8f5f-4f52-841d-12106658171f", # Quarks
            "a00b82aa-c047-4497-82bf-16c7206913e4", # QuarkTags
            "13f3499d-fa9c-44bb-91d3-8a3ccffecefb", # Bosons
        ]
    end

    # NyxObjects::namedHashToObjectsFilepath(namedhash)
    def self.namedHashToObjectsFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            fragment1 = namedhash[7, 2]
            fragment2 = namedhash[9, 2]
            fragment3 = namedhash[11, 2]
            filepath = "#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Objects/#{fragment1}/#{fragment2}/#{fragment3}/#{namedhash}.json"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxPrimaryStoreUtils: a10f1670-b694-4937-b155-cbfa695b784a]"
    end

    # NyxObjects::put(object) # namedhash
    def self.put(object)
        if object["uuid"].nil? then
            raise "[NyxObjects::put b45f7d8a] #{object}"
        end
        if object["nyxNxSet"].nil? then
            raise "[NyxObjects::put fd215c77] #{object}"
        end
        if !NyxObjects::nyxNxSets().include?(object["nyxNxSet"]) then
            raise "[NyxObjects::nyxNxSets c883b1e7] #{object}"
        end
        object["nyxNxStoreTimestamp"] = Time.new.to_f
        blob = JSON.generate(object)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxObjects::namedHashToObjectsFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        namedhash
    end

    # NyxObjects::storedObjectsEnumerator()
    def self.storedObjectsEnumerator()
        Enumerator.new do |objects|
            Find.find("#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Objects") do |path|
                next if !File.file?(path)
                next if path[-5, 5] != ".json"
                objects << JSON.parse(IO.read(path))
            end
        end
    end

    # NyxObjects::loadObjectsLatestVersions()
    def self.loadObjectsLatestVersions()
        mapping = {}
        NyxObjects::storedObjectsEnumerator()
            .each{|object|
                if mapping[object["uuid"]].nil? then
                    mapping[object["uuid"]] = object
                else
                    if mapping[object["uuid"]]["nyxNxStoreTimestamp"] < object["nyxNxStoreTimestamp"] then
                        mapping[object["uuid"]] = object
                    end
                end
            }
        mapping
            .values
            .select{|object| !object["nyxNxSet"].nil? } # removing the ones that have been deleted
    end
end

