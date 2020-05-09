
# encoding: UTF-8

require 'json'

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

# ----------------------------------------------------------------------

require_relative "NSXMiscUtils.rb"
require_relative "NSXWaveUtils.rb"

class WaveNextGen
    # WaveNextGen::pathToClaims()
    def self.pathToClaims()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Wave/Claims"
    end

    # WaveNextGen::claims()
    def self.claims()
        Dir.entries(WaveNextGen::pathToClaims())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{WaveNextGen::pathToClaims()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # WaveNextGen::getClaimByUUIDOrNUll(uuid)
    def self.getClaimByUUIDOrNUll(uuid)
        filepath = "#{WaveNextGen::pathToClaims()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # WaveNextGen::save(claim)
    def self.save(claim)
        uuid = claim["uuid"]
        File.open("#{WaveNextGen::pathToClaims()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
    end

    # WaveNextGen::destroy(claim)
    def self.destroy(claim)
        uuid = claim["uuid"]
        filepath = "#{WaveNextGen::pathToClaims()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # WaveNextGen::makeClaim(uuid, description, schedule)
    def self.makeClaim(uuid, description, schedule)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "schedule"     => schedule
        }
    end

    # WaveNextGen::issueClaim(uuid, description, schedule)
    def self.issueClaim(uuid, description, schedule)
        claim = WaveNextGen::makeClaim(uuid, description, schedule)
        WaveNextGen::save(claim)
    end

    # WaveNextGen::selectClaimOrNull()
    def self.selectClaimOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("claim:", WaveNextGen::claims(), lambda {|claim| claim["description"] })
    end
end



