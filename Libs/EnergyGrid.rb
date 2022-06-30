# encoding: UTF-8

class StargateUtils

    # StargateUtils::propagateDatablobs(folderpath1, folderpath2)
    def self.propagateDatablobs(folderpath1, folderpath2)
        Find.find(folderpath1) do |path|
            next if File.basename(path)[-5, 5] != ".data"
            filename = File.basename(path)
            targetfolderpath = "#{folderpath2}/#{filename[7, 2]}"
            targetfilepath = "#{targetfolderpath}/#{filename}"
            next if File.exist?(targetfilepath)
            if !File.exists?(targetfolderpath) then
                FileUtils.mkdir(targetfolderpath)
            end
            puts "copying datablob: #{filename}"
            DatablobsStargateCentralSQLBLobStores::putBlob(blob)
        end
    end

    # StargateUtils::propagateDatablobsWithPrimaryDeletion(folderpath1, folderpath2)
    def self.propagateDatablobsWithPrimaryDeletion(folderpath1, folderpath2)
        Find.find(folderpath1) do |path|
            next if File.basename(path)[-5, 5] != ".data"
            filename = File.basename(path)
            targetfolderpath = "#{folderpath2}/#{filename[7, 2]}"
            targetfilepath = "#{targetfolderpath}/#{filename}"
            if File.exist?(targetfilepath) then
                FileUtils.rm(path)
                next
            end
            if !File.exists?(targetfolderpath) then
                FileUtils.mkdir(targetfolderpath)
            end
            puts "copying datablob: #{filename}"
            FileUtils.cp(path, targetfilepath)
            FileUtils.rm(path)
        end
    end

    # StargateUtils::transferDatablobsLocalBufferOutToDatablobsStargateCentralSQLBLobStores()
    def self.transferDatablobsLocalBufferOutToDatablobsStargateCentralSQLBLobStores()
        Find.find(DatablobsLocalBufferOut::repositoryFolderpath()) do |path|
            next if File.basename(path)[-5, 5] != ".data"
            puts "copying datablob: #{File.basename(path)}"
            blob = IO.read(path)
            DatablobsStargateCentralSQLBLobStores::putBlob(blob)
            FileUtils.rm(path)
        end
    end
end

class DatablobsXCache

    # DatablobsXCache::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set(nhash, blob)
        nhash
    end

    # DatablobsXCache::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        XCache::getOrNull(nhash)
    end
end

class DatablobsLocalBufferOut

    # DatablobsLocalBufferOut::repositoryFolderpath()
    def self.repositoryFolderpath()
        "#{Config::pathToDataBankStargate()}/DatablobsBufferOut"
    end

    # DatablobsLocalBufferOut::decideFilepathForBlob(nhash)
    def self.decideFilepathForBlob(nhash)
        filepath = "#{DatablobsLocalBufferOut::repositoryFolderpath()}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        filepath
    end

    # DatablobsLocalBufferOut::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = DatablobsLocalBufferOut::decideFilepathForBlob(nhash)
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # DatablobsLocalBufferOut::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath = DatablobsLocalBufferOut::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            return IO.read(filepath)
        end
        nil
    end
end

class DatablobsStargateCentralClassic

    # DatablobsStargateCentralClassic::repositoryFolderpath()
    def self.repositoryFolderpath()
        "#{StargateCentral::pathToCentral()}/DatablobsDepth1"
    end

    # DatablobsStargateCentralClassic::decideFilepathForBlob(nhash)
    def self.decideFilepathForBlob(nhash)
        if !File.exists?(DatablobsStargateCentralClassic::repositoryFolderpath()) then
            puts "Please plug the drive"
            LucilleCore::pressEnterToContinue()
            if !File.exists?(DatablobsStargateCentralClassic::repositoryFolderpath()) then
                puts "Could not find the drive"
                exit
            end
        end
        filepath = "#{DatablobsStargateCentralClassic::repositoryFolderpath()}/#{nhash[7, 2]}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        filepath
    end

    # DatablobsStargateCentralClassic::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = DatablobsStargateCentralClassic::decideFilepathForBlob(nhash)
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # DatablobsStargateCentralClassic::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath = DatablobsStargateCentralClassic::decideFilepathForBlob(nhash)
        if File.exists?(filepath) then
            return IO.read(filepath)
        end
        nil
    end
end

class DatablobsStargateCentralSQLBLobStores

    # DatablobsStargateCentralSQLBLobStores::computeFilepath(nhash, indx)
    def self.computeFilepath(nhash, indx)
        raise "(error: c381f53b-6312-46d4-8621-2a2e6538364b)" if indx < 1
        "#{StargateCentral::pathToCentral()}/BlobStores/#{nhash[7, indx]}.sqlite3"
    end

    # DatablobsStargateCentralSQLBLobStores::decideFilepathForPut(nhash)
    def self.decideFilepathForPut(nhash)
        indx = 0
        loop {
            indx = indx + 1

            filepath = DatablobsStargateCentralSQLBLobStores::computeFilepath(nhash, indx)

            if !File.exists?(filepath) then
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute "create table _data_ (_key_ text, _blob_ blob);"
                db.close
            end

            gigabyte = 1024*1024*1024
            if File.size(filepath) < gigabyte then
                return filepath
            end
        }
    end

    # -----------------------------------------------------

    # DatablobsStargateCentralSQLBLobStores::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        indx = 0
        loop {
            indx = indx + 1

            filepath = DatablobsStargateCentralSQLBLobStores::computeFilepath(nhash, indx)

            if !File.exists?(filepath) then
                return nil
            end

            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            blob = nil
            db.execute("select * from _data_ where _key_=?", [nhash]) do |row|
                blob = row["_blob_"]
            end
            db.close
            blob

            if blob then
                return blob
            end
        }
    end

    # DatablobsStargateCentralSQLBLobStores::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        return nhash if !DatablobsStargateCentralSQLBLobStores::getBlobOrNull(nhash).nil?
        filepath = DatablobsStargateCentralSQLBLobStores::decideFilepathForPut(nhash)
        db = SQLite3::Database.new(filepath)
        db.execute "delete from _data_ where _key_=?", [nhash]
        db.execute "insert into _data_ (_key_, _blob_) values (?, ?)", [nhash, blob]
        db.close
        nhash
    end
end

# -----------------------------------------------------------

class EnergyGridClassicDatablobs

    # EnergyGridClassicDatablobs::putBlob(blob)
    def self.putBlob(blob)
        DatablobsLocalBufferOut::putBlob(blob)
        DatablobsXCache::putBlob(blob)
    end

    # EnergyGridClassicDatablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)

        blob = DatablobsXCache::getBlobOrNull(nhash)
        return blob if blob

        blob = DatablobsLocalBufferOut::getBlobOrNull(nhash)
        if blob then
            DatablobsXCache::putBlob(blob)
            return blob
        end

        #puts "downloading blob from Stargate Central: #{nhash}"
        #blob = DatablobsStargateCentralClassic::getBlobOrNull(nhash)
        #if blob then
        #    DatablobsXCache::putBlob(blob)
        #    return blob
        #end

        if !File.exists?(StargateCentral::pathToCentral()) then
            puts "I need the Infinity drive"
            LucilleCore:: pressEnterToContinue()
        end

        if !File.exists?(StargateCentral::pathToCentral()) then
            puts "I needed the Infinity drive. Exiting"
            exit
        end

        puts "downloading blob from Stargate Central: #{nhash}"
        blob = DatablobsStargateCentralSQLBLobStores::getBlobOrNull(nhash)
        if blob then
            DatablobsXCache::putBlob(blob)
            return blob
        end

        nil
    end
end

class EnergyGridUniqueBlobs

    # EnergyGridUniqueBlobs::decideFilepathForUniqueBlob(nhash)
    def self.decideFilepathForUniqueBlob(nhash)
        filepath1 = "/Users/pascal/Galaxy/DataBank/Stargate/Data/#{nhash[7, 2]}/#{nhash}.data"
        folderpath1 = File.dirname(filepath1)
        if !File.exists?(folderpath1) then
            FileUtils.mkdir(folderpath1)
        end
        filepath1
    end

    # EnergyGridUniqueBlobs::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath1 = EnergyGridUniqueBlobs::decideFilepathForUniqueBlob(nhash)
        File.open(filepath1, "w"){|f| f.write(blob) }
        nhash
    end

    # EnergyGridUniqueBlobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath1 = EnergyGridUniqueBlobs::decideFilepathForUniqueBlob(nhash)
        if File.exists?(filepath1) then
            return IO.read(filepath1)
        end
        #blob = EnergyGridClassicDatablobs::getBlobOrNull(nhash)
        #if blob then
        #    puts "EnergyGridUniqueBlobs: found blob in classical sense, nhash: #{nhash}".green
        #    EnergyGridUniqueBlobs::putBlob(blob)
        #end
        blob
    end
end

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

        #if blob.nil? then
        #    blob = EnergyGridClassicDatablobs::getBlobOrNull(nhash)
        #    if blob then
        #        puts "EnergyGridImmutableDataIsland: found blob in classical sense, nhash: #{nhash}".green
        #        putBlob(blob)
        #    end
        #end

        blob
    end
end

class EnergyGridImmutableDataIslandElizabeth

    def initialize(databaseFilepath)
        @databaseFilepath = databaseFilepath
        @island = EnergyGridImmutableDataIsland.new(databaseFilepath)
    end

    def putBlob(blob)
        @island.putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        @island.getBlobOrNull(nhash)
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

    def relocateToFilepath(filepath)
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        FileUtils.mv(@databaseFilepath, filepath)
    end

    def relocateToNhash(nhash)
        filepath1 = EnergyGridImmutableDataIslandsOperator::decideFilepathForIslandOrNull(nhash)
        relocateToFilepath(filepath1)
        puts "island #{nhash} relocated to #{filepath1}"
    end
end

class EnergyGridImmutableDataIslandsOperator

    # EnergyGridImmutableDataIslandsOperator::decideFilepathForIslandOrNull(nhash)
    def self.decideFilepathForIslandOrNull(nhash)
        filepath1 = "/Users/pascal/Galaxy/DataBank/Stargate/Data/#{nhash[7, 2]}/#{nhash}.data-island.sqlite3"
        folderpath1 = File.dirname(filepath1)
        if !File.exists?(folderpath1) then
            FileUtils.mkdir(folderpath1)
        end
        filepath1
    end

    # EnergyGridImmutableDataIslandsOperator::getIslandForNhash(nhash)
    def self.getIslandForNhash(nhash)
        filepath1 = EnergyGridImmutableDataIslandsOperator::decideFilepathForIslandOrNull(nhash)
        EnergyGridImmutableDataIsland.new(filepath1)
    end

    # EnergyGridImmutableDataIslandsOperator::getElizabethForTemporaryIsland()
    def self.getElizabethForTemporaryIsland()
        EnergyGridImmutableDataIslandElizabeth.new("/tmp/#{SecureRandom.uuid}")
    end

    # EnergyGridImmutableDataIslandsOperator::getElizabethForIslandForNhash(nhash)
    def self.getElizabethForIslandForNhash(nhash)
        filepath1 = EnergyGridImmutableDataIslandsOperator::decideFilepathForIslandOrNull(nhash)
        EnergyGridImmutableDataIslandElizabeth.new(filepath1)
    end
end
