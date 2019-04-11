#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

class NSXPlacements

    #NSXPlacements::issuePlacement(ordinal, description)
    def self.issuePlacement(ordinal, description)
        placement = {}
        placement["uuid"] = SecureRandom.uuid
        placement["creationUnixtime"] = Time.new.to_i
        placement["ordinal"] = ordinal
        placement["description"] = description
        placement["elementsSetUUID"] = SecureRandom.uuid
        BTreeSets::set("/Galaxy/DataBank/Catalyst/Placements-KVStoreRepository", "f8adfacb-a470-41b0-b154-1f224dd1ce3b", placement["uuid"], placement)
        placement
    end

    #NSXPlacements::getAllPlacements()
    def self.getAllPlacements()
        BTreeSets::values("/Galaxy/DataBank/Catalyst/Placements-KVStoreRepository", "f8adfacb-a470-41b0-b154-1f224dd1ce3b")
    end

    #NSXPlacements::issuePlacementClaim(placementuuid, catalystObjectUUID)
    def self.issuePlacementClaim(placementuuid, catalystObjectUUID)
        claim = {}
        claim["uuid"] = SecureRandom.uuid
        claim["placementuuid"] = placementuuid
        claim["catalystObjectUUID"] = catalystObjectUUID
        BTreeSets::set("/Galaxy/DataBank/Catalyst/Placements-KVStoreRepository", "c0151d3f-1761-42c1-9e51-68360f7c9d57", claim["uuid"], claim)
        claim
    end

    #NSXPlacements::getAllClaims()
    def self.getAllClaims()
        BTreeSets::values("/Galaxy/DataBank/Catalyst/Placements-KVStoreRepository", "c0151d3f-1761-42c1-9e51-68360f7c9d57")
    end

end
