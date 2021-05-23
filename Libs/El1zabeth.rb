
# encoding: UTF-8

class El1zabeth
    def commitBlob(blob)
        BinaryBlobsService::putBlob(blob)
    end
    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end
    def readBlobErrorIfNotFound(nhash)
        BinaryBlobsService::getBlobOrNull(nhash)
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
