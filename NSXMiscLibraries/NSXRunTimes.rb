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

=begin
Point {
    "uuid"              : String # randomly chosen
    "collectionuid"     : String
    "unixtime"          : Integer
    "timespanInSeconds" : Float
}
=end

class NSXRunTimes

    # NSXRunTimes::addTimespan(collectionuid, unixtime, timespanInSeconds)
    def self.addTimespan(collectionuid, unixtime, timespanInSeconds)
        uuid = SecureRandom.hex
        point = {
            "uuid"              => uuid,
            "collectionuid"     => collectionuid,
            "unixtime"          => unixtime,
            "timespanInSeconds" => timespanInSeconds
        }
        BTreeSets::set(nil, collectionuid, uuid, point)
    end

    # NSXRunTimes::getCollection(collectionuid)
    def self.getCollection(collectionuid)
        BTreeSets::values(nil, collectionuid)
    end

    # NSXRunTimes::pointsToMetric1(points)
    def self.pointsToMetric1(points)
        return 0.7
    end


end


