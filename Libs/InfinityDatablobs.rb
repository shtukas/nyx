
# encoding: UTF-8

class InfinityDatablobs_PureDrive

    # InfinityDatablobs_PureDrive::decideFilepathForBlob(nhash)
    def self.decideFilepathForBlob(nhash)
        "#{Config::pathToInfinityDidact()}/DatablobsDepth2/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
    end

    # InfinityDatablobs_PureDrive::putBlob(blob)
    def self.putBlob(blob)
        InfinityDrive::ensureInfinityDrive()
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = InfinityDatablobs_PureDrive::decideFilepathForBlob(nhash)
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # InfinityDatablobs_PureDrive::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        InfinityDrive::ensureInfinityDrive()

        filepath = InfinityDatablobs_PureDrive::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            return IO.read(filepath)
        end

        blob = Librarian2DatablobsXCache::getBlobOrNull(nhash)
        if blob then
            InfinityDatablobs_PureDrive::putBlob(blob)
            return blob
        end

        nil
    end
end

class InfinityElizabethPureDrive

    def commitBlob(blob)
        InfinityDatablobs_PureDrive::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = InfinityDatablobs_PureDrive::getBlobOrNull(nhash)
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

class InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching

    # InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::commitToDatablobsInfinityBufferOut(blob)
    def self.commitToDatablobsInfinityBufferOut(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = "#{Config::pathToLocalDidact()}/DatablobsInfinityBufferOut/#{nhash[7, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::putBlob(blob)
    def self.putBlob(blob)
        InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::commitToDatablobsInfinityBufferOut(blob)
        Librarian2DatablobsXCache::putBlob(blob)
    end

    # InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)

        # We first try XCache
        blob = Librarian2DatablobsXCache::getBlobOrNull(nhash)
        return blob if blob

        # Then we try the buffer out
        filepath = "#{Config::pathToLocalDidact()}/DatablobsInfinityBufferOut/#{nhash[7, 2]}/#{nhash}.data"
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            Librarian2DatablobsXCache::putBlob(blob)
            return blob
        end

        # Then we look up the drive
        InfinityDrive::ensureInfinityDrive()

        filepath = InfinityDatablobs_PureDrive::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            Librarian2DatablobsXCache::putBlob(blob)
            return blob
        end

        nil
    end
end

class InfinityElizabeth_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching

    def commitBlob(blob)
        InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 7ffc6f95-4977-47a2-b9fd-eecd8312ebbe) could not find blob, nhash: #{nhash}"
        raise "(error: 47f74e9a-0255-44e6-bf04-f12ff7786c65, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 479c057e-d77b-4cd9-a6ba-df082e93f6b5) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
