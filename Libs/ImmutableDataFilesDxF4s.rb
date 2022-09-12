
# encoding: UTF-8

class ImmutableDataFilesDxF4s

    # --------------------------------------------
    # Private

    # The first trace is the objectuuid
    # We then return {inputForNextFile: String, filename: String}
    # ImmutableDataFilesDxF4s::dxF4FileCoordinates(input)
    def self.dxF4FileCoordinates(input)
        {
            "inputForNextFile" => Digest::SHA1.hexdigest(input),
            "filename"         => "#{Digest::SHA1.hexdigest(input)}.dxf4.sqlite3"
        }
    end

    # ImmutableDataFilesDxF4s::decideNextPossibleDxF4FileCoordinates(objectuuid)
    def self.decideNextPossibleDxF4FileCoordinates(objectuuid)
        inputForNextFile = objectuuid
        loop {
            dxF4FileCoordinates = ImmutableDataFilesDxF4s::dxF4FileCoordinates(inputForNextFile)
            filename = dxF4FileCoordinates["filename"]
            filepath = ImmutableDataFilesDxF4s::dxF4FilenameToEnergyGridFilepath(filename)
            if !File.exists?(filepath) then
                return dxF4FileCoordinates
            end
            inputForNextFile = dxF4FileCoordinates["inputForNextFile"]
        }
    end

    # ImmutableDataFilesDxF4s::dxF1FileHasDatablobs(filepath)
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

    # ImmutableDataFilesDxF4s::dxF4FilenameToEnergyGridFilepath(filename)
    def self.dxF4FilenameToEnergyGridFilepath(filename)
        fragment = filename[0, 2]
        folderpath = "/Volumes/EnergyGrid1/Data/Pascal/Galaxy/DxF4-Repository/#{fragment}"
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        filepath = "#{folderpath}/#{filename}"
        filepath
    end

    # ImmutableDataFilesDxF4s::getExistingDxF4DataFilenames(objectuuid)
    def self.getExistingDxF4DataFilenames(objectuuid)
        filenames = []
        inputForNextFile = objectuuid
        loop {
            dxF4FileCoordinates = ImmutableDataFilesDxF4s::dxF4FileCoordinates(inputForNextFile)
            filename = dxF4FileCoordinates["filename"]
            filepath = ImmutableDataFilesDxF4s::dxF4FilenameToEnergyGridFilepath(filename)
            break if !File.exists?(filepath)
            filenames << filename
            inputForNextFile = dxF4FileCoordinates["inputForNextFile"]
        }
        filenames
    end

    # --------------------------------------------
    # Public

    # ImmutableDataFilesDxF4s::dxF1FileShouldFlushData(objectuuid)
    def self.dxF1FileShouldFlushData(objectuuid)
        # The limit is 100 Mb, that's the side we are confortable sending over on Syncthing
        dxF1Filepath = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        return false if dxF1Filepath.nil?
        return false if !File.exists?(dxF1Filepath)
        return false if File.size(dxF1Filepath) < 1024*1024*100 # 100Mb
        db = SQLite3::Database.new(dxF1Filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "vacuum", []
        db.close
        return false if File.size(dxF1Filepath) < 1024*1024*100 # 100Mb
        true
    end

    # ImmutableDataFilesDxF4s::transferDataToDxF4OrNothing(objectuuid)
    def self.transferDataToDxF4OrNothing(objectuuid)

        dxF1Filepath = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        if !File.exists?(dxF1Filepath) then
            raise "(error: 28f18c49-04a3-4a05-a48b-283e647fc1fa) Can't see dxF1Filepath: #{dxF1Filepath}, for objectuuid: #{objectuuid}"
        end

        return if ImmutableDataFilesDxF4s::dxF1FileHasDatablobs(dxF1Filepath)

        dxF4FileCoordinates = ImmutableDataFilesDxF4s::decideNextPossibleDxF4FileCoordinates(objectuuid)

        dxF4Filename = dxF4FileCoordinates["filename"]
        dxf4Filepath = ImmutableDataFilesDxF4s::dxF4FilenameToEnergyGridFilepath(dxF4Filename)

        db = SQLite3::Database.new(dxf4Filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _dxf4_ (_nhash_ text, _datablob_ blob)", [])
        db.close

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

            puts "Putting nhash #{nhash} @ #{dxF4Filename}"

            db2.execute "delete from _dxf4_ where _nhash_=?", [nhash]
            db2.execute "insert into _dxf4_ (_nhash_, _datablob_) values (?, ?)", [nhash, datablob]

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
    end

    # ImmutableDataFilesDxF4s::getBlobOrNull(objectuuid, nhash)
    def self.getBlobOrNull(objectuuid, nhash)
        filenames = ImmutableDataFilesDxF4s::getExistingDxF4DataFilenames(objectuuid)
        filenames.each{|dxF4Filename|
            dxf4Filepath = ImmutableDataFilesDxF4s::dxF4FilenameToEnergyGridFilepath(dxF4Filename)
            db = SQLite3::Database.new(dxf4Filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            blob = nil
            db.execute("select * from _dxf4_ where _nhash_=?", [nhash]) do |row|
                blob = row["_datablob_"]
            end
            db.close
            return blob if blob
        }
        nil
    end
end
