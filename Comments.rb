
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

class Comments

    # Comments::make(targetuuid, author: null or String, text)
    def self.make(targetuuid, author, text)
        namedhash = NyxBlobs::put(text)
        {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "7e99bb92-098d-4f84-a680-f158126aa3bf",
            "unixtime"    => Time.new.to_f,
            "author"      => author,
            "targetuuid"  => targetuuid,
            "namedhash"   => namedhash
        }
    end

    # Comments::issue(targetuuid, author: null or String, text)
    def self.issue(targetuuid, author, text)
        object = Comments::make(targetuuid, author, text)
        NyxObjects::put(object)
        object
    end

    # Comments::getForTargetUUIDInTimeOrder(targetuuid)
    def self.getForTargetUUIDInTimeOrder(targetuuid)
        NyxObjects::getSet("7e99bb92-098d-4f84-a680-f158126aa3bf")
            .select{|object| object["targetuuid"] == targetuuid }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # Comments::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object["uuid"])
    end
end
