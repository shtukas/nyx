
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "json"
require "find"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

# ----------------------------------------------------------------------

=begin

(DayBucket) {
    "date"   : String
    "items"  : Array[DateBucketItem]
}

DateBucketItem : {
    "objectuuid"        : String
    "timespan-in-hours" : Float    
}

Filenames for buckets are of the form: YYYY-MM-DD.json 

=end

DAY_BUCKETS_FOLDERPATH = "/Galaxy/DataBank/Catalyst/System-Data/Day-Buckets"

class NSXDayBucketOperator

    # NSXDayBucketOperator::today()
    def self.today()
        Time.new.to_s[0,10]
    end

    # NSXDayBucketOperator::bucketMaxWeightInHours()
    def self.bucketMaxWeightInHours()
        3
    end

    # NSXDayBucketOperator::getBucketsFilepaths()
    def self.getBucketsFilepaths()
        Dir.entries(DAY_BUCKETS_FOLDERPATH)
            .select{|filename| filename[-5, 5]==".json" }
            .map{|filename| "#{DAY_BUCKETS_FOLDERPATH}/#{filename}" }
    end

    # NSXDayBucketOperator::getBucketDays()
    def self.getBucketDays()
        NSXDayBucketOperator::getBucketsFilepaths()
            .map{|filepath| File.basename(filepath)[0,10] }
    end

    # NSXDayBucketOperator::commitBucketToDisk(bucket)
    def self.commitBucketToDisk(bucket)
        date = bucket["date"]
        filename = "#{date}.json"
        filepath = "#{DAY_BUCKETS_FOLDERPATH}/#{date}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(bucket)) }
    end

    # NSXDayBucketOperator::destroyBucket(date)
    def self.destroyBucket(date)
        filename = "#{date}.json"
        filepath = "#{DAY_BUCKETS_FOLDERPATH}/#{date}.json"
        FileUtils.rm(filepath)
    end

    # NSXDayBucketOperator::getBucketByDateOrNull(date)
    def self.getBucketByDateOrNull(date)
        filename = "#{date}.json"
        filepath = "#{DAY_BUCKETS_FOLDERPATH}/#{date}.json"
        if File.exists?(filepath) then
            return JSON.parse(IO.read(filepath))
        end
        nil
    end

    # NSXDayBucketOperator::getBuckets()
    def self.getBuckets()
        NSXDayBucketOperator::getBucketsFilepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|b1, b2| b1["date"]<=>b2["date"] }
    end

    # NSXDayBucketOperator::futureBuckets()
    def self.futureBuckets()
        NSXDayBucketOperator::getBuckets().select{|bucket| bucket["date"] > NSXDayBucketOperator::today() }
    end

    # NSXDayBucketOperator::bucketToTimestampInHours(bucket)
    def self.bucketToTimestampInHours(bucket)
        bucket["items"].map{|item| item["timespan-in-hours"] }.inject(0, :+)
    end

    # NSXDayBucketOperator::nextDate()
    def self.nextDate()
        (1..1000)
            .map{|index| (Time.at(Time.new.to_i+(86400*index))).to_s[0,10] }
            .select{|date| !NSXDayBucketOperator::getBucketDays().include?(date) }
            .first
    end

    # NSXDayBucketOperator::createNewBucketAtDateWithFirstitem(date, objectuuid, timeEstimationInHours)
    def self.createNewBucketAtDateWithFirstitem(date, objectuuid, timeEstimationInHours)
        bucket = {
            "date"   => date,
            "items"  => []
        }
        bucket["items"] << {
            "objectuuid" => objectuuid,
            "timespan-in-hours" => timeEstimationInHours
        }
        NSXDayBucketOperator::commitBucketToDisk(bucket)
    end

    # NSXDayBucketOperator::addObjectToNextAvailableBucket(objectuuid, timeEstimationInHours)
    def self.addObjectToNextAvailableBucket(objectuuid, timeEstimationInHours)
        buckets = NSXDayBucketOperator::getBuckets()
        if buckets.size==0 then
            date = NSXDayBucketOperator::nextDate()
            NSXDayBucketOperator::createNewBucketAtDateWithFirstitem(date, objectuuid, timeEstimationInHours)
        else
            bucket = buckets
                    .select{|bucket| bucket["date"] > NSXDayBucketOperator::today() }
                    .select{|bucket| (NSXDayBucketOperator::bucketToTimestampInHours(bucket)+timeEstimationInHours) <= NSXDayBucketOperator::bucketMaxWeightInHours()*1.2 }
                    .first
            if bucket then
                bucket["items"] << {
                    "objectuuid" => objectuuid,
                    "timespan-in-hours" => timeEstimationInHours
                }
                NSXDayBucketOperator::commitBucketToDisk(bucket)
            else
                date = NSXDayBucketOperator::nextDate()
                NSXDayBucketOperator::createNewBucketAtDateWithFirstitem(date, objectuuid, timeEstimationInHours)             
            end
        end
    end

end
