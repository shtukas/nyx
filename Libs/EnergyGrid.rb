
# encoding: UTF-8

class EnergyGridDatablobs

    # EnergyGridDatablobs::putBlob(blob)
    def self.putBlob(blob)
        XCacheDatablobs::putBlob(blob)
    end

    # EnergyGridDatablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)

        # We first try XCache
        blob = XCacheDatablobs::getBlobOrNull(nhash)
        return blob if blob

        # Then we look up the drive
        InfinityDriveUtils::ensureInfinityDrive()

        filepath = InfinityDriveDatablobs::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            XCacheDatablobs::putBlob(blob)
            return blob
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

    def readBlobErrorIfNotFound(nhash)
        blob = EnergyGridDatablobs::getBlobOrNull(nhash)
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
