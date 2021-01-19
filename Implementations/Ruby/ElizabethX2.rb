
# encoding: UTF-8

# -------------------------------------------------------------------------------------

class ElizabethX2

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/AionPointsDatablobs/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/AionPointsDatablobs/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        if !File.exists?(filepath) then
            raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        end
        IO.read(filepath)
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

#AionCore::commitLocationReturnHash(operator, location)
#AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
#AionFsck::structureCheckAionHash(operator, nhash)

# -------------------------------------------------------------------------------------

