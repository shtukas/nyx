
# encoding: UTF-8

class Datablobs

    # Datablobs::repositoryPath()
    def self.repositoryPath()
        "#{Config::pathToData()}/Datablobs"
    end

    # Datablobs::putBlob(blob) # nhash
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{Datablobs::repositoryPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exist?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # Datablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash) # data | nil
        folderpath = "#{Datablobs::repositoryPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end
end
