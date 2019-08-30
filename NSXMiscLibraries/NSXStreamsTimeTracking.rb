
# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'find'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
KeyValueStore::set(repositorylocation or nil, key, value)
KeyValueStore::getOrNull(repositorylocation or nil, key)
KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

# ----------------------------------------------------------------------

class NSXStreamsTimeTracking

    # NSXStreamsTimeTracking::currentDate()
    def self.currentDate()
        Time.now.utc.iso8601[0,10]
    end

    # NSXStreamsTimeTracking::addTimeInSecondsToStream(streamuuid, seconds)
    def self.addTimeInSecondsToStream(streamuuid, seconds)
        Torr::event("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Streams-KVStoreRepository", "a12b763e-6e84-4c31-9e5e-470cfbd93a32:#{streamuuid}", seconds)
    end

    # NSXStreamsTimeTracking::getTimeInSecondsForStream(streamuuid)
    def self.getTimeInSecondsForStream(streamuuid)
        Torr::weight("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Streams-KVStoreRepository", "a12b763e-6e84-4c31-9e5e-470cfbd93a32:#{streamuuid}", 86400)
    end

    # NSXStreamsTimeTracking::streamWideMetric(streamuuid, expectationTimeInSeconds, metricAtTarget)
    def self.streamWideMetric(streamuuid, expectationTimeInSeconds, metricAtZero, metricAtTarget)
        Torr::metric("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Streams-KVStoreRepository", "a12b763e-6e84-4c31-9e5e-470cfbd93a32:#{streamuuid}", 86400, expectationTimeInSeconds, metricAtZero, metricAtTarget)
    end

end
