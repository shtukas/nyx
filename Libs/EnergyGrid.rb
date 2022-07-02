# encoding: UTF-8

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

# -----------------------------------------------------------

class EnergyGridUniqueBlobs

    # EnergyGridUniqueBlobs::decideFilepathForUniqueBlob(nhash)
    def self.decideFilepathForUniqueBlob(nhash)
        filepath1 = "#{Config::pathToDataBankStargate()}/Data/#{nhash[7, 2]}/#{nhash}.data"
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

        #blob = DatablobsXCache::getBlobOrNull(nhash)
        #if blob then
        #    puts "EnergyGridUniqueBlobs: Got from xcache: #{nhash}".green
        #    EnergyGridUniqueBlobs::putBlob(blob)
        #    return blob
        #end

        nil
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
        return blob if blob

        StargateCentral::askForInfinityAndFailIfNot()

        stargateFilepath = @databaseFilepath.gsub("#{Config::pathToDataBankStargate()}/Data", "#{StargateCentral::pathToCentral()}/Data")
        
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

        #blob = DatablobsXCache::getBlobOrNull(nhash)
        #if blob then
        #    puts "EnergyGridImmutableDataIsland: Got from xcache: #{nhash}".green
        #    putBlob(blob)
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
        filepath1 = "#{Config::pathToDataBankStargate()}/Data/#{nhash[7, 2]}/#{nhash}.data-island.sqlite3"
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
