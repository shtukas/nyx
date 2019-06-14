
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

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

DO_NOT_SHOW_UNTIL_DATETIME_DATA_FOLDER = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/DoNotShowUntilDateTime"

class NSXData
    # To be decommissioned upon site.
    def self.getValueAsStringOrNull(datarootfolderpath, id)
        id = Digest::SHA1.hexdigest(id)
        pathfragment = "#{id[0,2]}/#{id[2,2]}"
        filepath = "#{datarootfolderpath}/#{pathfragment}/#{id}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
    def self.getValueAsIntegerOrNull(datarootfolderpath, id)
        value = NSXData::getValueAsStringOrNull(datarootfolderpath, id)
        return nil if value.nil?
        value.to_i
    end
    def self.getValueAsIntegerOrDefaultValue(datarootfolderpath, id, defaultValue)
        value = NSXData::getValueAsIntegerOrNull(datarootfolderpath, id)
        return defaultValue if value.nil?
        value
    end
end

class NSXDoNotShowUntilDatetime

    # NSXDoNotShowUntilDatetime::setDatetime(objectuuid, datetime)
    def self.setDatetime(objectuuid, datetime)
        KeyValueStore::set(DO_NOT_SHOW_UNTIL_DATETIME_DATA_FOLDER, "6d3371d3-0600-45d1-93f3-1afa9c3f927f:#{objectuuid}", datetime)
    end

    # NSXDoNotShowUntilDatetime::getStoredDatetimeOrNull(objectuuid)
    def self.getStoredDatetimeOrNull(objectuuid)
        datetime = KeyValueStore::getOrNull(DO_NOT_SHOW_UNTIL_DATETIME_DATA_FOLDER, "6d3371d3-0600-45d1-93f3-1afa9c3f927f:#{objectuuid}")
        return datetime if datetime
        NSXData::getValueAsStringOrNull(DO_NOT_SHOW_UNTIL_DATETIME_DATA_FOLDER, objectuuid)
    end

    # NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(objectuuid)
    def self.getFutureDatetimeOrNull(objectuuid)
        datetime = NSXDoNotShowUntilDatetime::getStoredDatetimeOrNull(objectuuid)
        return nil if datetime.nil?
        datetime = DateTime.parse(datetime).to_time.utc.iso8601
        return nil if Time.new.utc.iso8601 > datetime
        datetime
    end

end
