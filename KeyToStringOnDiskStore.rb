# encoding: utf-8

KEYVALUESTORE_XSPACE_XCACHE_V2_FOLDER_PATH = "/Users/pascal/x-space/x-cache-v2"

class KeyToStringOnDiskStorePathManager

    # KeyToStringOnDiskStorePathManager::pastFewMonthsExcludingThisOne()
    def self.pastFewMonthsExcludingThisOne()
        months = Dir.entries(KEYVALUESTORE_XSPACE_XCACHE_V2_FOLDER_PATH)
                    .select{|filename| filename[0,1] == '2' }
                    .uniq
                    .sort
        months - [Time.new.strftime("%Y-%m")]
    end

    # KeyToStringOnDiskStorePathManager::filepathAtMonth(month, key)
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

    # KeyToStringOnDiskStorePathManager::getFilepathAtXCacheV2(key)
    def self.getFilepathAtXCacheV2(key)
        months = KeyToStringOnDiskStorePathManager::pastFewMonthsExcludingThisOne()
        thismonth = Time.new.strftime("%Y-%m")

        thisMonthFilePath = KeyToStringOnDiskStorePathManager::filepathAtMonth(thismonth, key)

        if File.exists?(thisMonthFilePath) then
            return thisMonthFilePath
        end

        KeyToStringOnDiskStorePathManager::pastFewMonthsExcludingThisOne().sort.reverse.each{|filepath|
            if File.exists?(filepath) then
                FileUtils.mv(filepath, thisMonthFilePath)
                return thisMonthFilePath
            end
        }

        thisMonthFilePath

    end

    # KeyToStringOnDiskStorePathManager::getFilepath(repositorylocation, key)
    def self.getFilepath(repositorylocation, key)
        if repositorylocation.nil? then
            return KeyToStringOnDiskStorePathManager::getFilepathAtXCacheV2(key)
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

    # KeyToStringOnDiskStorePathManager::getFilepaths(repositorylocation, key)
    def self.getFilepaths(repositorylocation, key)
        filepathFinal = KeyToStringOnDiskStorePathManager::getFilepath(repositorylocation, key)
        filepathTmp   = "#{filepathFinal}-write-tmp-#{SecureRandom.hex(4)}"
        [filepathFinal, filepathTmp]
    end

end

class KeyToStringOnDiskStore

    # KeyToStringOnDiskStore::set(repositorylocation, key, value)
    def self.set(repositorylocation, key, value)
        filepathFinal, filepathTmp = KeyToStringOnDiskStorePathManager::getFilepaths(repositorylocation, key)
        File.open(filepathTmp,'w'){|f| f.write(value)}
        FileUtils.mv(filepathTmp, filepathFinal)
    end

    # KeyToStringOnDiskStore::getOrNull(repositorylocation, key)
    def self.getOrNull(repositorylocation, key)
        filepath, _ = KeyToStringOnDiskStorePathManager::getFilepaths(repositorylocation, key)
        if File.exists?(filepath) then
            FileUtils.touch(filepath)
            IO.read(filepath)
        else
            nil
        end
    end

    # KeyToStringOnDiskStore::getOrDefaultValue(repositorylocation, key, defaultValue)
    def self.getOrDefaultValue(repositorylocation, key, defaultValue)
        maybevalue = KeyToStringOnDiskStore::getOrNull(repositorylocation, key)
        if maybevalue.nil? then
            defaultValue
        else
            maybevalue
        end
    end

    # KeyToStringOnDiskStore::destroy(repositorylocation, key)
    def self.destroy(repositorylocation, key)
        filepath, _ = KeyToStringOnDiskStorePathManager::getFilepaths(repositorylocation, key)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # -----------------------------------------------------

    # KeyToStringOnDiskStore::setFlagTrue(repositorylocation, key)
    def self.setFlagTrue(repositorylocation, key)
        filepath, _ = KeyToStringOnDiskStorePathManager::getFilepaths(repositorylocation, key)
        FileUtils.touch(filepath)
    end

    # KeyToStringOnDiskStore::setFlagFalse(repositorylocation, key)
    def self.setFlagFalse(repositorylocation, key)
        filepath, _ = KeyToStringOnDiskStorePathManager::getFilepaths(repositorylocation, key)
        return if !File.exist?(filepath)
        FileUtils.rm(filepath)
    end

    # KeyToStringOnDiskStore::flagIsTrue(repositorylocation, key)
    def self.flagIsTrue(repositorylocation, key)
        filepath, _ = KeyToStringOnDiskStorePathManager::getFilepaths(repositorylocation, key)
        if File.exists?(filepath) then
            FileUtils.touch(filepath)
            true
        else
            false
        end
    end
end
