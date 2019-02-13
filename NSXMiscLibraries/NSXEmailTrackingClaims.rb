
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

class NSXEmailTrackingClaims

    # NSXEmailTrackingClaims::makeclaim(emailuid, genericContentsItemUUID, streamItemUUID)
    def self.makeclaim(emailuid, genericContentsItemUUID, streamItemUUID)
        creationUnixtime = Time.new.to_i
        status = "init"
        lastStatusUpdateUnixtime = Time.new.to_i
        {
            "emailuid"                 => emailuid,
            "genericContentsItemUUID"  => genericContentsItemUUID,
            "streamItemUUID"           => streamItemUUID,
            "creationUnixtime"         => creationUnixtime,
            "status"                   => status,
            "lastStatusUpdateUnixtime" => lastStatusUpdateUnixtime
        }
    end

    # NSXEmailTrackingClaims::commitClaimToDisk(claim)
    def self.commitClaimToDisk(claim)
        KeyValueStore::set(nil, "54b7238c-2322-4e90-835f-5c4fa5929c86:#{claim["emailuid"]}", JSON.generate(claim))
        KeyValueStore::set(nil, "5b6910df-06e2-4999-a005-bbed7e9c1af2:#{claim["genericContentsItemUUID"]}", JSON.generate(claim))
        KeyValueStore::set(nil, "80ea7f3d-e0eb-4dee-9340-be439f7891fe:#{claim["streamItemUUID"]}", JSON.generate(claim))
    end

    # NSXEmailTrackingClaims::getClaimByEmailUIDOrNull(emailuid)
    def self.getClaimByEmailUIDOrNull(emailuid)
        claim = KeyValueStore::getOrNull(nil, "54b7238c-2322-4e90-835f-5c4fa5929c86:#{emailuid}")
        return nil if claim.nil?
        JSON.parse(claim)
    end

    # NSXEmailTrackingClaims::getClaimByGenericContentsItemUUIDOrNull(uuid)
    def self.getClaimByGenericContentsItemUUIDOrNull(uuid)
        claim = KeyValueStore::getOrNull(nil, "5b6910df-06e2-4999-a005-bbed7e9c1af2:#{uuid}")
        return nil if claim.nil?
        JSON.parse(claim)
    end

    # NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(uuid)
    def self.getClaimByStreamItemUUIDOrNull(uuid)
        claim = KeyValueStore::getOrNull(nil, "80ea7f3d-e0eb-4dee-9340-be439f7891fe:#{uuid}")
        return nil if claim.nil?
        JSON.parse(claim)
    end

end