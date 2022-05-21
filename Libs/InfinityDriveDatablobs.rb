
# encoding: UTF-8

class InfinityDriveDatablobs

    # InfinityDriveDatablobs::decideFilepathForBlob(nhash)
    def self.decideFilepathForBlob(nhash)
        "#{Config::pathToInfinityDidactDataBankType1()}/DatablobsDepth2/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
    end

    # InfinityDriveDatablobs::prepareFilepathForBlob(nhash)
    def self.prepareFilepathForBlob(nhash)
        filepath = "#{Config::pathToInfinityDidactDataBankType1()}/DatablobsDepth2/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        filepath
    end

    # InfinityDriveDatablobs::putBlob(blob)
    def self.putBlob(blob)
        InfinityDriveUtils::ensureInfinityDrive()
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = InfinityDriveDatablobs::prepareFilepathForBlob(nhash)
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # InfinityDriveDatablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        InfinityDriveUtils::ensureInfinityDrive()

        filepath = InfinityDriveDatablobs::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            return IO.read(filepath)
        end

        blob = XCacheExtensionsDatablobs::getBlobOrNull(nhash)
        if blob then
            InfinityDriveDatablobs::putBlob(blob)
            return blob
        end

        nil
    end
end

class InfinityDriveElizabeth

    def commitBlob(blob)
        InfinityDriveDatablobs::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = InfinityDriveDatablobs::getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 69f99c35-5560-44fb-b463-903e9850bc93) could not find blob, nhash: #{nhash}"
        raise "(error: 0573a059-5ca2-431d-a4b4-ab8f4a0a34fe, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 36d664ef-0731-4a00-ba0d-b5a7fb7cf941) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
