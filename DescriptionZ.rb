
# encoding: UTF-8

# require_relative "Tags.rb"

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


class DescriptionZ

    # DescriptionZ::make(targetuuid, description)
    def self.make(targetuuid, description)
        raise "[DescriptionZ error 9482c130]" if description.strip.size == 0
        {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f",
            "unixtime"    => Time.new.to_f,
            "targetuuid"  => targetuuid,
            "description" => description
        }
    end

    # DescriptionZ::issue(targetuuid, description)
    def self.issue(targetuuid, description)
        object = DescriptionZ::make(targetuuid, description)
        NyxObjects::put(object)
        object
    end

    # DescriptionZ::issueReplacementOfAnyExisting(targetuuid, description)
    def self.issueReplacementOfAnyExisting(targetuuid, description)
        existingobjects = DescriptionZ::getForTargetUUIDInTimeOrder(targetuuid)
        object = DescriptionZ::make(targetuuid, description)
        NyxObjects::put(object)
        existingobjects.each{|o|
            DescriptionZ::destroy(o)
        }
        object
    end

    # DescriptionZ::getForTargetUUIDInTimeOrder(targetuuid)
    def self.getForTargetUUIDInTimeOrder(targetuuid)
        NyxObjects::getSet("4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f")
            .select{|object| object["targetuuid"] == targetuuid }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # DescriptionZ::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object["uuid"])
    end
end
