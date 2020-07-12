
# encoding: UTF-8

# require_relative "TaxonomyArrows.rb"

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

class TaxonomyArrows

    # TaxonomyArrows::make(source, target)
    def self.make(source, target)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "d83a3ff5-023e-482c-8658-f7cfdbb6b738",
            "unixtime"   => Time.new.to_f,
            "sourceuuid" => source["uuid"],
            "targetuuid" => target["uuid"]
        }
    end

    # TaxonomyArrows::issue(source, target)
    def self.issue(source, target)
        arrow = TaxonomyArrows::make(source, target)
        NyxObjects::put(arrow)
        arrow
    end

    # TaxonomyArrows::getTargetsForSource(source)
    def self.getTargetsForSource(source)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["sourceuuid"] == source["uuid"] }
            .map{|arrow| arrow["targetuuid"] }
            .map{|targetuuid| NyxObjects::getOrNull(targetuuid) }
            .compact
    end

    # TaxonomyArrows::getSourcesForTarget(target)
    def self.getSourcesForTarget(target)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["targetuuid"] == target["uuid"] }
            .map{|arrow| arrow["sourceuuid"] }
            .map{|sourceuuid| NyxObjects::getOrNull(sourceuuid) }
            .compact
    end

    # TaxonomyArrows::destroy(source, target)
    def self.destroy(source, target)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| 
                b1 = (arrow["sourceuuid"] == source["uuid"])
                b2 = (arrow["targetuuid"] == target["uuid"])
                b1 and b2
            }
            .first(1)
            .each{|arrow| NyxObjects::destroy(arrow["uuid"]) }
    end

    # TaxonomyArrows::exists?(source, target)
    def self.exists?(source, target)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .any?{|arrow|  
                b1 = (arrow["sourceuuid"] == source["uuid"])
                b2 = (arrow["targetuuid"] == target["uuid"])
                b1 and b2
            }
    end
end
