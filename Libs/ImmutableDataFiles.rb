
# encoding: UTF-8

class ImmutableDataFiles

    # ImmutableDataFiles::dxF1FileShouldFlushData(objectuuid)
    def self.dxF1FileShouldFlushData(objectuuid)
        # The limit is 100 Mb, that's the side we are confortable sending over on Syncthing
        dxF1Filepath = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        return false if !File.exist?(dxF1Filepath)
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

    # ImmutableDataFiles::makeNewDataFileUsingDxF1File()
    def self.makeNewDataFileUsingDxF1File()
        # This function get the data contained in a DxF1, make a data file on EnergyGrid, at the next available spot
        # We derive names from the starting objectuuid. And empty the DxF1+vacuum
    end

    # ImmutableDataFiles::getBlobOrNullOrError(objectuuid, nhash)
    def self.getBlobOrNullOrError(objectuuid, nhash)

    end
end
