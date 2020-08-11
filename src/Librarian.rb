
# encoding: UTF-8

=begin
    LibrarianElizabeth is the class that explain to 
    Aion how to compute hashes and where to store and 
    retrive the blobs to and from.
=end

class LibrarianElizabeth

    def initialize()
    end

    def commitBlob(blob)
        NyxBlobs::put(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = NyxBlobs::getBlobOrNull(nhash)
        raise "[LibrarianElizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

class LibrarianOperator

    # LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
    def self.commitLocationDataAndReturnNamedHash(location)
        AionCore::commitLocationReturnHash(LibrarianElizabeth.new(), location)
    end

    # LibrarianOperator::namedHashExportAtFolder(namedHash, folderpath)
    def self.namedHashExportAtFolder(namedHash, folderpath)
        AionCore::exportHashAtFolder(LibrarianElizabeth.new(), namedHash, folderpath)
    end

    # LibrarianOperator::getFSVirtualSizeOfANamedHashInBytesUseTheForce(namedHash)
    def self.getFSVirtualSizeOfANamedHashInBytesUseTheForce(namedHash)
        aionpoint = JSON.parse(NyxBlobs::getBlobOrNull(namedHash))
        if aionpoint["aionType"] == "file" then
            return aionpoint["size"]
        end
        if aionpoint["aionType"] == "directory" then
            return aionpoint["items"].map{|nh| LibrarianOperator::getFSVirtualSizeOfANamedHashInBytesUseTheForce(nh) }.inject(0, :+)
        end
        return 0
    end

    # LibrarianOperator::getFSVirtualSizeOfANamedHashInBytes(namedHash)
    def self.getFSVirtualSizeOfANamedHashInBytes(namedHash)
        cacheKey = "16d2c004-cac1-4d38-9c8c-b1cbd1d664c2:#{namedHash}"
        value = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return value.to_i if value
        value = LibrarianOperator::getFSVirtualSizeOfANamedHashInBytesUseTheForce(namedHash)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, value)
        value
    end

    # LibrarianOperator::getNumberOfFilesOfANamedHashUseTheForce(namedHash)
    def self.getNumberOfFilesOfANamedHashUseTheForce(namedHash)
        aionpoint = JSON.parse(NyxBlobs::getBlobOrNull(namedHash))
        if aionpoint["aionType"] == "file" then
            return 1
        end
        if aionpoint["aionType"] == "directory" then
            return aionpoint["items"].map{|nh| LibrarianOperator::getNumberOfFilesOfANamedHashUseTheForce(nh) }.inject(0, :+)
        end
        return 0
    end

    # LibrarianOperator::getNumberOfFilesOfANamedHash(namedHash)
    def self.getNumberOfFilesOfANamedHash(namedHash)
        cacheKey = "f93af855-8b72-486a-bbf8-11cf21ebb08d:#{namedHash}"
        value = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return value.to_i if value
        value = LibrarianOperator::getNumberOfFilesOfANamedHashUseTheForce(namedHash)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, value)
        value
    end
end
