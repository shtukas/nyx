
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

require_relative "Constants.rb"

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

DAY_BUCKETS_FOLDERPATH = "/Galaxy/DataBank/Catalyst/System-Data/DayBuckets"

class DayBucketOperator

    # DayBucketOperator::today()
    def self.today()
        Time.new.to_s[0,10]
    end

    # DayBucketOperator::bucketMaxWeightInHours()
    def self.bucketMaxWeightInHours()
        3
    end

    # DayBucketOperator::getBucketsFilepaths()
    def self.getBucketsFilepaths()
        Dir.entries(DAY_BUCKETS_FOLDERPATH)
            .select{|filename| filename[-5, 5]==".json" }
            .map{|filename| "#{DAY_BUCKETS_FOLDERPATH}/#{filename}" }
    end

    # DayBucketOperator::getBucketDays()
    def self.getBucketDays()
        DayBucketOperator::getBucketsFilepaths()
            .map{|filepath| File.basename(filepath)[0,10] }
    end

    # DayBucketOperator::commitBucketToDisk(bucket)
    def self.commitBucketToDisk(bucket)
        date = bucket["date"]
        filename = "#{date}.json"
        filepath = "#{DAY_BUCKETS_FOLDERPATH}/#{date}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(bucket)) }
    end

    # DayBucketOperator::destroyBucket(date)
    def self.destroyBucket(date)
        filename = "#{date}.json"
        filepath = "#{DAY_BUCKETS_FOLDERPATH}/#{date}.json"
        FileUtils.rm(filepath)
    end

    # DayBucketOperator::getBucketByDateOrNull(date)
    def self.getBucketByDateOrNull(date)
        filename = "#{date}.json"
        filepath = "#{DAY_BUCKETS_FOLDERPATH}/#{date}.json"
        if File.exists?(filepath) then
            return JSON.parse(IO.read(filepath))
        end
        nil
    end

    # DayBucketOperator::getBuckets()
    def self.getBuckets()
        DayBucketOperator::getBucketsFilepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|b1, b2| b1["date"]<=>b2["date"] }
    end

    # DayBucketOperator::futureBuckets()
    def self.futureBuckets()
        DayBucketOperator::getBuckets().select{|bucket| bucket["date"] > DayBucketOperator::today() }
    end

    # DayBucketOperator::bucketToTimestampInHours(bucket)
    def self.bucketToTimestampInHours(bucket)
        bucket["items"].map{|item| item["timespan-in-hours"] }.inject(0, :+)
    end

    # DayBucketOperator::nextDate()
    def self.nextDate()
        (1..1000)
            .map{|index| (Time.at(Time.new.to_i+(86400*index))).to_s[0,10] }
            .select{|date| !DayBucketOperator::getBucketDays().include?(date) }
            .first
    end

    # DayBucketOperator::createNewBucketAtDateWithFirstitem(date, objectuuid, timeEstimationInHours)
    def self.createNewBucketAtDateWithFirstitem(date, objectuuid, timeEstimationInHours)
        bucket = {
            "date"   => date,
            "items"  => []
        }
        bucket["items"] << {
            "objectuuid" => objectuuid,
            "timespan-in-hours" => timeEstimationInHours
        }
        DayBucketOperator::commitBucketToDisk(bucket)
    end

    # DayBucketOperator::addObjectToNextAvailableBucket(objectuuid, timeEstimationInHours)
    def self.addObjectToNextAvailableBucket(objectuuid, timeEstimationInHours)
        buckets = DayBucketOperator::getBuckets()
        if buckets.size==0 then
            date = DayBucketOperator::nextDate()
            DayBucketOperator::createNewBucketAtDateWithFirstitem(date, objectuuid, timeEstimationInHours)
        else
            bucket = buckets
                    .select{|bucket| bucket["date"] > DayBucketOperator::today() }
                    .select{|bucket| (DayBucketOperator::bucketToTimestampInHours(bucket)+timeEstimationInHours) <= DayBucketOperator::bucketMaxWeightInHours()*1.2 }
                    .first
            if bucket then
                bucket["items"] << {
                    "objectuuid" => objectuuid,
                    "timespan-in-hours" => timeEstimationInHours
                }
                DayBucketOperator::commitBucketToDisk(bucket)
            else
                date = DayBucketOperator::nextDate()
                DayBucketOperator::createNewBucketAtDateWithFirstitem(date, objectuuid, timeEstimationInHours)             
            end
        end
    end

    def self.CatalystObjectOrNull()
        today = DayBucketOperator::today()
        dates = DayBucketOperator::getBucketDays()
        pastdays = dates.select{ |date| date < today }
        if pastdays.size>0 then
            # Bad pascal, Bad.
            pastdays.each{|date|
                bucket = DayBucketOperator::getBucketByDateOrNull(date)
                next if bucket.nil
                puts "Rescheduling the following bucket:"
                puts JSON.generate(bucket)
                LucilleCore::pressEnterToContinue()
                bucket["item"].each{|item|
                    puts "Rescheduling item: #{item}"
                    DayBucketOperator::addObjectToNextAvailableBucket(item["objectuuid"], item["timespan-in-hours"])
                }
                # We should now be able to delete the bucket now that it has no items left to reshedule 
                puts "Destroying bucket: #{bucket["date"]}"
                DayBucketOperator::destroyBucket(bucket["date"])
            }
        end
    end

end
