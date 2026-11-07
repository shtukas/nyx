
class Datablobs

    # Datablobs::putBlob(datablob) # nhash
    def self.putBlob(datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        filepath = "#{Config::pathToTheLibrarianDatablobsPartial()}/#{nhash}.blob"
        File.open(filepath, "w") {|f| f.write(datablob) }
        nhash
    end

    # Datablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash) # data | nil
        filepath = "#{Config::pathToTheLibrarianDatablobsPartial()}/#{nhash}.blob"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end
end
