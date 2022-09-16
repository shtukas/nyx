class DataStore1

    # -------------------------------------------------------
    # Private Config

    # DataStore1::energyGridDataStore1Folder()
    def self.energyGridDataStore1Folder()
        "/Volumes/EnergyGrid1/Data/Pascal/Galaxy/DataStore1"
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
                            "#{Config::starlightCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.file-datastore1"
                        }

        filepaths1 + filepaths2
    end

    # DataStore1::acquireFilepathsForWritingNoCommLine(nhash) # Array[filepath]
    def self.acquireFilepathsForWritingNoCommLine(nhash)
        [
            DataStore1::computeOutGoingBufferFilepath(nhash),
            DataStore1::requestLocalCacheFilepath(nhash)
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
    end

    # DataStore1::putDataByFilepath(sourcefilepath) # nhash
    def self.putDataByFilepath(sourcefilepath)
        nhash = "SHA256-#{Digest::SHA256.file(sourcefilepath).hexdigest}"
        DataStore1::acquireFilepathsForWriting(nhash).each{|filepath|
            next if File.exists?(filepath)
            FileUtils.cp(sourcefilepath, filepath)
        }
    end

    # DataStore1::putDataByFilepathNoCommLine(sourcefilepath) # nhash
    def self.putDataByFilepathNoCommLine(sourcefilepath)
        nhash = "SHA256-#{Digest::SHA256.file(sourcefilepath).hexdigest}"
        DataStore1::acquireFilepathsForWritingNoCommLine(nhash).each{|filepath|
            next if File.exists?(filepath)
            FileUtils.cp(sourcefilepath, filepath)
        }
    end

    # DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(nhash) # Array[filepath]
    def self.acquireNearestFilepathForReadingErrorIfNotAcquisable(nhash)
        filepath = DataStore1::requestLocalCacheFilepath(nhash)
        return filepath if File.exists?(filepath)

        filepath = DataStore1::computeOutGoingBufferFilepath(nhash)
        return filepath if File.exists?(filepath)

        EnergyGrid::acquireEnergyGridOrExit()

        filepath = DataStore1::computeEnergyGridFilepathErrorIfNotAcquisable(nhash)
        return filepath if File.exists?(filepath)

        raise "(error: 22825ba0-7b86-452d-be25-af73ac31ab61) nhash: #{nhash}"
    end

    # DataStore1::outBufferToEnergyGrid()
    def self.outBufferToEnergyGrid()
        LucilleCore::locationsAtFolder(DataStore1::outGoingBufferFolder()).each{|filepath1|
            next if !File.basename(filepath1).start_with?("SHA256-")
            nhash = File.basename(filepath1)
            filepath2 = DataStore1::computeEnergyGridFilepathErrorIfNotAcquisable(nhash)
            FileUtils.mv(filepath1, filepath2)
        }
    end
end
