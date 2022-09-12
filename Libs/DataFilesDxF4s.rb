
# encoding: UTF-8

class DataFilesDxF4s

    # --------------------------------------------
    # Private

    # DataFilesDxF4s::dxF4Repository()
    def self.dxF4Repository()
        "/Volumes/EnergyGrid1/Data/Pascal/Galaxy/DxF4-Repository"
    end

    # DataFilesDxF4s::acquireRepositoryOrExit()
    def self.acquireRepositoryOrExit()
        return if File.exists?(DataFilesDxF4s::dxF4Repository())
        puts "We need Energy Grid"
        LucilleCore::pressEnterToContinue()
        return if File.exists?(DataFilesDxF4s::dxF4Repository())
        exit
    end

    # DataFilesDxF4s::dxF1FileHasDatablobs(filepath)
    def self.dxF1FileHasDatablobs(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select count(*) as _count_ from _dxf1_ where _eventType_=?", ["datablob"]) do |row|
            answer = (row["_count_"] > 0)
        end
        db.close
        answer
    end

    # DataFilesDxF4s::getDxF4EnergyGridFilepathOrNull(objectuuid)
    def self.getDxF4EnergyGridFilepathOrNull(objectuuid)
        DataFilesDxF4s::acquireRepositoryOrExit()
        filename = "#{Digest::SHA1.hexdigest(objectuuid)}.dxf4.sqlite3"
        fragment = filename[0, 2]
        folderpath = "#{DataFilesDxF4s::dxF4Repository()}/#{fragment}"
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        filepath = "#{folderpath}/#{filename}"
        filepath
    end

    # --------------------------------------------
    # Public

    # DataFilesDxF4s::repositoryIsVisible()
    def self.repositoryIsVisible()
        File.exists?(DataFilesDxF4s::dxF4Repository())
    end

    # DataFilesDxF4s::dxF1FileShouldFlushData(objectuuid)
    def self.dxF1FileShouldFlushData(objectuuid)
        # The limit is 100 Mb, that's the side we are confortable sending over on Syncthing
        dxF1Filepath = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        return false if dxF1Filepath.nil?
        return false if !File.exists?(dxF1Filepath)
        DataFilesDxF4s::dxF1FileHasDatablobs(dxF1Filepath)
    end

    # DataFilesDxF4s::transferDataToDxF4OrNothing(objectuuid) # Boolean: Indicates if a transfer has happened
    def self.transferDataToDxF4OrNothing(objectuuid)

        dxF1Filepath = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        if !File.exists?(dxF1Filepath) then
            raise "(error: 28f18c49-04a3-4a05-a48b-283e647fc1fa) Can't see dxF1Filepath: #{dxF1Filepath}, for objectuuid: #{objectuuid}"
        end

        return false if !DataFilesDxF4s::dxF1FileHasDatablobs(dxF1Filepath)

        DataFilesDxF4s::acquireRepositoryOrExit()

        dxf4Filepath = DataFilesDxF4s::getDxF4EnergyGridFilepathOrNull(objectuuid)

        if !File.exists?(dxf4Filepath) then
            db = SQLite3::Database.new(dxf4Filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("create table _dxf4_ (_nhash_ text, _datablob_ blob)", [])
            db.close
        end

        db1 = SQLite3::Database.new(dxF1Filepath)
        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true

        db2 = SQLite3::Database.new(dxf4Filepath)
        db2.busy_timeout = 117
        db2.busy_handler { |count| true }
        db2.results_as_hash = true

        db1.execute("select * from _dxf1_ where _eventType_=?", ["datablob"]) do |row|

            objectuuid = row["_objectuuid_"]
            eventuuid  = row["_eventuuid_"]
            eventTime  = row["_eventTime_"]
            eventType  = row["_eventType_"]
            attname    = row["_name_"]
            attvalue   = row["_value_"]

            nhash      = attname
            datablob   = attvalue

            puts "Putting nhash #{nhash} @ #{File.basename(dxf4Filepath)}"

            db2.execute "delete from _dxf4_ where _nhash_=?", [nhash]
            db2.execute "insert into _dxf4_ (_nhash_, _datablob_) values (?, ?)", [nhash, datablob]

            XCacheDatablobs::putBlob(datablob) # To be read later after when the DxF4 is no longer visible

        end
        db2.close
        db1.close

        db = SQLite3::Database.new(dxF1Filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _dxf1_ where _eventType_=?", ["datablob"]
        db.execute "vacuum", []
        db.close

        true
    end

    # DataFilesDxF4s::getBlobOrNull(objectuuid, nhash, useCache)
    def self.getBlobOrNull(objectuuid, nhash, useCache)
        if useCache then
            blob = XCacheDatablobs::getBlobOrNull(nhash)
            return blob if blob
        end

        DataFilesDxF4s::acquireRepositoryOrExit()

        dxf4Filepath = DataFilesDxF4s::getDxF4EnergyGridFilepathOrNull(objectuuid)
        return nil if !File.exists?(dxf4Filepath)

        db = SQLite3::Database.new(dxf4Filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _dxf4_ where _nhash_=?", [nhash]) do |row|
            blob = row["_datablob_"]
        end
        db.close
        if blob then
            if useCache then
                XCacheDatablobs::putBlob(blob)
            end
            return blob
        end

        nil
    end
end
