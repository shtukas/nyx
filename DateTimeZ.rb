
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


class DateTimeZ

    # DateTimeZ::make(targetuuid, datetime)
    def self.make(targetuuid, datetime)
        raise "[DateTimeZ errror 4E5352A4]" if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
        {
            "uuid"            => SecureRandom.uuid,
            "nyxNxSet"        => "1bc9b712-09be-44da-9551-f22d70a3f15d",
            "unixtime"        => Time.new.to_f,
            "targetuuid"      => targetuuid,
            "datetimeISO8601" => datetime
        }
    end

    # DateTimeZ::issue(targetuuid, datetime)
    def self.issue(targetuuid, datetime)
        object = DateTimeZ::make(targetuuid, datetime)
        NyxObjects::put(object)
        object
    end

    # DateTimeZ::getForTargetUUIDInTimeOrder(targetuuid)
    def self.getForTargetUUIDInTimeOrder(targetuuid)
        NyxObjects::getSet("1bc9b712-09be-44da-9551-f22d70a3f15d")
            .select{|object| object["targetuuid"] == targetuuid }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # DateTimeZ::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object["uuid"])
    end
end
