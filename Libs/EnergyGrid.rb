# encoding: UTF-8

class DatablobsXCache

    # DatablobsXCache::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set(nhash, blob)
        nhash
    end

    # DatablobsXCache::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        XCache::getOrNull(nhash)
    end
end

class DatablobsBufferOut

    # DatablobsBufferOut::repositoryFolderpath()
    def self.repositoryFolderpath()
        "#{Config::pathToDataBankStargate()}/DatablobsBufferOut"
    end

    # DatablobsBufferOut::decideFilepathForBlob(nhash)
    def self.decideFilepathForBlob(nhash)
        filepath = "#{DatablobsBufferOut::repositoryFolderpath()}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        filepath
    end

    # DatablobsBufferOut::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = DatablobsBufferOut::decideFilepathForBlob(nhash)
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # DatablobsBufferOut::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath = DatablobsBufferOut::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            return IO.read(filepath)
        end
        nil
    end
end

class StargateCentralDatablobs

    # StargateCentralDatablobs::repositoryFolderpath()
    def self.repositoryFolderpath()
        "#{StargateCentral::pathToCentral()}/DatablobsDepth1"
    end

    # StargateCentralDatablobs::decideFilepathForBlob(nhash)
    def self.decideFilepathForBlob(nhash)
        if !File.exists?(StargateCentralDatablobs::repositoryFolderpath()) then
            puts "Please plug the drive"
            LucilleCore::pressEnterToContinue()
            if !File.exists?(StargateCentralDatablobs::repositoryFolderpath()) then
                puts "Could not find the drive"
                exit
            end
        end
        filepath = "#{StargateCentralDatablobs::repositoryFolderpath()}/#{nhash[7, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        filepath
    end

    # StargateCentralDatablobs::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = StargateCentralDatablobs::decideFilepathForBlob(nhash)
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # StargateCentralDatablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath = StargateCentralDatablobs::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            return IO.read(filepath)
        end
        nil
    end
end

class EnergyGridDatablobs

    # EnergyGridDatablobs::putBlob(blob)
    def self.putBlob(blob)
        DatablobsBufferOut::putBlob(blob)
        DatablobsXCache::putBlob(blob)
    end

    # EnergyGridDatablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)

        blob = DatablobsXCache::getBlobOrNull(nhash)
        return blob if blob

        blob = DatablobsBufferOut::getBlobOrNull(nhash)
        if blob then
            DatablobsXCache::putBlob(blob)
            return blob
        end

        puts "downloading blob from Stargate Central: #{nhash}"
        blob = StargateCentralDatablobs::getBlobOrNull(nhash)
        return blob if blob

        nil
    end
end

class EnergyGridElizabeth

    def commitBlob(blob)
        EnergyGridDatablobs::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        EnergyGridDatablobs::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "EnergyGridElizabeth: (error: a02556b0-1852-4dbb-8048-9a3f5b75c3cd) could not find blob, nhash: #{nhash}"
        raise "(error: 290d45ea-4d54-40f1-9da5-4d6be6e2a8a2, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: b97a25ea-50ad-4d87-8a42-d887be5b37d6) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
