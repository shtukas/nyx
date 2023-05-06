# encoding: utf-8

# require "/Users/pascal/Galaxy/Software/Lucille-Ruby-Libraries/XCache.rb"
=begin
    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)

    XCache::setFlag(key, flag)
    XCache::getFlag(key)

    XCache::filepath(key)
=end

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf(dir)

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'json'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'find'

# -----------------------------------------------------------------------------------

=begin

The logic of the cache is simple. We store at the current date and if we read from a past date we move the file to the 
current date. Date folders older than 60 days are deleted. This means that a value is available for 60 days after 
the last time it was written or read.

There is currently no prevention against the cache becoming arbitrarily big.

=end

XSPACE_XCACHE_V1_FOLDER_PATH = "#{ENV['HOME']}/x-space/xcache-v1-days"

class XCachePaths1

    # XCachePaths1::today()
    def self.today()
        Time.new.to_s[0, 10]
    end

    # XCachePaths1::dates()
    def self.dates()
        dates = Dir.entries(XSPACE_XCACHE_V1_FOLDER_PATH)
                    .select{|filename| filename[0,1] == '2' }
                    .sort

        # Automatic garbage collection
        # We used to keep 60 folders, but now we keep all dates after 60 days ago
        # This came up when we were merging x-caches from various computers, 
        # we had more than 60 folders but all within 60 days, for instance, 2022-07-15 and 2022-07-15+A
        twoMonthsAgo = Time.at((Time.new.to_i - 86400*60)).to_s[0, 10]
        while !dates.empty? and dates[0][0, 10] < twoMonthsAgo do
            date = dates.shift
            datefolder = "#{XSPACE_XCACHE_V1_FOLDER_PATH}/#{date}"
            FileUtils.rm_rf(datefolder)
        end

        dates
    end

    # XCachePaths1::filepathAtDate(key, date)
    def self.filepathAtDate(key, date)
        datefolder = "#{XSPACE_XCACHE_V1_FOLDER_PATH}/#{date}"
        filename = "#{Digest::SHA1.hexdigest(key)}.data"
        folderpath = "#{datefolder}/#{filename[0,2]}"
        filepath = "#{folderpath}/#{filename}"
        if !File.exist?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath
    end

    # XCachePaths1::getFilepath(key)
    def self.getFilepath(key)
        filepaths = XCachePaths1::dates()
            .map{|date| XCachePaths1::filepathAtDate(key, date) }
            .select{|filepath| File.exist?(filepath) }

        if filepaths.size == 0 then
            return XCachePaths1::filepathAtDate(key, XCachePaths1::today())
        end

        while filepaths.size > 1 do
            filepath = filepaths.shift
            FileUtils.rm(filepath)
        end

        filepath = filepaths[0]
        filepathForToday = XCachePaths1::filepathAtDate(key, XCachePaths1::today())

        if filepath == filepathForToday then
            return filepath
        else
            filepathForTodayTmp = "#{filepathForToday}-#{SecureRandom.hex(4)}"
            FileUtils.cp(filepath, filepathForTodayTmp)
            FileUtils.mv(filepathForTodayTmp, filepathForToday)
            return filepathForToday
        end
    end

    # XCachePaths1::getFilepathWithTmpLocation(key)
    def self.getFilepathWithTmpLocation(key)
        filepathFinal = XCachePaths1::getFilepath(key)
        filepathTmp   = "#{filepathFinal}-#{SecureRandom.hex(4)}"
        [filepathFinal, filepathTmp]
    end

    # XCachePaths1::getFilepathsForDeletion(key)
    def self.getFilepathsForDeletion(key)
        XCachePaths1::dates()
            .map{|date| XCachePaths1::filepathAtDate(key, date) }
            .select{|filepath| File.exist?(filepath) }
    end
end

class XCache

    # XCache::set(key, value)
    def self.set(key, value)
        filepathFinal, filepathTmp = XCachePaths1::getFilepathWithTmpLocation(key)
        File.open(filepathTmp,'w'){|f| f.write(value)}
        FileUtils.mv(filepathTmp, filepathFinal)
    end

    # XCache::getOrNull(key)
    def self.getOrNull(key)
        filepath, _ = XCachePaths1::getFilepathWithTmpLocation(key)
        if File.exist?(filepath) then
            return IO.read(filepath)
        end
        nil
    end

    # XCache::getOrDefaultValue(key, defaultValue)
    def self.getOrDefaultValue(key, defaultValue)
        maybevalue = XCache::getOrNull(key)
        if maybevalue.nil? then
            defaultValue
        else
            maybevalue
        end
    end

    # XCache::destroy(key)
    def self.destroy(key)
        XCachePaths1::getFilepathsForDeletion(key)
            .each{|filepath|
                if File.exist?(filepath) then
                    FileUtils.rm(filepath)
                end
            }
    end

    # -----------------------------------------------------

    # XCache::setFlag(key, flag)
    def self.setFlag(key, flag)
        XCache::set(key, flag ? "true" : "false")
    end

    # XCache::getFlag(key)
    def self.getFlag(key)
        XCache::getOrNull(key) == "true"
    end

    # -----------------------------------------------------
    # XCache::filepath(key)
    def self.filepath(key)
        XCachePaths1::getFilepath(key)
    end
end
