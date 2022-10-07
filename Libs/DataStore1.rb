class DataStore1

    # -------------------------------------------------------
    # Locations

    # DataStore1::localRepository()
    def self.localRepository()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/datastore1"
    end

    # DataStore1::energyGridRepository()
    def self.energyGridRepository()
        "/Volumes/EnergyGrid1/Stargate/DataStore1"
    end

    # -------------------------------------------------------
    # Filepaths

    # @deprecated
    # DataStore1::getXCacheFilepath(nhash)
    def self.getXCacheFilepath(nhash)
        XCache::filepath(nhash)
    end

    # DataStore1::getEnergyGridFilepathForFilename(nhash)
    def self.getEnergyGridFilepathForFilename(nhash)
        month = "2022-09"
        fragment = nhash[7, 2]
        folderpath = "#{DataStore1::energyGridRepository()}/#{month}/#{fragment}"
        "#{folderpath}/#{nhash}"
    end

    # DataStore1::getEnergyGridFilepathErrorIfNotAcquisable(nhash)
    def self.getEnergyGridFilepathErrorIfNotAcquisable(nhash)
        if !File.exists?(DataStore1::energyGridRepository()) then
            raise "(error: c1244503-8ab9-4f51-aa7b-fc19ddad87f8) nhash: #{nhash}"
        end
        filepath = DataStore1::getEnergyGridFilepathForFilename(nhash)
        folderpath = File.dirname(filepath)
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath
    end

    # DataStore1::getLocalRepositoryFilepath(nhash)
    def self.getLocalRepositoryFilepath(nhash)
        month = "2022-09"
        folderpath = "#{DataStore1::localRepository()}/#{month}/#{nhash[7, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}"
    end

    # DataStore1::getFilepathsForWritingNoCommLine(nhash) # Array[filepath]
    def self.getFilepathsForWritingNoCommLine(nhash)
        [
            DataStore1::getLocalRepositoryFilepath(nhash)
        ]
    end

    # DataStore1::getFilepathsForWriting(nhash) # Array[filepath]
    def self.getFilepathsForWriting(nhash)
        filepaths1 = [
            DataStore1::getLocalRepositoryFilepath(nhash)
        ]
        filepaths2 = Machines::theOtherInstanceIds()
                        .map{|targetInstanceId|
                            "#{CommsLine::pathToStaging()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.file-datastore1"
                        }

        filepaths1 + filepaths2
    end

    # DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(nhash, optimiseUsingCacheWrites) # filepath
    def self.getNearestFilepathForReadingErrorIfNotAcquisable(nhash, optimiseUsingCacheWrites)
        filepath = DataStore1::getLocalRepositoryFilepath(nhash)
        if File.exists?(filepath) then
            return filepath
        end

        # We are moving away from XCache, but we still have data there
        filepath = DataStore1::getXCacheFilepath(nhash)
        if File.exists?(filepath) then
            FileUtils.cp(filepath, DataStore1::getLocalRepositoryFilepath(nhash))
            return filepath
        end

        EnergyGrid::acquireEnergyGridOrExit()

        filepath = DataStore1::getEnergyGridFilepathErrorIfNotAcquisable(nhash)
        if File.exists?(filepath) then
            if optimiseUsingCacheWrites then
                FileUtils.cp(filepath, DataStore1::getLocalRepositoryFilepath(nhash))
            end
            return filepath
        end

        raise "(error: 22825ba0-7b86-452d-be25-af73ac31ab61) nhash: #{nhash}"
    end

    # -------------------------------------------------------
    # Public

    # DataStore1::putDataByContent(content) # nhash
    def self.putDataByContent(content)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(content)}"
        DataStore1::getFilepathsForWriting(nhash).each{|filepath|
            next if File.exists?(filepath)
            File.open(filepath, "w"){|f| f.write(content) }
        }
        nhash
    end

    # DataStore1::putDataByFilepathNoCommLine(sourcefilepath) # nhash
    def self.putDataByFilepathNoCommLine(sourcefilepath)
        nhash = "SHA256-#{Digest::SHA256.file(sourcefilepath).hexdigest}"
        DataStore1::getFilepathsForWritingNoCommLine(nhash).each{|filepath|
            next if File.exists?(filepath)
            FileUtils.cp(sourcefilepath, filepath)
        }
        nhash
    end

    # DataStore1::putDataByFilepath(sourcefilepath) # nhash
    def self.putDataByFilepath(sourcefilepath)
        nhash = "SHA256-#{Digest::SHA256.file(sourcefilepath).hexdigest}"
        DataStore1::getFilepathsForWriting(nhash).each{|filepath|
            next if File.exists?(filepath)
            FileUtils.cp(sourcefilepath, filepath)
        }
        nhash
    end

    # -------------------------------------------------------
    # Operations

    # DataStore1::localDataToEnergyGrid()
    def self.localDataToEnergyGrid()
        Find.find(DataStore1::localRepository()) do |path|
            next if !File.basename(path).start_with?("SHA256-")
            filepath1 = path
            nhash = File.basename(filepath1)
            filepath2 = DataStore1::getEnergyGridFilepathErrorIfNotAcquisable(nhash)
            if File.exists?(filepath2) then
                next
            end
            FileUtils.cp(filepath1, filepath2)
        end
    end
end
