class DataStore1

    # -------------------------------------------------------
    # Private Config

    # DataStore1::energyGridDataStore1Folder()
    def self.energyGridDataStore1Folder()
        "/Volumes/EnergyGrid1/Data/Pascal/Galaxy/Stargate/DataStore1"
    end

    # DataStore1::outGoingBufferFolder()
    def self.outGoingBufferFolder()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/DataStore1OutGoingBuffer"
    end

    # -------------------------------------------------------
    # Private Files

    # DataStore1::requestLocalCacheFilepath(nhash)
    def self.requestLocalCacheFilepath(nhash)
        XCache::filepath(nhash)
    end

    # DataStore1::computeOutGoingBufferFilepath(nhash)
    def self.computeOutGoingBufferFilepath(nhash)
        "#{DataStore1::outGoingBufferFolder()}/#{nhash}"
    end

    # DataStore1::computeEnergyGridFilepathForFilename(nhash)
    def self.computeEnergyGridFilepathForFilename(nhash)
        month = "2022-09"
        fragment = nhash[7, 2]
        folderpath = "#{DataStore1::energyGridDataStore1Folder()}/#{month}/#{fragment}"
        "#{folderpath}/#{nhash}"
    end

    # DataStore1::computeEnergyGridFilepathErrorIfNotAcquisable(nhash)
    def self.computeEnergyGridFilepathErrorIfNotAcquisable(nhash)
        if !File.exists?(DataStore1::energyGridDataStore1Folder()) then
            raise "(error: c1244503-8ab9-4f51-aa7b-fc19ddad87f8) nhash: #{nhash}"
        end
        filepath = DataStore1::computeEnergyGridFilepathForFilename(nhash)
        folderpath = File.dirname(filepath)
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath
    end

    # -------------------------------------------------------
    # Private Ops

    # DataStore1::acquireFilepathsForWriting(nhash) # Array[filepath]
    def self.acquireFilepathsForWriting(nhash)
        filepaths1 = [
            DataStore1::computeOutGoingBufferFilepath(nhash),
            DataStore1::requestLocalCacheFilepath(nhash)
        ]
        filepaths2 = Machines::theOtherInstanceIds()
                        .map{|targetInstanceId|
                            "#{StargateMultiInstanceShared::pathToCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.file-datastore1"
                        }

        filepaths1 + filepaths2
    end

    # DataStore1::acquireFilepathsForWritingNoCommLine(nhash) # Array[filepath]
    def self.acquireFilepathsForWritingNoCommLine(nhash)
        [
            DataStore1::computeOutGoingBufferFilepath(nhash),
            DataStore1::requestLocalCacheFilepath(nhash)
        ]
        [
            DataStore1::computeOutGoingBufferFilepath(nhash)
        ]
    end

    # -------------------------------------------------------
    # Public

    # DataStore1::putDataByContent(content) # nhash
    def self.putDataByContent(content)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(content)}"
        DataStore1::acquireFilepathsForWriting(nhash).each{|filepath|
            next if File.exists?(filepath)
            File.open(filepath, "w"){|f| f.write(content) }
        }
        nhash
    end

    # DataStore1::putDataByFilepath(sourcefilepath) # nhash
    def self.putDataByFilepath(sourcefilepath)
        nhash = "SHA256-#{Digest::SHA256.file(sourcefilepath).hexdigest}"
        DataStore1::acquireFilepathsForWriting(nhash).each{|filepath|
            next if File.exists?(filepath)
            FileUtils.cp(sourcefilepath, filepath)
        }
        nhash
    end

    # DataStore1::putDataByFilepathNoCommLine(sourcefilepath) # nhash
    def self.putDataByFilepathNoCommLine(sourcefilepath)
        nhash = "SHA256-#{Digest::SHA256.file(sourcefilepath).hexdigest}"
        DataStore1::acquireFilepathsForWritingNoCommLine(nhash).each{|filepath|
            next if File.exists?(filepath)
            FileUtils.cp(sourcefilepath, filepath)
        }
        nhash
    end

    # DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(nhash, optimiseUsingCacheWrites) # filepath
    def self.acquireNearestFilepathForReadingErrorIfNotAcquisable(nhash, optimiseUsingCacheWrites)
        filepath = DataStore1::requestLocalCacheFilepath(nhash)
        if File.exists?(filepath) then
            return filepath
        end

        filepath = DataStore1::computeOutGoingBufferFilepath(nhash)
        if File.exists?(filepath) then
            if optimiseUsingCacheWrites then
                #puts "DataStore1: caching nhash: #{nhash}"
                FileUtils.cp(filepath, DataStore1::requestLocalCacheFilepath(nhash)) # Caching the file from the out buffer into the local cache
            end
            return filepath
        end

        EnergyGrid::acquireEnergyGridOrExit()

        filepath = DataStore1::computeEnergyGridFilepathErrorIfNotAcquisable(nhash)
        if File.exists?(filepath) then
            if optimiseUsingCacheWrites then
                #puts "DataStore1: caching nhash: #{nhash}"
                FileUtils.cp(filepath, DataStore1::requestLocalCacheFilepath(nhash)) # Caching the file from Energy Grid into the local cache
            end
            return filepath
        end

        raise "(error: 22825ba0-7b86-452d-be25-af73ac31ab61) nhash: #{nhash}"
    end

    # DataStore1::outBufferToEnergyGrid()
    def self.outBufferToEnergyGrid()
        LucilleCore::locationsAtFolder(DataStore1::outGoingBufferFolder()).each{|filepath1|
            next if !File.basename(filepath1).start_with?("SHA256-")
            nhash = File.basename(filepath1)
            filepath2 = DataStore1::computeEnergyGridFilepathErrorIfNotAcquisable(nhash)
            puts "out buffer to energy grid: #{nhash}"
            if File.exists?(filepath2) then
                FileUtils.rm(filepath1)
                next
            end
            FileUtils.cp(filepath1, filepath2)
            FileUtils.rm(filepath1)
        }
    end
end
