
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
end
