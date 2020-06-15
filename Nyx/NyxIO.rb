
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"

# -----------------------------------------------------------------

class NyxIO

    # NyxIO::pathToRepository()
    def self.pathToRepository()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Nxy-Repository/objects"
    end

    # NyxIO::getOrNullAtType(uuid, nyxtype)
    def self.getOrNullAtType(uuid, nyxtype)
        filepath = "#{NyxIO::pathToRepository()}/#{nyxtype}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxIO::getDataNetworkTypes()
    def self.getDataNetworkTypes()
        Dir.entries(NyxIO::pathToRepository())
            .select{|filename| filename[0, 1] != "." }
    end

    # NyxIO::destroyAtType(uuid, nyxtype)
    def self.destroyAtType(uuid, nyxtype)
        filepath = "#{NyxIO::pathToRepository()}/#{nyxtype}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -----------------------------------------------------------------------------------

    # NyxIO::objects(nyxtype)
    def self.objects(nyxtype)
        folderpath = "#{NyxIO::pathToRepository()}/#{nyxtype}"
        Dir.entries(folderpath)
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{folderpath}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
    end

    # NyxIO::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxIO::getDataNetworkTypes()
            .map{|nyxtype| NyxIO::getOrNullAtType(uuid, nyxtype) }
            .compact
            .first
    end

    # NyxIO::commitToDisk(object)
    def self.commitToDisk(object)
        raise "[02986280]" if object["nyxType"].nil?
        raise "[222C74D4]" if object["uuid"].nil?
        filepath = "#{NyxIO::pathToRepository()}/#{object["nyxType"]}/#{object["uuid"]}.json"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(object)) }
    end

    # NyxIO::destroy(uuid)
    def self.destroy(uuid)
        NyxIO::getDataNetworkTypes()
            .map{|nyxtype| NyxIO::destroyAtType(uuid, nyxtype) }
    end

    # -----------------------------------------------------------------------------------

    # NyxIO::dataCarriersNyxTypes()
    def self.dataCarriersNyxTypes()
        [
            "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "tag-57c7eced-24a8-466d-a6fe-588142afd53b"
        ]
    end

    # NyxIO::rolesNyxTypes()
    def self.rolesNyxTypes()
        [
            "asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37",
            "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
            "wave-12ed27da-b5e4-4e6e-940f-2c84071cca58"
        ]
    end

end
