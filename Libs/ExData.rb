
class ExData

    # ExData::putBlobInLocalDatablobsFolder(blob)
    def self.putBlobInLocalDatablobsFolder(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filename = "#{nhash}.data"
        filepath = "#{Config::pathToLocalDataBankStargate()}/Datablobs/#{filename}"
        File.open(filepath, "w"){|f| f.write(blob)}
        nhash
    end

    # ExData::putBlobOnEnergyGrid1(blob)
    def self.putBlobOnEnergyGrid1(blob)
        StargateCentral::ensureEnergyGrid1()
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filename = "#{nhash}.data"
        filepath = "#{StargateCentral::pathToCentral()}/DatablobsDepth2/#{nhash[7, 2]}/#{nhash[9, 2]}/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob)}
        nhash
    end

    # ExData::getBlobFromLocalDatablobsFolder(nhash)
    def self.getBlobFromLocalDatablobsFolder(nhash)
        filename = "#{nhash}.data"
        filepath = "#{Config::pathToLocalDataBankStargate()}/Datablobs/#{filename}"
        return nil if !File.exists?(filepath)
        blob = IO.read(filepath)
        if (nhash != "SHA256-#{Digest::SHA256.hexdigest(blob)}") then # better safe than sorry
            raise "(error: da338a8b-f946-4a94-9f93-de9e2bf875f7) the extracted blob #{nhash} from file '#{filepath}' using ExData::getBlobFromLocalDatablobsFolder(#{nhash}) did not validate."
        end
        blob
    end

    # ExData::getBlobFromEnergyGrid1(nhash)
    def self.getBlobFromEnergyGrid1(nhash)
        StargateCentral::ensureEnergyGrid1()
        filename = "#{nhash}.data"
        filepath = "#{StargateCentral::pathToCentral()}/DatablobsDepth2/#{nhash[7, 2]}/#{nhash[9, 2]}/#{filename}"
        return nil if !File.exists?(filepath)
        blob = IO.read(filepath)
        if (nhash != "SHA256-#{Digest::SHA256.hexdigest(blob)}") then # better safe than sorry
            raise "(error: 253a0fad-a9f2-47de-a0f3-1af171ad9827) the extracted blob #{nhash} from file '#{filepath}' using ExData::getBlobFromEnergyGrid1(#{nhash}) did not validate."
        end
        blob
    end

    # ExData::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)

        # First we look at XCache
        blob = XCacheDatablobs::getBlobOrNull(nhash)
        if blob then
            return blob
        end

        # Second we look inside the local datablobs folder
        blob = ExData::getBlobFromLocalDatablobsFolder(nhash)
        if blob then
            XCacheDatablobs::putBlob(blob)
            return blob
        end

        # Third we try the EnergyGrid1 drive
        blob = ExData::getBlobFromEnergyGrid1(nhash)
        if blob then
            XCacheDatablobs::putBlob(blob)
            return blob
        end

        nil
    end

    # ExData::getBlobOrNullForFsck(nhash)
    def self.getBlobOrNullForFsck(nhash)

        # First we look inside the local block
        blob = ExData::getBlobFromLocalDatablobsFolder(nhash)
        if blob then
            XCacheDatablobs::putBlob(blob)
            return blob
        end

        # Second we try the EnergyGrid1 drive
        blob = ExData::getBlobFromEnergyGrid1(nhash)
        if blob then
            return blob
        end

        # Last resort: XCache
        blob = XCacheDatablobs::getBlobOrNull(nhash)
        if blob then
            puts "(warning: 9fa7067a-c774-4c3c-9660-a4d77ed412cd) I have just repaired EnergyGrid1 (for nhash: #{nhash}) using XCache during fsck 🤔"
            ExData::putBlobOnEnergyGrid1(blob)
            return blob
        end

        nil
    end
end

class ExDataElizabeth

    def initialize(objectuuid)
        @objectuuid = objectuuid
    end

    def putBlob(blob)
        ExData::putBlobInLocalDatablobsFolder(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        ExData::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 56ff3216-249e-4fb4-ae2f-5c2cd562c915) could not find blob, nhash: #{nhash}"
        raise "(error: e0ab9a9a-7a5b-4e1d-a2bc-3aa80c456ebb, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: da4e9dd0-bb5a-45bc-8b52-f56c081d0869) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class ExDataElizabethForFsck

    def initialize(objectuuid)
        @objectuuid = objectuuid
    end

    def putBlob(blob)
        raise "(error b7ac0e1f-0a06-41a7-b7e9-9beced2da1e7)"
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        ExData::getBlobOrNullForFsck(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 41d5a038-72c4-45ba-a911-70a206ff22e8) could not find blob, nhash: #{nhash}"
        raise "(error: 2a4fb644-e23a-4718-87c0-8c4209c33339, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 21c1e398-9895-4b63-abda-266428e3ef93) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
