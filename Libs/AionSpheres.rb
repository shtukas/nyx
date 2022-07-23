# encoding: UTF-8

class AionSpheres

    # AionSpheres::objectRepositoryFolderpath(objectuuid)
    def self.objectRepositoryFolderpath(objectuuid)
        path = "#{StargateCentral::pathToCentral()}/Aion-Spheres/#{objectuuid}"
        if !File.exists?(path) then
            FileUtils.mkdir(path)
        end
        path
    end

    # AionSpheres::objectDatabaseFilepaths(objectuuid)
    def self.objectDatabaseFilepaths(objectuuid)
        LucilleCore::locationsAtFolder(AionSpheres::objectRepositoryFolderpath(objectuuid))
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
            .sort
    end

    # AionSpheres::objectDatabaseFilepathsLessThan100Mb(objectuuid)
    def self.objectDatabaseFilepathsLessThan100Mb(objectuuid)
        AionSpheres::objectDatabaseFilepaths(objectuuid).select{|filepath|
            File.size(filepath) < 1024*1024*100
        }
    end

    # AionSpheres::getBlobFromFileOrNull(filepath, nhash)
    def self.getBlobFromFileOrNull(filepath, nhash)
       db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _data_ where _nhash_=?", [nhash]) do |row|
            blob = row["_blob_"]
        end
        blob
    end

    # AionSpheres::getBlobOrNull(objectuuid, nhash)
    def self.getBlobOrNull(objectuuid, nhash)
        AionSpheres::objectDatabaseFilepaths(objectuuid).each{|filepath|
            blob = AionSpheres::getBlobFromFileOrNull(filepath, nhash)
            return blob if blob
        }
        nil
    end

    # AionSpheres::putBlob(objectuuid, blob)
    def self.putBlob(objectuuid, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"

        # Let's check whether we have the blob already
        blob2 = AionSpheres::getBlobOrNull(objectuuid, nhash)
        if blob2 then
            nhash2 = "SHA256-#{Digest::SHA256.hexdigest(blob2)}"
            if nhash == nhash2 then
                # We already have a blob and the one we have is fine
                return nhash
            end
            puts "(error: 9e320b00-57f1-4269-89ee-d90ceeabb234)"
            puts "If this ever happens then we need more code. We need to track down the incorrect blob and remove it"
            exit
        end

        # We need to commit it
        databaseFilepaths = AionSpheres::objectDatabaseFilepathsLessThan100Mb(objectuuid)
        filepath = nil

        if databaseFilepaths.empty? then
            filepath = "#{AionSpheres::objectRepositoryFolderpath(objectuuid)}/#{LucilleCore::timeStringL22()}.sqlite3"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "create table _data_ (_nhash_ text primary key, _blob_ blob)"
            db.close
        else
            filepath = databaseFilepaths.last
        end

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # Here we do not perform how usual deletion of a possible existing record because by design there should not already be one
        db.execute "insert into _data_ (_nhash_, _blob_) values (?, ?)", [nhash, blob]
        db.close

        nhash
    end
end

class AionSphereElizabeth

    def initialize(objectuuid)
        StargateCentral::ensureInfinityDrive()
        @objectuuid = objectuuid
    end

    def putBlob(blob)
        AionSpheres::putBlob(@objectuuid, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        AionSpheres::getBlobOrNull(@objectuuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "EnergyGridImmutableDataIslandElizabeth: (error: a576427a-422d-48d0-9417-1a6408d09ba5) could not find blob, nhash: #{nhash}"
        raise "(error: 7bb5c627-d029-4a21-a333-f823255d2343, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 51eb1858-b30e-4d54-aa5d-6176d02ffb95) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end