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

=begin

AlgebraicTimePoint {
    "uuid"            : String
    "collection"      : String
    "weigthInSeconds" : Float
}

=end

class NSXAlgebraicTimePoints

    # NSXAlgebraicTimePoints::issuePoint(collection, weigthInSeconds)
    def self.issuePoint(collection, weigthInSeconds)
        uuid = SecureRandom.hex
        point = {
            "uuid" => uuid,
            "collection" => collection,
            "weigthInSeconds" => weigthInSeconds
        }
        BTreeSets::set("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/AlgebraicTimePoints", collection, uuid, point)
    end

    # NSXAlgebraicTimePoints::getCollectionPoints(collection)
    def self.getCollectionPoints(collection)
        BTreeSets::values("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/AlgebraicTimePoints", collection)
    end

    # NSXAlgebraicTimePoints::getCollectionCumulatedValue(collection)
    def self.getCollectionCumulatedValue(collection)
        NSXAlgebraicTimePoints::getCollectionPoints(collection)
            .map{|point| point["weigthInSeconds"] }
            .inject(0, :+)
    end

    # NSXAlgebraicTimePoints::getOneCollectionPositivePointOrNull(collection)
    def self.getOneCollectionPositivePointOrNull(collection)
        NSXAlgebraicTimePoints::getCollectionPoints(collection)
            .select{|point| point["weigthInSeconds"] > 0 }
            .first
    end

    # NSXAlgebraicTimePoints::getOneCollectionNegativePointOrNull(collection)
    def self.getOneCollectionNegativePointOrNull(collection)
        NSXAlgebraicTimePoints::getCollectionPoints(collection)
            .select{|point| point["weigthInSeconds"] < 0 }
            .first
    end

    # NSXAlgebraicTimePoints::attemptCollectionAlgebraicSimplification(collection)
    def self.attemptCollectionAlgebraicSimplification(collection)
        positivePoint = NSXAlgebraicTimePoints::getOneCollectionPositivePointOrNull(collection)
        return if positivePoint.nil?
        negativePoint = NSXAlgebraicTimePoints::getOneCollectionNegativePointOrNull(collection)
        return if negativePoint.nil?
        NSXAlgebraicTimePoints::issuePoint(collection, positivePoint["weigthInSeconds"]+negativePoint["weigthInSeconds"])
        BTreeSets::destroy("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/AlgebraicTimePoints", collection, positivePoint["uuid"])
        BTreeSets::destroy("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/AlgebraicTimePoints", collection, negativePoint["uuid"])
    end

    # NSXAlgebraicTimePoints::metric(collection, basemetric)
    def self.metric(collection, basemetric)
        value = NSXAlgebraicTimePoints::getCollectionCumulatedValue(collection)
        if value > 0 then
            0.2 + (basemetric-0.2)*Math.exp(-(value.to_f/600)) # exponential: -1 in +10 minutes
        else
            basemetric + Math.atan(-value).to_f/100 # the more negative, the higher but close to the base metric
        end

    end

end