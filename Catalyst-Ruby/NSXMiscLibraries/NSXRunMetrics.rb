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

class NSXRunMetrics
    # NSXRunMetrics::linearMap(x1, y1, x2, y2, x)
    def self.linearMap(x1, y1, x2, y2, x)
        slope = (y2-y1).to_f/(x2-x1)
        (x-x1)*slope + y1
    end

    # NSXRunMetrics::metric1Core(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
    def self.metric1Core(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
        algebraicTimespanInSeconds = points
            .select{|point| (Time.new.to_i - point["unixtime"]) <= periodInSeconds }
            .map{|point| point["algebraicTimespanInSeconds"] }
            .inject(0, :+)
        x1 = 0
        y1 = metricAtZero
        x2 = targetTimeInSeconds
        y2 = metricAtTarget
        x  = algebraicTimespanInSeconds
        return y1 if x < x1
        return metricAtTarget*Math.exp(-(x-x2).to_f/(0.1*targetTimeInSeconds)) if x > x2
        NSXRunMetrics::linearMap(x1, y1, x2, y2, x)
    end

    # NSXRunMetrics::metric1(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
    def self.metric1(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
        m1 = NSXRunMetrics::metric1Core(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
        m2 = NSXRunMetrics::metric1Core(points, targetTimeInSeconds*2, periodInSeconds*2, metricAtZero, metricAtTarget)
        m3 = NSXRunMetrics::metric1Core(points, targetTimeInSeconds*3, periodInSeconds*3, metricAtZero, metricAtTarget)
       [m1, m2, m3].min
    end
end


