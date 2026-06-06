
class Datablobs

    # ------------------------------------------------------------------
    # Config

    # Datablobs::path_to_datablobs()
    def self.path_to_datablobs()
        "#{Config::pathToGalaxy()}/DataHub/First-Light-Weaves-Living-Song/datablobs"
    end

    # ------------------------------------------------------------------
    # Datablob

    # Datablobs::putBlob(datablob)
    def self.putBlob(datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        filename = "#{nhash}.data"
        folder   = "#{Datablobs::path_to_datablobs()}/#{fragment}"
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
        folder   = "#{Datablobs::path_to_datablobs()}/#{fragment}"
        filename = "#{nhash}.data"
        filepath = "#{folder}/#{filename}"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end

end
