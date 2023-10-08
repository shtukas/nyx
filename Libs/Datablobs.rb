
class Datablobs

    # Datablobs::repository()
    def self.repository()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/nyx/datablobs/2023-10"
    end

    # Datablobs::putBlob(datablob) # nhash
    def self.putBlob(datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        filename = "#{nhash}.blob"
        folder   = "#{Datablobs::repository()}/#{fragment}"
        if !File.exist?(folder) then
            FileUtils.mkpath(folder)
        end
        filepath = "#{folder}/#{filename}"
        File.open(filepath, "w"){|f| f.write(datablob) }
        nhash
    end

    # Datablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        folder   = "#{Datablobs::repository()}/#{fragment}"
        filename = "#{nhash}.blob"
        filepath = "#{folder}/#{filename}"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end
end

class Elizabeth

    def initialize()

    end

    def putBlob(datablob) # nhash
        Datablobs::putBlob(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Datablobs::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: 060e256c-c675-423d-a821-0daf56650fc6, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 09ec5711-c1a7-4e71-b54b-bce7eab66879) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
