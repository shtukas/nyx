# encoding: utf-8

# require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
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

KEYVALUESTORE_XSPACE_XCACHE_V2_FOLDER_PATH = "/Users/pascal/x-space/x-cache-v2"

class KeyValueStorePathManager

    # KeyValueStorePathManager::pastFewMonthsExcludingThisOne()
    def self.pastFewMonthsExcludingThisOne()
        months = Dir.entries(KEYVALUESTORE_XSPACE_XCACHE_V2_FOLDER_PATH)
                    .select{|filename| filename[0,1] == '2' }
                    .uniq
                    .sort
        months - [Time.new.strftime("%Y-%m")]
    end

    # KeyValueStorePathManager::filepathAtMonth(month, key)
    def self.filepathAtMonth(month, key)
        repositorylocation = "#{KEYVALUESTORE_XSPACE_XCACHE_V2_FOLDER_PATH}/#{month}"
        filename = "#{Digest::SHA1.hexdigest(key)}.data"
        folderpath = "#{repositorylocation}/#{filename[0,2]}/#{filename[2,2]}/#{filename[4,2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{filename}"
        filepath
    end

    # KeyValueStorePathManager::getFilepathAtXCacheV2(key)
    def self.getFilepathAtXCacheV2(key)
        months = KeyValueStorePathManager::pastFewMonthsExcludingThisOne()
        thismonth = Time.new.strftime("%Y-%m")

        thisMonthFilePath = KeyValueStorePathManager::filepathAtMonth(thismonth, key)

        if File.exists?(thisMonthFilePath) then
            return thisMonthFilePath
        end

        KeyValueStorePathManager::pastFewMonthsExcludingThisOne().sort.reverse.each{|filepath|
            if File.exists?(filepath) then
                FileUtils.mv(filepath, thisMonthFilePath)
                return thisMonthFilePath
            end
        }

        thisMonthFilePath

    end

    # KeyValueStorePathManager::getFilepath(repositorylocation, key)
    def self.getFilepath(repositorylocation, key)
        if repositorylocation.nil? then
            return KeyValueStorePathManager::getFilepathAtXCacheV2(key)
        else
            filename = "#{Digest::SHA1.hexdigest(key)}.data"
            folderpath = "#{repositorylocation}/#{filename[0,2]}/#{filename[2,2]}/#{filename[4,2]}"
            if !File.exists?(folderpath) then
                FileUtils.mkpath(folderpath)
            end
            filepath = "#{folderpath}/#{filename}"
            return filepath
        end
    end

    # KeyValueStorePathManager::getFilepaths(repositorylocation, key)
    def self.getFilepaths(repositorylocation, key)
        filepathFinal = KeyValueStorePathManager::getFilepath(repositorylocation, key)
        filepathTmp   = "#{filepathFinal}-write-tmp-#{SecureRandom.hex(4)}"
        [filepathFinal, filepathTmp]
    end

end

class KeyValueStore

    # KeyValueStore::set(repositorylocation, key, value)
    def self.set(repositorylocation, key, value)
        filepathFinal, filepathTmp = KeyValueStorePathManager::getFilepaths(repositorylocation, key)
        File.open(filepathTmp,'w'){|f| f.write(value)}
        FileUtils.mv(filepathTmp, filepathFinal)
    end

    # KeyValueStore::getOrNull(repositorylocation, key)
    def self.getOrNull(repositorylocation, key)
        filepath, _ = KeyValueStorePathManager::getFilepaths(repositorylocation, key)
        if File.exists?(filepath) then
            FileUtils.touch(filepath)
            IO.read(filepath)
        else
            nil
        end
    end

    # KeyValueStore::getOrDefaultValue(repositorylocation, key, defaultValue)
    def self.getOrDefaultValue(repositorylocation, key, defaultValue)
        maybevalue = KeyValueStore::getOrNull(repositorylocation, key)
        if maybevalue.nil? then
            defaultValue
        else
            maybevalue
        end
    end

    # KeyValueStore::destroy(repositorylocation, key)
    def self.destroy(repositorylocation, key)
        filepath, _ = KeyValueStorePathManager::getFilepaths(repositorylocation, key)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # -----------------------------------------------------

    # KeyValueStore::setFlagTrue(repositorylocation, key)
    def self.setFlagTrue(repositorylocation, key)
        filepath, _ = KeyValueStorePathManager::getFilepaths(repositorylocation, key)
        FileUtils.touch(filepath)
    end

    # KeyValueStore::setFlagFalse(repositorylocation, key)
    def self.setFlagFalse(repositorylocation, key)
        filepath, _ = KeyValueStorePathManager::getFilepaths(repositorylocation, key)
        return if !File.exist?(filepath)
        FileUtils.rm(filepath)
    end

    # KeyValueStore::flagIsTrue(repositorylocation, key)
    def self.flagIsTrue(repositorylocation, key)
        filepath, _ = KeyValueStorePathManager::getFilepaths(repositorylocation, key)
        if File.exists?(filepath) then
            FileUtils.touch(filepath)
            true
        else
            false
        end
    end
end
