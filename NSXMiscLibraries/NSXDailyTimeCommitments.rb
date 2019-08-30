
# encoding: UTF-8

class NSXDailyTimeCommitments

    # NSXDailyTimeCommitments::commitTimingEntry(objectuuid, timingEntry)
    def self.commitTimingEntry(objectuuid, timingEntry)
        # This code was abstracted away from the agent when Multi Instances was born
        BTreeSets::set(nil, "entry-uuid-to-timing-set-uuids:qw213ew:#{objectuuid}", SecureRandom.uuid, timingEntry)
    end
end
