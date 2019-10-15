# encoding: UTF-8

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/BTreeSets.rb"
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
    "uuid"          : String # randomly chosen
    "collectionuid" : String
    "unixtime"      : Integer
    "algebraicTimespanInSeconds" : Float
}
=end

class NSXRunTimes

    # NSXRunTimes::addPoint(collectionuid, unixtime, algebraicTimespanInSeconds)
    def self.addPoint(collectionuid, unixtime, algebraicTimespanInSeconds)
        puts "NSXRunTimes::addPoint(#{collectionuid}, unixtime, #{algebraicTimespanInSeconds})"
        uuid = SecureRandom.hex
        point = {
            "uuid"          => uuid,
            "collectionuid" => collectionuid,
            "unixtime"      => unixtime,
            "algebraicTimespanInSeconds" => algebraicTimespanInSeconds
        }
        BTreeSets::set(nil, "4032a477-81a3-418f-b670-79d099bd5408:#{collectionuid}", uuid, point)
    end

    # NSXRunTimes::addPoint2(point)
    def self.addPoint2(point)
        collectionuid = point["collectionuid"]
        uuid = point["uuid"]
        BTreeSets::set(nil, "4032a477-81a3-418f-b670-79d099bd5408:#{collectionuid}", uuid, point)
    end

    # NSXRunTimes::getPoints(collectionuid)
    def self.getPoints(collectionuid)
        BTreeSets::values(nil, "4032a477-81a3-418f-b670-79d099bd5408:#{collectionuid}")
    end

end


