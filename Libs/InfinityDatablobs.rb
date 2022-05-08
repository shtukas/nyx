
# encoding: UTF-8

=begin

IxD01 represents the state of a Bucket

{
    "index"     : Integer
    "filenames" : Array[Nhash]
    "isOldest"  : Boolean
}

=end

class InfinityDatablobsConfig

    # InfinityDatablobsConfig::sequenceFolderpath()
    def self.sequenceFolderpath()
        "#{Config::pathToInfinityDidact()}/DatablobsVx20220501/Sequence"
    end

    # InfinityDatablobsConfig::maxBucketSize()
    def self.maxBucketSize()
        1000
    end

    # InfinityDatablobsConfig::accelerationIxD01PrimaryCacheKey()
    def self.accelerationIxD01PrimaryCacheKey()
        "0739d998-b931-4d40-a79f-c360eb65035e:#{Utils::today()}"
    end
end

$InfinityDatablobsAcceleration1 = {}
$InfinityDatablobsAccelerationSequenceOfIntegers = nil

class InfinityDatablobsAcceleration

    # This class privides in memory structures to speed up blobs finding and management

    # InfinityDatablobsAcceleration::orderedSequenceOfIntegersFromDisk()
    def self.orderedSequenceOfIntegersFromDisk()
        LucilleCore::locationsAtFolder(InfinityDatablobsConfig::sequenceFolderpath())
            .map{|location| File.basename(location).to_i }
            .sort
    end

    # InfinityDatablobsAcceleration::getOrderedSequenceOfIntegers()
    def self.getOrderedSequenceOfIntegers()
        if $InfinityDatablobsAccelerationSequenceOfIntegers then
            return $InfinityDatablobsAccelerationSequenceOfIntegers
        end
        $InfinityDatablobsAccelerationSequenceOfIntegers = InfinityDatablobsAcceleration::orderedSequenceOfIntegersFromDisk()
        $InfinityDatablobsAccelerationSequenceOfIntegers
    end

    # InfinityDatablobsAcceleration::computeIxD01FromInfinityDrive(idx)
    def self.computeIxD01FromInfinityDrive(idx)
        # We need to compute it and store it.
        puts "Computing IxD01 from drive (index: #{idx})"
        filenames = LucilleCore::locationsAtFolder("#{InfinityDatablobsConfig::sequenceFolderpath()}/#{idx}")
            .map{|location|
                File.basename(location)
            }
        sequenceOfIntegers = InfinityDatablobsAcceleration::getOrderedSequenceOfIntegers()
        isOldest = sequenceOfIntegers.first == idx
        item = {
            "index"     => idx,
            "filenames" => filenames,
            "isOldest"  => isOldest
        }
        puts JSON.pretty_generate(item)
        item
    end

    # InfinityDatablobsAcceleration::getIxD01(idx)
    def self.getIxD01(idx)

        if $InfinityDatablobsAcceleration1[idx.to_s] then
            return $InfinityDatablobsAcceleration1[idx.to_s]
        end

        item = XCache::getOrNull("#{InfinityDatablobsConfig::accelerationIxD01PrimaryCacheKey()}:#{idx}")
        if item then
            item = JSON.parse(item)
            $InfinityDatablobsAcceleration1[idx.to_s] = item
            return item
        end

        item = InfinityDatablobsAcceleration::computeIxD01FromInfinityDrive(idx)
        XCache::set("#{InfinityDatablobsConfig::accelerationIxD01PrimaryCacheKey()}:#{idx}", JSON.generate(item))
        $InfinityDatablobsAcceleration1[idx.to_s] = item
        item
    end

    # InfinityDatablobsAcceleration::destroyIxD01OnMemoryAndOnDisk(idx)
    def self.destroyIxD01OnMemoryAndOnDisk(idx)
        XCache::destroy("#{InfinityDatablobsConfig::accelerationIxD01PrimaryCacheKey()}:#{idx}")
        $InfinityDatablobsAcceleration1[idx.to_s] = nil
    end

    # InfinityDatablobsAcceleration::addFilenameAtIndex(idx, filename)
    def self.addFilenameAtIndex(idx, filename)
        item = InfinityDatablobsAcceleration::getIxD01(idx)
        item["filenames"] << filename
        $InfinityDatablobsAcceleration1[idx.to_s] = item
        XCache::set("#{InfinityDatablobsConfig::accelerationIxD01PrimaryCacheKey()}:#{idx}", JSON.generate(item))
    end

    # InfinityDatablobsAcceleration::getBucketSize(idx)
    def self.getBucketSize(idx)
        InfinityDatablobsAcceleration::getIxD01(idx)["filenames"].size
    end

    # InfinityDatablobsAcceleration::updateStructuresAfterNewBucketCreation()
    def self.updateStructuresAfterNewBucketCreation()
        $InfinityDatablobsAccelerationSequenceOfIntegers = InfinityDatablobsAcceleration::orderedSequenceOfIntegersFromDisk()
        $InfinityDatablobsAccelerationSequenceOfIntegers.each{|idx|
            InfinityDatablobsAcceleration::getIxD01(idx) # The side effect of this is that $InfinityDatablobsAcceleration1 XCache are going to be updated with the new IxD01 corresponding to the newly created bucket
        }
    end

    # InfinityDatablobsAcceleration::getExistingIndexForBlobOrNull(nhash)
    def self.getExistingIndexForBlobOrNull(nhash)
        InfinityDatablobsAcceleration::getOrderedSequenceOfIntegers()
            .each{|idx|
                item = InfinityDatablobsAcceleration::getIxD01(idx)
                if item["filenames"].include?("#{nhash}.data") then
                    return idx
                end
            }
        nil
    end

    # InfinityDatablobsAcceleration::indexIsFirst?(idx)
    def self.indexIsFirst?(idx)
        InfinityDatablobsAcceleration::getOrderedSequenceOfIntegers().first == idx
    end

    # InfinityDatablobsAcceleration::getLastIndex()
    def self.getLastIndex()
        InfinityDatablobsAcceleration::getOrderedSequenceOfIntegers().last
    end

end

class InfinityDatablobsUtils

    # ------------------------------------------------------------
    # Pure Functions

    # InfinityDatablobsUtils::computeBucketPathForIndex(idx)
    def self.computeBucketPathForIndex(idx)
        "#{InfinityDatablobsConfig::sequenceFolderpath()}/#{idx}"
    end

    # InfinityDatablobsUtils::computeFilepathForBucketAndNhash(bucketPath, nhash)
    def self.computeFilepathForBucketAndNhash(bucketPath, nhash)
        "#{bucketPath}/#{nhash}.data"
    end

    # ------------------------------------------------------------
    # Accelerated Functions without Disk IO

    # InfinityInMemory::blobIsInBucket_useAcceleration(bucketPath, nhash)
    def self.blobIsInBucket_useAcceleration(bucketPath, nhash)
        item = InfinityDatablobsAcceleration::getIxD01(idx)
        item["filenames"].include?("#{nhash}.data")
    end

    # InfinityDatablobsUtils::getOrderedSequenceOfBucketPaths()
    def self.getOrderedSequenceOfBucketPaths()
        InfinityDatablobsAcceleration::getOrderedSequenceOfIntegers().map{|idx| InfinityDatablobsUtils::computeBucketPathForIndex(idx) }
    end

    # ------------------------------------------------------------
    # IO

    # InfinityDatablobsUtils::createNewBucket()
    def self.createNewBucket()
        idx = InfinityDatablobsAcceleration::getOrderedSequenceOfIntegers().last + 1
        folderpath = InfinityDatablobsUtils::computeBucketPathForIndex(idx)
        if File.exists?(folderpath) then
            raise "(error: 892d5ea2-aa28-44de-83de-28c7cdc011f5) idx: #{idx}, folderpath: #{folderpath}"
        end
        FileUtils.mkdir(folderpath)
        [idx, folderpath]
    end

    # ------------------------------------------------------------------

    # InfinityDatablobsUtils::decideFilepathForBlob(nhash)
    def self.decideFilepathForBlob(nhash)
        idx = InfinityDatablobsAcceleration::getExistingIndexForBlobOrNull(nhash)

        if idx.nil? then
            idx = InfinityDatablobsAcceleration::getLastIndex()
            if InfinityDatablobsAcceleration::getBucketSize(idx) >= InfinityDatablobsConfig::maxBucketSize() then
                idx, filename = InfinityDatablobsUtils::createNewBucket()
            end
            return InfinityDatablobsUtils::computeFilepathForBucketAndNhash(InfinityDatablobsUtils::computeBucketPathForIndex(idx), nhash)
        end

        if InfinityDatablobsAcceleration::indexIsFirst?(idx) then
            idx = InfinityDatablobsAcceleration::getLastIndex()
            if InfinityDatablobsAcceleration::getBucketSize(idx) >= InfinityDatablobsConfig::maxBucketSize() then
                idx, filename = InfinityDatablobsUtils::createNewBucket()
            end
            return InfinityDatablobsUtils::computeFilepathForBucketAndNhash(InfinityDatablobsUtils::computeBucketPathForIndex(idx), nhash)
        end

        InfinityDatablobsUtils::computeFilepathForBucketAndNhash(InfinityDatablobsUtils::computeBucketPathForIndex(idx), nhash)
    end
end

class InfinityDatablobs_PureDrive

    # InfinityDatablobs_PureDrive::putBlob(blob)
    def self.putBlob(blob)
        InfinityDrive::ensureInfinityDrive()
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = InfinityDatablobsUtils::decideFilepathForBlob(nhash)
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }

        idx = File.basename(File.dirname(filepath)).to_i
        filename = File.basename(filepath)
        InfinityDatablobsAcceleration::addFilenameAtIndex(idx, filename)
        nhash
    end

    # InfinityDatablobs_PureDrive::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        InfinityDrive::ensureInfinityDrive()

        filepath = InfinityDatablobsUtils::decideFilepathForBlob(nhash)
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

class InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching

    # InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::commitToDatablobsInfinityBufferOut(blob)
    def self.commitToDatablobsInfinityBufferOut(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = "#{Config::pathToLocalDidact()}/DatablobsInfinityBufferOut/#{nhash[7, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::putBlob(blob)
    def self.putBlob(blob)
        InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::commitToDatablobsInfinityBufferOut(blob)
        Librarian2DatablobsXCache::putBlob(blob)
    end

    # InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
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

        filepath = InfinityDatablobsUtils::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            Librarian2DatablobsXCache::putBlob(blob)
            return blob
        end

        nil
    end
end

class InfinityElizabeth_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching

    def commitBlob(blob)
        InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
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
