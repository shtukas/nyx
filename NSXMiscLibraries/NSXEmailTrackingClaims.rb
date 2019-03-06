
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
        KeyValueStore::set("/Galaxy/DataBank/Catalyst/Email-Metadata-KVStoreRepository", "9bba7e64-2322-4e90-835f-5c4fa5929c87:#{claim["emailuid"]}", JSON.generate(claim))
        KeyValueStore::set("/Galaxy/DataBank/Catalyst/Email-Metadata-KVStoreRepository", "9bba7e64-06e2-4999-a005-bbed7e9c1af3:#{claim["genericContentsItemUUID"]}", JSON.generate(claim))
        KeyValueStore::set("/Galaxy/DataBank/Catalyst/Email-Metadata-KVStoreRepository", "9bba7e64-e0eb-4dee-9340-be439f7891ff:#{claim["streamItemUUID"]}", JSON.generate(claim))
    end

    # NSXEmailTrackingClaims::getClaimByEmailUIDOrNull(emailuid)
    def self.getClaimByEmailUIDOrNull(emailuid)
        claim = KeyValueStore::getOrNull("/Galaxy/DataBank/Catalyst/Email-Metadata-KVStoreRepository", "9bba7e64-2322-4e90-835f-5c4fa5929c87:#{emailuid}")
        return nil if claim.nil?
        JSON.parse(claim)
    end

    # NSXEmailTrackingClaims::getClaimByGenericContentsItemUUIDOrNull(uuid)
    def self.getClaimByGenericContentsItemUUIDOrNull(uuid)
        claim = KeyValueStore::getOrNull("/Galaxy/DataBank/Catalyst/Email-Metadata-KVStoreRepository", "9bba7e64-06e2-4999-a005-bbed7e9c1af3:#{uuid}")
        return nil if claim.nil?
        JSON.parse(claim)
    end

    # NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(uuid)
    def self.getClaimByStreamItemUUIDOrNull(uuid)
        claim = KeyValueStore::getOrNull("/Galaxy/DataBank/Catalyst/Email-Metadata-KVStoreRepository", "9bba7e64-e0eb-4dee-9340-be439f7891ff:#{uuid}")
        return nil if claim.nil?
        JSON.parse(claim)
    end

end