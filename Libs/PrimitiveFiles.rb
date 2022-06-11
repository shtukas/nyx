
# encoding: UTF-8

class PrimitiveFiles

    # -------------------------------------------------
    # Read

    # PrimitiveFiles::commitFileReturnPartsHashsImproved(filepath, operator)
    def self.commitFileReturnPartsHashsImproved(filepath, operator)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)
        hashes = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            hashes << operator.commitBlob(blob)
        end
        f.close()
        hashes
    end

    # PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(filepath) # [dottedExtension, nhash, parts]
    def self.locationToPrimitiveFileDataArrayOrNull(filepath)
        return nil if !File.exists?(filepath)
        return nil if !File.file?(filepath)
        dottedExtension = File.extname(filepath)
        nhash = CommonUtils::filepathToContentHash(filepath)
        parts = PrimitiveFiles::commitFileReturnPartsHashsImproved(filepath, EnergyGridElizabeth.new())
        return [dottedExtension, nhash, parts]
    end

    # -------------------------------------------------
    # Write

    # PrimitiveFiles::writePrimitiveFile2(parentLocation, basefilename, dottedExtension, parts) # filepat
    def self.writePrimitiveFile2(parentLocation, basefilename, dottedExtension, parts)
        filepath = "#{parentLocation}/#{basefilename}.#{dottedExtension}"
        File.open(filepath, "w"){|f|  
            parts.each{|nhash|
                blob = EnergyGridElizabeth.new().getBlobOrNull(nhash)
                raise "(error: 416666c5-3d7a-491b-a08f-1994c5adfc86)" if blob.nil?
                f.write(blob)
            }
        }
        filepath
    end
end
