
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "json"
require "find"

require 'time'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Iphetra.rb"
=begin
    Iphetra::commitObjectToDisk(repositoryRootFolderPath, setuuid, object)
    Iphetra::getObjectByUUIDOrNull(repositoryRootFolderPath, setuuid, objectuuid)
    Iphetra::getObjects(repositoryRootFolderPath, setuuid)
=end

# ----------------------------------------------------------------------

CATALYST_METRIC_WEIGHT_IPHETRA_SETUUID_PREFIX = "1b26d580-05ad-46e0-a008-170d468d8337"

class NSXMetricWeight

    # NSXMetricWeight::unixtimeToWeightCoefficientMultiplier(unixtime)
    def self.unixtimeToWeightCoefficientMultiplier(unixtime)
        1-Math.exp(-(Time.new.to_f-unixtime).to_f/3600)
    end

    # NSXMetricWeight::unixtimesToWeightCoefficientMultiplier(unixtimes)
    def self.unixtimesToWeightCoefficientMultiplier(unixtimes)
        unixtimes.map{|unixtime| NSXMetricWeight::unixtimeToWeightCoefficientMultiplier(unixtime) }.inject(1, :*)
    end

    # NSXMetricWeight::unixtimesMetricCombination(unixtimes, metric): [weightCoefficientMultiplier, newMetric]
    def self.unixtimesMetricCombination(unixtimes, metric)
        weightCoefficientMultiplier = NSXMetricWeight::unixtimesToWeightCoefficientMultiplier(unixtimes)
        [ weightCoefficientMultiplier, weightCoefficientMultiplier*metric ]
    end

    # NSXMetricWeight::markObject(objectuuid)
    def self.markObject(objectuuid)
        setuuid = "#{CATALYST_METRIC_WEIGHT_IPHETRA_SETUUID_PREFIX}/#{objectuuid}"
        object = {
            "uuid"     => SecureRandom.hex,
            "unixtime" => Time.new.to_i
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, setuuid, object)
    end

    # NSXMetricWeight::getObjectMarks(objectuuid)
    def self.getObjectMarks(objectuuid)
        setuuid = "#{CATALYST_METRIC_WEIGHT_IPHETRA_SETUUID_PREFIX}/#{objectuuid}"
        Iphetra::getObjects(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, setuuid)
            .map{|object| object["unixtime"] }
    end

    # NSXMetricWeight::updateObjectWithNewMetric(object: CatalystObject): CatalystObject
    def self.updateObjectWithNewMetric(object)
        unixtimes = NSXMetricWeight::getObjectMarks(object["uuid"])
        return object if unixtimes.size==0
        weightCoefficientMultiplier, newMetric = NSXMetricWeight::unixtimesMetricCombination(unixtimes, object["metric"])
        object["metric"] = newMetric
        object[":NSXMetricWeight-weight-coefficient-multiplier:"] = weightCoefficientMultiplier
        object
    end

end
