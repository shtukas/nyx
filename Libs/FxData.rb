# encoding: UTF-8

=begin

data files: create table _data_ (_objectuuid_ text, _nhash_ text, _blob_ blob)

=end

class FxData

    # -------------------------------------------------------------------

    # FxData::localFxDatabaseFilepath()
    def self.localFxDatabaseFilepath()
        "#{Config::pathToLocalDataBankStargate()}/FxData.sqlite3"
    end

    # FxData::ensureFxDataLocalDatabase()
    def self.ensureFxDataLocalDatabase()
        return if File.exists?(FxData::localFxDatabaseFilepath())
        db = SQLite3::Database.new(FxData::localFxDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _data_ (_objectuuid_ text, _nhash_ text, _blob_ blob)"
        db.close
    end

    # -------------------------------------------------------------------

    # FxData::getBlobFromFileOrNull(filepath, objectuuid, nhash)
    def self.getBlobFromFileOrNull(filepath, objectuuid, nhash)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _data_ where _objectuuid_=? and _nhash_=?", [objectuuid, nhash]) do |row|
            blob = row["_blob_"]
        end
        db.close
        if (blob and nhash != "SHA256-#{Digest::SHA256.hexdigest(blob)}") then # better safe than sorry
            puts "(critical: 77418e01-9411-4096-8212-1068745bba08) the extracted blob #{nhash} from file '#{filepath}' using FxData::getBlobFromFileOrNull(filepath, #{objectuuid}, #{nhash}) did not validate."
            return nil
        end
        blob
    end

    # FxData::putBlobIntoFile(filepath, objectuuid, blob)
    def self.putBlobIntoFile(filepath, objectuuid, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _data_ where _objectuuid_=? and _nhash_=?", [objectuuid, nhash]
        db.execute "insert into _data_ (_objectuuid_, _nhash_, _blob_) values (?, ?, ?)", [objectuuid, nhash, blob]
        db.close
        nhash
    end

    # -------------------------------------------------------------------

    # FxData::putBlobOnLocal(objectuuid, blob)
    def self.putBlobOnLocal(objectuuid, blob)
        FxData::ensureFxDataLocalDatabase()
        nhash = FxData::putBlobIntoFile(FxData::localFxDatabaseFilepath(), objectuuid, blob)
        nhash
    end

    # FxData::putBlobOnInfinity(objectuuid, blob)
    def self.putBlobOnInfinity(objectuuid, blob)

        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"

        StargateCentral::ensureInfinityDrive()

        filenames = Fx18Sets::items(objectuuid, "fxdata-filenames")
        filepaths = filenames.map{|filename| "#{StargateCentral::pathToCentral()}/FxData500/#{filename}" }

        if filepaths.any?{|filepath| !FxData::getBlobFromFileOrNull(filepath, objectuuid, nhash).nil? } then
            # The blob is already on Infinity against that objectuuid
            return nhash
        end

        # Let us see whether there is some space left in one of the known files

        filepaths = filepaths.select{|filepath| File.size?(filepath) < 1024*1024*500 } # We Limit to 500 Mb

        if filepaths.size > 0 then
            filepath = filepaths.sample # chosing one randomly
            nhash = FxData::putBlobIntoFile(filepath, objectuuid, blob)
            return nhash
        end

        # We could not find a file or they are all full.
        # Let's try and find another file we could start using

        filepaths = LucilleCore::locationsAtFolder("#{StargateCentral::pathToCentral()}/FxData500")
                        .select{|filepath| filepath[-15, 15] == ".fxdata.sqlite3" }
                        .select{|filepath| File.size?(filepath) < 1024*1024*500 }

        if filepaths.size > 0 then
            filepath = filepaths.sample # chosing one randomly
            # We now need to let the object know that we are going to use this file
            filename = File.basename(filepath)
            Fx18Sets::add2(objectuuid, "fxdata-filenames", filename, filename)
            nhash = FxData::putBlobIntoFile(filepath, objectuuid, blob)
            return nhash
        end

        # We could not find one file for the object
        # or they are all full
        # and we could not find an existing file we could start using
        # Let's issue a new one

        filename = "#{SecureRandom.uuid}.fxdata.sqlite3"

        puts "declaring Infinity data file: #{filename} for objectuuid: #{objectuuid}"

        Fx18Sets::add2(objectuuid, "fxdata-filenames", filename, filename)

        filepath = "#{StargateCentral::pathToCentral()}/FxData500/#{filename}"

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _data_ (_objectuuid_ text, _nhash_ text, _blob_ blob)"
        db.close

        nhash = FxData::putBlobIntoFile(filepath, objectuuid, blob)
        nhash
    end

    # -------------------------------------------------------------------

    # FxData::getBlobOrNull(objectuuid, nhash)
    def self.getBlobOrNull(objectuuid, nhash)

        # ------------------------------------------------------------------------------------------

        First we look at XCache
        blob = XCacheDatablobs::getBlobOrNull(nhash)
        if blob then
            FxData::putBlobOnInfinity(objectuuid, blob)
            return blob
        end

        # Second, we look into the local store
        FxData::ensureFxDataLocalDatabase()
        blob = FxData::getBlobFromFileOrNull(FxData::localFxDatabaseFilepath(), objectuuid, nhash)
        if blob then
            XCacheDatablobs::putBlob(blob)
            return blob
        end

        # If not, then we try the Infinity drive
        StargateCentral::ensureInfinityDrive()

        # We need to extract the names of the database where this object stores its data on Infinity
        filenames = Fx18Sets::items(objectuuid, "fxdata-filenames")

        # Mapping the names into paths
        filepaths = filenames.map{|filename| "#{StargateCentral::pathToCentral()}/FxData500/#{filename}" }

        filepaths.each{|filepath|
            blob = FxData::getBlobFromFileOrNull(filepath, objectuuid, nhash)
            if blob then
                XCacheDatablobs::putBlob(blob)
                return blob
            end
        }

        nil
    end

    # FxData::getBlobOrNullForFsck(objectuuid, nhash)
    def self.getBlobOrNullForFsck(objectuuid, nhash)

        # Second, we look into the local store
        FxData::ensureFxDataLocalDatabase()
        blob = FxData::getBlobFromFileOrNull(FxData::localFxDatabaseFilepath(), objectuuid, nhash)
        if blob then
            return blob
        end

        # Infinity drive
        StargateCentral::ensureInfinityDrive()

        # We need to extract the names of the database where this object stores its data on Infinity
        filenames = Fx18Sets::items(objectuuid, "fxdata-filenames")

        # Mapping the names into paths
        filepaths = filenames.map{|filename| "#{StargateCentral::pathToCentral()}/FxData500/#{filename}" }

        filepaths.each{|filepath|
            blob = FxData::getBlobFromFileOrNull(filepath, objectuuid, nhash)
            if blob then
                return blob
            end
        }

        nil
    end

end

class FxDataElizabeth

    def initialize(objectuuid)
        @objectuuid = objectuuid
    end

    def putBlob(blob)
        FxData::putBlobOnLocal(@objectuuid, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        FxData::getBlobOrNull(@objectuuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "EnergyGridImmutableDataIslandElizabeth: (error: 56ff3216-249e-4fb4-ae2f-5c2cd562c915) could not find blob, nhash: #{nhash}"
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

class FxDataElizabethForFsck

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
        FxData::getBlobOrNullForFsck(@objectuuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "EnergyGridImmutableDataIslandElizabeth: (error: 41d5a038-72c4-45ba-a911-70a206ff22e8) could not find blob, nhash: #{nhash}"
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