# encoding: UTF-8

class NyxBlobs

    # -----------------------------------------------
    # Private

    # NyxBlobs::namedHashToBlobFilepath(namedhash)
    def self.namedHashToBlobFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            cube1 = namedhash[7, 2]
            cube2 = namedhash[9, 2]
            cube3 = namedhash[11, 2]
            filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-Blobs/#{cube1}/#{cube2}/#{cube3}/#{namedhash}.data"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxPrimaryStoreUtils: a9c49293-497f-4371-98a5-6d71a7f1ba80]"
    end

    # -----------------------------------------------
    # Public

    # NyxBlobs::put(blob) # namedhash
    def self.put(blob)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxBlobs::namedHashToBlobFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        namedhash
    end

    # NyxBlobs::getBlobOrNull(namedhash)
    def self.getBlobOrNull(namedhash)
        filepath = NyxBlobs::namedHashToBlobFilepath(namedhash)
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
end
