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

    # Placements ------------------------------------------------------------

    # NSXPlacements::issuePlacement(ordinal, description)
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

    # NSXPlacements::getAllPlacements()
    def self.getAllPlacements()
        BTreeSets::values("/Galaxy/DataBank/Catalyst/Placements-KVStoreRepository", "f8adfacb-a470-41b0-b154-1f224dd1ce3b")
        .sort{|p1,p2| p1["ordinal"]<=>p2["ordinal"] }
    end

    # NSXPlacements::selectPlacementOrNullInteractively()
    def self.selectPlacementOrNullInteractively()
        placements = NSXPlacements::getAllPlacements()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("placement", placements, lambda{|placement| placement["description"] })
    end

    # NSXPlacements::destroyPlacement(placement)
    def self.destroyPlacement(placement)
        BTreeSets::destroy("/Galaxy/DataBank/Catalyst/Placements-KVStoreRepository", "f8adfacb-a470-41b0-b154-1f224dd1ce3b", placement["uuid"])
    end

    # Claims ------------------------------------------------------------

    # NSXPlacements::issuePlacementClaim(placementuuid, catalystObjectUUID)
    def self.issuePlacementClaim(placement, catalystObjectUUID)
        claim = {}
        claim["uuid"] = SecureRandom.uuid
        claim["placementuuid"] = placement["uuid"]
        claim["catalystObjectUUID"] = catalystObjectUUID
        BTreeSets::set("/Galaxy/DataBank/Catalyst/Placements-KVStoreRepository", placement["elementsSetUUID"], claim["uuid"], claim)
        claim
    end

    # NSXPlacements::getClaimsForPlacement(placement)
    def self.getClaimsForPlacement(placement)
        BTreeSets::values("/Galaxy/DataBank/Catalyst/Placements-KVStoreRepository", placement["elementsSetUUID"])
    end

    # NSXPlacements::getAllClaimsForAllActivePlacements()
    def self.getAllClaimsForAllActivePlacements()
        NSXPlacements::getAllPlacements()
            .map{|placement| NSXPlacements::getClaimsForPlacement(placement) }
            .flatten
    end
end
