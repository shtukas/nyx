
# encoding: UTF-8

class PrimitiveFiles

    # PrimitiveFiles::decideFilepathForPrimitiveFileDataIsland(parts)
    def self.decideFilepathForPrimitiveFileDataIsland(parts)
        nhash = Digest::SHA1.hexdigest(parts.join(":"))
        filepath1 = "/Users/pascal/Galaxy/DataBank/Stargate/Data/#{nhash[0, 2]}/#{nhash}.primitive-file-island.sqlite3"
        folderpath1 = File.dirname(filepath1)
        if !File.exists?(folderpath1) then
            FileUtils.mkdir(folderpath1)
        end
        filepath1
    end

    # PrimitiveFiles::nhashcommitFileReturnPartsHashsImproved_v1(filepath, operator)
    def self.nhashcommitFileReturnPartsHashsImproved_v1(filepath, operator)
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

    # PrimitiveFiles::nhashcommitFileReturnPartsHashsImproved_v2(filepath)
    def self.nhashcommitFileReturnPartsHashsImproved_v2(filepath)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)

        # The interface of v2 is simpler, we get the filepath and return the hashes. In the meantime 
        # an island will have been created and populated.

        nhash = CommonUtils::filepathToContentHash(filepath)

        filepath1 = "/tmp/#{SecureRandom.uuid}"
        island = EnergyGridImmutableDataIsland.new(filepath1)

        parts = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            parts << island.putBlob(blob)
        end
        f.close()

        # Now that we have the parts, we can compute the filename nd move it to its final location
        filepath2 = PrimitiveFiles::decideFilepathForPrimitiveFileDataIsland(parts)
        FileUtils.mv(filepath1, filepath2)

        [nhash, parts]
    end

    # PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(filepath) # [dottedExtension, nhash, parts]
    def self.locationToPrimitiveFileDataArrayOrNull(filepath)
        return nil if !File.exists?(filepath)
        return nil if !File.file?(filepath)
        dottedExtension = File.extname(filepath)
        nhash, hashes = PrimitiveFiles::nhashcommitFileReturnPartsHashsImproved_v2(filepath)
        [dottedExtension, nhash, parts]
    end
end
