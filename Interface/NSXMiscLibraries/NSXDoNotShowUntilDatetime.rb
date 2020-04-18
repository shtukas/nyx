
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "json"
require "find"

require 'time'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)

    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

class NSXDoNotShowUntilDatetime

    # NSXDoNotShowUntilDatetime::setDatetime(objectuuid, datetime)
    def self.setDatetime(objectuuid, datetime)
        KeyValueStore::set(nil, objectuuid, datetime)
    end

    # NSXDoNotShowUntilDatetime::getDatetimeOrNull(objectuuid)
    def self.getDatetimeOrNull(objectuuid)
        KeyValueStore::getOrNull(nil, objectuuid)
    end

    # NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(objectuuid)
    def self.getFutureDatetimeOrNull(objectuuid)
        datetime = NSXDoNotShowUntilDatetime::getDatetimeOrNull(objectuuid)
        return nil if datetime.nil?
        datetime = DateTime.parse(datetime).to_time.utc.iso8601
        return nil if Time.new.utc.iso8601 > datetime
        datetime
    end

end
