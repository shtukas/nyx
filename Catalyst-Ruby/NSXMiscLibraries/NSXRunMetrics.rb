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

class NSXRunMetricsShared
    # NSXRunMetricsShared::linearMap(x1, y1, x2, y2, x)
    def self.linearMap(x1, y1, x2, y2, x)
        slope = (y2-y1).to_f/(x2-x1)
        (x-x1)*slope + y1
    end
end

class NSXRunMetrics1 # TimespanTargetThenCollapseToZero


    # NSXRunMetrics1::core(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
    def self.core(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
        algebraicTimespanInSeconds = points
            .select{|point| (Time.new.to_i - point["unixtime"]) <= periodInSeconds }
            .map{|point| point["algebraicTimespanInSeconds"].to_f } # .to_f came up because I accidentally injected a string in there
            .inject(0, :+)
        x1 = 0
        y1 = metricAtZero
        x2 = targetTimeInSeconds
        y2 = metricAtTarget
        x  = algebraicTimespanInSeconds
        return y1 if x < x1
        return metricAtTarget*Math.exp(-(x-x2).to_f/(0.1*targetTimeInSeconds)) if x > x2
        NSXRunMetricsShared::linearMap(x1, y1, x2, y2, x)
    end

    # NSXRunMetrics1::numbers(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
    def self.numbers(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
        [
            NSXRunMetrics1::core(points, targetTimeInSeconds*3, periodInSeconds*3, metricAtZero, metricAtTarget),
            NSXRunMetrics1::core(points, targetTimeInSeconds*2, periodInSeconds*2, metricAtZero, metricAtTarget),
            NSXRunMetrics1::core(points, targetTimeInSeconds*1, periodInSeconds*1, metricAtZero, metricAtTarget)
        ]
    end

    # NSXRunMetrics1::metric(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
    def self.metric(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
        NSXRunMetrics1::numbers(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget).min
    end

end

class NSXRunMetrics2 # TimespanTargetStuckAtMetricAtTarget

    # NSXRunMetrics2::core(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
    def self.core(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
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
        return metricAtTarget if x > x2
        NSXRunMetricsShared::linearMap(x1, y1, x2, y2, x)
    end

    # NSXRunMetrics2::numbers(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
    def self.numbers(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
        [3, 2, 1].map{|indx|
            NSXRunMetrics2::core(points, targetTimeInSeconds*indx, periodInSeconds*indx, metricAtZero, metricAtTarget)
        }
    end

    # NSXRunMetrics2::metric(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
    def self.metric(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget)
        NSXRunMetrics2::numbers(points, targetTimeInSeconds, periodInSeconds, metricAtZero, metricAtTarget).min
    end
end

class NSXRunMetrics3 # CountTargetThenCollapseToZero

    # NSXRunMetrics3::core(points, targetCount, periodInSeconds, metricAtZero, metricAtTarget)
    def self.core(points, targetCount, periodInSeconds, metricAtZero, metricAtTarget)
        count = points
            .select{|point| (Time.new.to_i - point["unixtime"]) <= periodInSeconds }
            .size
        # Here, unlike the timespan counterpart, we do not care how long  was spent on that point/hit
        x1 = 0
        y1 = metricAtZero
        x2 = targetCount
        y2 = metricAtTarget
        x  = count
        return y1 if x < x1
        return metricAtTarget*Math.exp(-(x-x2).to_f/(0.1*targetCount)) if x > x2
        NSXRunMetricsShared::linearMap(x1, y1, x2, y2, x)
    end

    # NSXRunMetrics3::numbers(points, targetCount, periodInSeconds, metricAtZero, metricAtTarget)
    def self.numbers(points, targetCount, periodInSeconds, metricAtZero, metricAtTarget)
        (1..7).to_a.reverse.map{|indx|
            NSXRunMetrics3::core(points, targetCount*indx, periodInSeconds*indx, metricAtZero, metricAtTarget)
        }
    end

    # NSXRunMetrics3::metric(points, targetCount, periodInSeconds, metricAtZero, metricAtTarget)
    def self.metric(points, targetCount, periodInSeconds, metricAtZero, metricAtTarget)
        NSXRunMetrics3::numbers(points, targetCount, periodInSeconds, metricAtZero, metricAtTarget).min
    end
end
