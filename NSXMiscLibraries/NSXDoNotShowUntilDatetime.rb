
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

# ----------------------------------------------------------------------

class NSXDoNotShowUntilDatetime
	# NSXDoNotShowUntilDatetime::setDatetime(objectuuid, datetime)
    def self.setDatetime(objectuuid, datetime)
        NSXSystemDataKeyValueStore::set("85362cf4-0a44-4203-aedc-02197d1a243e:#{objectuuid}", datetime)
    end

	# NSXDoNotShowUntilDatetime::getDatetimeOrNull(objectuuid)
    def self.getDatetimeOrNull(objectuuid)
    	datetime = NSXSystemDataKeyValueStore::getOrNull("85362cf4-0a44-4203-aedc-02197d1a243e:#{objectuuid}")
		return nil if datetime.nil?
    	DateTime.parse(datetime).to_time.utc.iso8601
    end
end
