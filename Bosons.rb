
# encoding: UTF-8

# require_relative "Bosons.rb"

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

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require_relative "Quarks.rb"

require_relative "Cliques.rb"

require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require_relative "BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
=end

# -----------------------------------------------------------------


class Bosons
    # Bosons::make(clique, quark)
    def self.make(clique, quark)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "13f3499d-fa9c-44bb-91d3-8a3ccffecefb",
            "unixtime"   => Time.new.to_f,
            "cliqueuuid" => clique["uuid"],
            "quarkuuid"  => quark["uuid"]
        }
    end

    # Bosons::issue(clique, quark)
    def self.issue(clique, quark)
        boson = Bosons::make(clique, quark)
        NyxObjects::put(boson)
        boson
    end

    # Bosons::getQuarksForClique(clique)
    def self.getQuarksForClique(clique)
        NyxObjects::getSet("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
            .select{|boson| boson["cliqueuuid"] == clique["uuid"] }
            .map{|boson| boson["quarkuuid"] }
            .map{|quarkuuid| Quarks::getOrNull(quarkuuid) }
            .compact
    end

    # Bosons::getCliquesForQuark(quark)
    def self.getCliquesForQuark(quark)
        NyxObjects::getSet("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
            .select{|boson| boson["quarkuuid"] == quark["uuid"] }
            .map{|boson| boson["cliqueuuid"] }
            .map{|cliqueuuid| Cliques::getOrNull(cliqueuuid) }
            .compact
    end

    # Bosons::destroy(clique, quark)
    def self.destroy(clique, quark)
        NyxObjects::getSet("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
            .select{|boson| 
                b1 = (boson["cliqueuuid"] == clique["uuid"])
                b2 = (boson["quarkuuid"] == quark["uuid"])
                b1 and b2
            }
            .first(1)
            .each{|boson| NyxObjects::destroy(boson["uuid"]) }
    end

    # Bosons::linked?(clique, quark)
    def self.linked?(clique, quark)
        NyxObjects::getSet("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
            .any?{|boson|  
                b1 = (boson["cliqueuuid"] == clique["uuid"])
                b2 = (boson["quarkuuid"] == quark["uuid"])
                b1 and b2
            }
    end
end
