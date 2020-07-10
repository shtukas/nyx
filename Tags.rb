
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


class Tags
    # Tags::makeTag(targetuuid, payload)
    def self.makeTag(targetuuid, payload)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "4643abd2-fec6-4184-a9ad-5ad3df3257d6",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "payload"    => payload
        }
    end

    # Tags::issueTag(targetuuid, payload)
    def self.issueTag(targetuuid, payload)
        object = Tags::makeTag(targetuuid, payload)
        NyxObjects::put(object)
        object
    end

    # Tags::getTagsForTargetUUID(targetuuid)
    def self.getTagsForTargetUUID(targetuuid)
        NyxObjects::getSet("4643abd2-fec6-4184-a9ad-5ad3df3257d6")
            .select{|tag| tag["targetuuid"] == targetuuid }
    end
end
