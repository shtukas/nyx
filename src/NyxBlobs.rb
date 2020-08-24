# encoding: UTF-8

class NyxBlobs

    # -----------------------------------------------
    # Private

    # NyxBlobs::x2BlobFilepath(namedhash)
    def self.x2BlobFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            ns01 = namedhash[7, 2]
            ns02 = namedhash[9, 2]
            ns03 = namedhash[11, 2]
            filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-Blobs-X2/#{ns01}/#{ns02}/#{namedhash}.data"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxBlobs: 96f61a92-6e9d-44b2-93c0-1fe60bd1f0e4]"
    end

    # -----------------------------------------------
    # Public

    # NyxBlobs::put(blob) # namedhash
    def self.put(blob)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxBlobs::x2BlobFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        namedhash
    end

    # NyxBlobs::getBlobOrNull(namedhash)
    def self.getBlobOrNull(namedhash)
        filepath = NyxBlobs::x2BlobFilepath(namedhash)
        if File.exists?(filepath) then
            return IO.read(filepath)
        end
        nil
    end
end
