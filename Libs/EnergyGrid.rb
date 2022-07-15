# encoding: UTF-8

# -----------------------------------------------------------

class EnergyGridImmutableDataIsland

    def initialize(databaseFilepath)
        @databaseFilepath = databaseFilepath
        if !File.exists?(databaseFilepath) then
            db = SQLite3::Database.new(databaseFilepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "create table _data_ (_key_ text, _blob_ blob);"
            db.close
        end
    end

    def putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        db = SQLite3::Database.new(@databaseFilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _data_ where _key_=?", [nhash]
        db.execute "insert into _data_ (_key_, _blob_) values (?, ?)", [nhash, blob]
        db.close
        nhash
    end

    def getBlobOrNull(nhash)
        db = SQLite3::Database.new(@databaseFilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _data_ where _key_=?", [nhash]) do |row|
            blob = row["_blob_"]
        end
        db.close
        return blob if blob

        StargateCentral::askForInfinityAndFailIfNot()

        stargateFilepath = @databaseFilepath.gsub("#{Config::pathToDataBankStargate()}/Data", "#{StargateCentral::pathToCentral()}/Data")

        return if !File.exists?(stargateFilepath)

        puts "accessing #{stargateFilepath}".green

        db = SQLite3::Database.new(stargateFilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _data_ where _key_=?", [nhash]) do |row|
            blob = row["_blob_"]
        end
        db.close
        return blob if blob

        nil
    end
end

class EnergyGridImmutableDataIslandElizabeth

    def initialize(objectuuid, databaseFilepath)
        @objectuuid = objectuuid
        @databaseFilepath = databaseFilepath
        @island = EnergyGridImmutableDataIsland.new(databaseFilepath)
    end

    def putBlob(blob)
        Fx18s::putBlob3(@objectuuid, blob, false)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        blob = Fx18s::getBlobOrNull(@objectuuid, nhash, false)
        return blob if blob

        puts "EnergyGridImmutableDataIslandElizabeth: looking into the island for #{nhash}".green
        blob = @island.getBlobOrNull(nhash)

        if blob then
            Fx18s::putBlob3(@objectuuid, blob, false)
            return blob
        end

        nil
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "EnergyGridImmutableDataIslandElizabeth: (error: 321676dc-03c7-4af7-b82b-ef957734e132) could not find blob, nhash: #{nhash}"
        raise "(error: 60f1fd88-d45b-4aef-96ef-2412e2a3a5d6, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 001b182a-121f-480e-8c26-6b25dd04d03f) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end

    def recastToNhash(nhash)
        filepath1 = @databaseFilepath # Where we are.
        filepath2 = EnergyGridImmutableDataIslandsOperator::forNewIslandConstructLocalDataIslandFilepathForNhash(nhash) # Where we are going

        if !File.exists?(File.dirname(filepath2)) then
            FileUtils.mkdir(File.dirname(filepath2))
        end

        # If we are moving to a file that already exists, we remove it
        if File.exists?(filepath2) then
            puts "We are moving"
            puts "    source: #{filepath1}"
            puts "    target: #{filepath2}"
            puts "(info: fbfdbf1c-b85d-4d4e-a120-5f6c6c59e342)"
            puts "    We already have that target. This is surprising 🤔"
            puts "    I am going to remove target and move source, but I thought you might want to know"
            LucilleCore::pressEnterToContinue()
            FileUtils.rm(filepath2)
        end

        puts "data island relocating from #{filepath1} to #{filepath2}".green
        FileUtils.cp(filepath1, filepath2)
    end
end

class EnergyGridImmutableDataIslandsOperator

    # EnergyGridImmutableDataIslandsOperator::forNewIslandConstructLocalDataIslandFilepathForNhash(nhash)
    def self.forNewIslandConstructLocalDataIslandFilepathForNhash(nhash)
        filepath1 = "#{Config::pathToDataBankStargate()}/Data/#{nhash[7, 2]}/#{nhash}.data-island.sqlite3"
        folderpath1 = File.dirname(filepath1)
        if !File.exists?(folderpath1) then
            FileUtils.mkdir(folderpath1)
        end
        filepath1
    end

    # EnergyGridImmutableDataIslandsOperator::forExistingIslandLocateIslandFilepathForNhashOrError(nhash, shouldDownloadFromCentralIfMissingOnLocal)
    def self.forExistingIslandLocateIslandFilepathForNhashOrError(nhash, shouldDownloadFromCentralIfMissingOnLocal)
        filepath1 = "#{Config::pathToDataBankStargate()}/Data/#{nhash[7, 2]}/#{nhash}.data-island.sqlite3"
        return filepath1 if File.exists?(filepath1)

        # We could not find the file in xcache, now looking in stargate central
        status = StargateCentral::askForInfinityReturnBoolean()

        if !status then
            puts "Could not access Infinity drive while looking for island #{nhash}.data-island.sqlite3"
            raise "(error: f52e43e4-b157-412d-b39e-78ece2ffe48d)"
        end

        filepath2 = "#{StargateCentral::pathToCentral()}/Data/#{nhash[7, 2]}/#{nhash}.data-island.sqlite3"
        if !File.exists?(filepath2) then
            puts "Could not find island #{nhash}.data-island.sqlite3 on Stargate Central"
            raise "(error: 82f87c4e-75de-4de4-80ee-952a2d7d2aef)"
        end

        if shouldDownloadFromCentralIfMissingOnLocal then
            puts "copying island #{nhash}.data-island.sqlite3 from Stargate Central to local Data folder".green
            FileUtils.cp(filepath2, filepath1)
            return filepath1
        else
            return filepath2
        end
    end

    # EnergyGridImmutableDataIslandsOperator::getElizabethWithTemporaryIsland(objectuuid)
    def self.getElizabethWithTemporaryIsland(objectuuid)
        EnergyGridImmutableDataIslandElizabeth.new(objectuuid, "/tmp/#{SecureRandom.uuid}")
    end

    # EnergyGridImmutableDataIslandsOperator::getElizabethForExistingIslandForNhashOrNull(objectuuid, nhash, shouldDownloadFromCentralIfMissingOnLocal)
    def self.getElizabethForExistingIslandForNhashOrNull(objectuuid, nhash, shouldDownloadFromCentralIfMissingOnLocal)
        filepath = EnergyGridImmutableDataIslandsOperator::forExistingIslandLocateIslandFilepathForNhashOrError(nhash, shouldDownloadFromCentralIfMissingOnLocal)
        return nil if !File.exists?(filepath)
        EnergyGridImmutableDataIslandElizabeth.new(objectuuid, filepath)
    end

    # EnergyGridImmutableDataIslandsOperator::getElizabethForFilepath(objectuuid, filepath)
    def self.getElizabethForFilepath(objectuuid, filepath)
        EnergyGridImmutableDataIslandElizabeth.new(objectuuid, filepath)
    end

    # EnergyGridImmutableDataIslandsOperator::getExistingIslandElizabethForPrimitiveFilePartsOrNull(objectuuid, parts, shouldDownloadFromCentralIfMissingOnLocal)
    def self.getExistingIslandElizabethForPrimitiveFilePartsOrNull(objectuuid, parts, shouldDownloadFromCentralIfMissingOnLocal)
        filepath = PrimitiveFiles::locateFilepathForExistingPrimitiveFileDataIsland(parts, shouldDownloadFromCentralIfMissingOnLocal)
        return nil if !File.exists?(filepath)
        EnergyGridImmutableDataIslandsOperator::getElizabethForFilepath(objectuuid, filepath)
    end
end
