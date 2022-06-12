# encoding: UTF-8

class EnergyGridDatablobs

    # EnergyGridDatablobs::datablobsRepositoryPath()
    def self.datablobsRepositoryPath()
        "#{Config::pathToDataBankStargate()}/DatablobsDepth1"
    end

    # EnergyGridDatablobs::decideFilepathForBlob(nhash)
    def self.decideFilepathForBlob(nhash)
        filepath = "#{EnergyGridDatablobs::datablobsRepositoryPath()}/#{nhash[7, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        filepath
    end

    # EnergyGridDatablobs::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = EnergyGridDatablobs::decideFilepathForBlob(nhash)
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # EnergyGridDatablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)

        filepath = EnergyGridDatablobs::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            return IO.read(filepath)
        end

        if !Machines::isLucille20() then
            begin
                blob = DRbObject.new(nil, "druby://192.168.0.3:9876").getBlobOrNull(nhash)
                if blob then
                    puts "> downloading blob from Lucille20: #{nhash}"
                    EnergyGridDatablobs::putBlob(blob)
                end
                return blob
            rescue
            end
        end

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
        puts "(error: a02556b0-1852-4dbb-8048-9a3f5b75c3cd) could not find blob, nhash: #{nhash}"
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
