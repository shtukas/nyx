# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

# ------------------------------------------------------------------------

class NyxBlobs

    # NyxBlobs::namedHashToBlobFilepath(namedhash)
    def self.namedHashToBlobFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            fragment1 = namedhash[7, 2]
            fragment2 = namedhash[9, 2]
            fragment3 = namedhash[11, 2]
            filepath = "#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Blobs/#{fragment1}/#{fragment2}/#{fragment3}/#{namedhash}.data"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxPrimaryStoreUtils: a9c49293-497f-4371-98a5-6d71a7f1ba80]"
    end

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
