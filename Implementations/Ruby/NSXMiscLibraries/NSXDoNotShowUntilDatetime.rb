
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

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
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

DO_NOT_SHOW_UNTIL_DATETIME_DATA_FOLDER = "#{CATALYST_DATA_FOLDERPATH}/DoNotShowUntilDateTime2"

$DO_NOT_SHOW_UNTIL_DATETIME_IN_MEMORY_MAP = {}

class NSXDoNotShowUntilDatetime

    # NSXDoNotShowUntilDatetime::setDatetime(objectuuid, datetime)
    def self.setDatetime(objectuuid, datetime)
        logobject = {
            "objectuuid" => objectuuid,
            "datetime"   => datetime
        }
        folderpath1 = DO_NOT_SHOW_UNTIL_DATETIME_DATA_FOLDER
        folderpath2 = LucilleCore::indexsubfolderpath(folderpath1)
        filepath1 = "#{folderpath2}/#{LucilleCore::timeStringL22()}.json"
        File.open(filepath1, "w"){|f| f.puts(JSON.pretty_generate(logobject)) }
        $DO_NOT_SHOW_UNTIL_DATETIME_IN_MEMORY_MAP[objectuuid] = datetime
    end

    # NSXDoNotShowUntilDatetime::getDatetimeOrNull(objectuuid)
    def self.getDatetimeOrNull(objectuuid)
        $DO_NOT_SHOW_UNTIL_DATETIME_IN_MEMORY_MAP[objectuuid]
    end

    # NSXDoNotShowUntilDatetime::loadDataFromDisk()
    def self.loadDataFromDisk()
        dataset = {}
        Find.find(DO_NOT_SHOW_UNTIL_DATETIME_DATA_FOLDER) do |path|
            next if !File.file?(path)
            next if File.basename(path)[-5, 5] != '.json'
            item = JSON.parse(IO.read(path))
            dataset[item["objectuuid"]] = DateTime.parse(item["datetime"]).to_time.utc.iso8601
        end
        $DO_NOT_SHOW_UNTIL_DATETIME_IN_MEMORY_MAP = dataset
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

NSXDoNotShowUntilDatetime::loadDataFromDisk()
Thread.new {
    loop {
        sleep 300
        NSXDoNotShowUntilDatetime::loadDataFromDisk()
    }
}
