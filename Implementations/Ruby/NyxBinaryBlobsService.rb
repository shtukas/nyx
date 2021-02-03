
# encoding: UTF-8

class NyxBinaryBlobsService

    # NyxBinaryBlobsService::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Nyx/NyxDatablobsDepth2"
    end

    # NyxBinaryBlobsService::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # NyxBinaryBlobsService::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{NyxBinaryBlobsService::repositoryFolderPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # NyxBinaryBlobsService::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        folderpath = "#{NyxBinaryBlobsService::repositoryFolderPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
end
