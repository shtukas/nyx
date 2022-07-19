
# encoding: UTF-8

class PrimitiveFiles

    # PrimitiveFiles::nhashcommitFileReturnPartsHashsImproved_v2(objectuuid, filepath)
    def self.nhashcommitFileReturnPartsHashsImproved_v2(objectuuid, filepath)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)

        # The interface of v2 is simpler, we get the filepath and return the hashes. In the meantime 
        # an island (through the Elizabeth) will have been created and populated

        nhash = CommonUtils::filepathToContentHash(filepath)

        elizabeth = Fx18ElizabethStandard.new(objectuuid)

        parts = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            parts << elizabeth.putBlob(blob)
        end
        f.close()

        [nhash, parts]
    end

    # PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(objectuuid, filepath) # [dottedExtension, nhash, parts]
    def self.locationToPrimitiveFileDataArrayOrNull(objectuuid, filepath)
        return nil if !File.exists?(filepath)
        return nil if !File.file?(filepath)
        dottedExtension = File.extname(filepath)
        nhash, parts = PrimitiveFiles::nhashcommitFileReturnPartsHashsImproved_v2(objectuuid, filepath)
        [dottedExtension, nhash, parts]
    end

    # PrimitiveFiles::locationToPrimitiveFileNx111OrNull(objectuuid, location) # Nx111
    def self.locationToPrimitiveFileNx111OrNull(objectuuid, location)
        data = PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(objectuuid, location)
        return nil if data.nil?
        dottedExtension, nhash, parts = data
        {
            "uuid"            => SecureRandom.uuid,
            "type"            => "file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts
        }
    end
end
