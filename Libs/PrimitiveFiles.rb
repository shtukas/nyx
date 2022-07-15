
# encoding: UTF-8

class PrimitiveFiles

    # PrimitiveFiles::computeFilepathForNewPrimitiveFileDataIsland(parts)
    def self.computeFilepathForNewPrimitiveFileDataIsland(parts)
        nhash = Digest::SHA1.hexdigest(parts.join(":"))
        filepath1 = "#{Config::pathToDataBankStargate()}/Data/#{nhash[0, 2]}/#{nhash}.primitive-file-island.sqlite3"
        folderpath1 = File.dirname(filepath1)
        if !File.exists?(folderpath1) then
            FileUtils.mkdir(folderpath1)
        end
        filepath1
    end

    # PrimitiveFiles::locateFilepathForExistingPrimitiveFileDataIsland(parts, shouldDownloadFromCentralIfMissingOnLocal)
    def self.locateFilepathForExistingPrimitiveFileDataIsland(parts, shouldDownloadFromCentralIfMissingOnLocal)
        nhash = Digest::SHA1.hexdigest(parts.join(":"))
        filepath1 = "#{Config::pathToDataBankStargate()}/Data/#{nhash[0, 2]}/#{nhash}.primitive-file-island.sqlite3"
        return filepath1 if File.exists?(filepath1)

        # We could not find the file in xcache, now looking in stargate central
        status = StargateCentral::askForInfinityReturnBoolean()

        if !status then
            puts "Could not access Infinity drive while looking for island #{nhash}.primitive-file-island.sqlite3"
            raise "(error: 334ff0d9-2528-4854-9b13-f495faa3ba3b)"
        end

        filepath2 = "#{StargateCentral::pathToCentral()}/Data/#{nhash[0, 2]}/#{nhash}.primitive-file-island.sqlite3"
        if !File.exists?(filepath2) then
            puts "Could not find island #{nhash}.primitive-file-island.sqlite3 on Stargate Central"
            puts "Tried: #{filepath2}"
            raise "(error: 63c6a99e-ee3b-42cc-b5d1-c03521c494c9)"
        end

        if shouldDownloadFromCentralIfMissingOnLocal then
            puts "copying island #{nhash}.primitive-file-island.sqlite3 from Stargate Central to local Data folder".green
            FileUtils.cp(filepath2, filepath1)
            return filepath1
        else
            return filepath2
        end
    end

    # PrimitiveFiles::nhashcommitFileReturnPartsHashsImproved_v2(objectuuid, filepath)
    def self.nhashcommitFileReturnPartsHashsImproved_v2(objectuuid, filepath)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)

        # The interface of v2 is simpler, we get the filepath and return the hashes. In the meantime 
        # an island (through the Elizabeth) will have been created and populated

        nhash = CommonUtils::filepathToContentHash(filepath)

        filepath1 = "/tmp/#{SecureRandom.uuid}"
        elizabeth = EnergyGridImmutableDataIslandsOperator::getElizabethForFilepath(objectuuid, filepath1)

        parts = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            parts << elizabeth.putBlob(blob)
        end
        f.close()

        # Now that we have the parts, we can compute the filename nd move it to its final location
        filepath2 = PrimitiveFiles::computeFilepathForNewPrimitiveFileDataIsland(parts)
        FileUtils.mv(filepath1, filepath2)

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
