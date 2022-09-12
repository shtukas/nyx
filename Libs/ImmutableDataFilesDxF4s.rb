
# encoding: UTF-8

class ImmutableDataFilesDxF4s

    # The first trace is the objectuuid
    # We then return {inputForNextFile: String, filename: String}
    # ImmutableDataFilesDxF4s::fileCoordinates(input)
    def self.fileCoordinates(input)
        {
            "inputForNextFile" => Digest::SHA1.hexdigest(input),
            "filename"         => "#{Digest::SHA1.hexdigest(input)}.dxf4.sqlite3"
        }
    end

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

    # ImmutableDataFilesDxF4s::makeNewDataFileUsingDxF1File(objectuuid)
    def self.makeNewDataFileUsingDxF1File(objectuuid)
        # This function get the data contained in a DxF1, make a data file on EnergyGrid, at the next available spot
        # We derive names from the starting objectuuid. And empty the DxF1+vacuum

        # (comment group: 9d205ce8-885f-4a80-85aa-64bd081ec5e7)
        # At the moment we work on limited mode, using one file

        dxF1Filepath = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        if !File.exists?(dxF1Filepath) then
            raise "(error: 28f18c49-04a3-4a05-a48b-283e647fc1fa) Can't see dxF1Filepath: #{dxF1Filepath}, for objectuuid: #{objectuuid}"
        end

        # (comment group: 9d205ce8-885f-4a80-85aa-64bd081ec5e7)
        # At the moment we work on limited mode, using one file

        dxf4FileCoordinates = ImmutableDataFilesDxF4s::fileCoordinates(objectuuid)

        dxf4Filename = dxf4FileCoordinates["filename"]
        dxf4Filepath = ImmutableDataFilesDxF4s::filenameToEnergyGridFilepath(dxf4Filename)

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

            puts "Putting nhash #{nhash} @ #{dxf4Filename}"

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

    # ImmutableDataFilesDxF4s::filenameToEnergyGridFilepath(filename)
    def self.filenameToEnergyGridFilepath(filename)
        fragment = filename[0, 2]
        folderpath = "/Volumes/EnergyGrid1/Data/Pascal/Galaxy/DxF4-Repository/#{fragment}"
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        filepath = "#{folderpath}/#{filename}"
        filepath
    end

    # ImmutableDataFilesDxF4s::getExistingDataFilenames(objectuuid)
    def self.getExistingDataFilenames(objectuuid)
        flag1 = File.exists?("/Volumes/EnergyGrid1/Data/Pascal/Galaxy/DxF4-Repository")
        raise "(error: 9e97abd1-57f3-4507-8342-16b0eec153a9) Can't see EnergyGrid" if !flag1
        # (comment group: 9d205ce8-885f-4a80-85aa-64bd081ec5e7)
        # At the moment we work on limited mode, using one file

        dxf4FileCoordinates = ImmutableDataFilesDxF4s::fileCoordinates(objectuuid)
        filename = dxf4FileCoordinates["filename"]
        filepath = ImmutableDataFilesDxF4s::filenameToEnergyGridFilepath(filename)
        if File.exists?(filepath) then
            [filename]
        else
            []
        end
    end

    # ImmutableDataFilesDxF4s::getBlobOrNull(objectuuid, nhash)
    def self.getBlobOrNull(objectuuid, nhash)
        dxf4FileCoordinates = ImmutableDataFilesDxF4s::fileCoordinates(objectuuid)
        dxf4Filename = dxf4FileCoordinates["filename"]
        dxf4Filepath = ImmutableDataFilesDxF4s::filenameToEnergyGridFilepath(dxf4Filename)
        db = SQLite3::Database.new(dxf4Filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _dxf4_ where _nhash_=?", [nhash]) do |row|
            blob = row["_datablob_"]
        end
        db.close
        blob
    end
end
