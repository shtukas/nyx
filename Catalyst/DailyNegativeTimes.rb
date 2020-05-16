
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DailyNegativeTimes.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"
=begin
    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::exists?(filename)
    CoreDataFile::openOrCopyToDesktop(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::exists?(foldername)
    CoreDataDirectory::openFolder(foldername)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

# -----------------------------------------------------------------

class DailyNegativeTimes

    # DailyNegativeTimes::getItem24HoursTimeExpectationInHours(referenceTimeInHours, ordinal)
    def self.getItem24HoursTimeExpectationInHours(referenceTimeInHours, ordinal)
        referenceTimeInHours * (1.to_f / 2**(ordinal+1))
    end

    # DailyNegativeTimes::addNegativeTimePerOrdinalToBankOrDoNothing(uuid, referenceTimeInHours, ordinal, allowedDayIndices)
    def self.addNegativeTimePerOrdinalToBankOrDoNothing(uuid, referenceTimeInHours, ordinal, allowedDayIndices)
        return if !allowedDayIndices.include?(Time.new.wday)
        return if Bank::total(uuid) < -3600 # This values allows small targets to get some time and the big ones not to become overwelming
        return if KeyValueStore::flagIsTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
        return if Time.new.hour < 6
        return if Time.new.hour > 12
        timespan = DailyNegativeTimes::getItem24HoursTimeExpectationInHours(referenceTimeInHours, ordinal) * 3600
        Bank::put(uuid, -timespan, CatalystCommon::pingRetainPeriodInSeconds())
        KeyValueStore::setFlagTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
    end

    # DailyNegativeTimes::addNegativeTimeToBankOrDoNothing(uuid, timeInSeconds, allowedDayIndices)
    def self.addNegativeTimeToBankOrDoNothing(uuid, timeInSeconds, allowedDayIndices)
        return if !allowedDayIndices.include?(Time.new.wday)
        return if Bank::total(uuid) < -3600 # This values allows small targets to get some time and the big ones not to become overwelming
        return if KeyValueStore::flagIsTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
        return if Time.new.hour < 6
        return if Time.new.hour > 12
        Bank::put(uuid, -timeInSeconds, CatalystCommon::pingRetainPeriodInSeconds())
        KeyValueStore::setFlagTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
    end
end
