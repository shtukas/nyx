# encoding: UTF-8

class NxCubes

    # NxCubes::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/NxCubes"
    end

    # NxCubes::referenceToFilepath(reference)
    def self.referenceToFilepath(reference)
        "#{NxCubes::repositoryFolderPath()}/#{reference}.cube"
    end

    # NxCubes::makeNewEmptyCube(reference)
    def self.makeNewEmptyCube(reference)
        filepath = NxCubes::referenceToFilepath(reference)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _datablobs_ (_nhash_ text, _datablob_ blob)"
        db.close
    end

    # NxCubes::interactivelyMakeCubeOrNull()
    def self.interactivelyMakeCubeOrNull() # cube reference

    end

    # NxCubes::accessCube(reference)
    def self.accessCube(reference)

    end

    # NxCubes::editCube(reference)
    def self.editCube(reference)

    end

    # NxCubes::destroyCube(reference)
    def self.destroyCube(reference)

    end

end

class NxCubeDatablobs

    # NxCubeDatablobs::trueIfFileHasBlob(reference, nhash)
    def self.trueIfFileHasBlob(reference, nhash)
        filepath = NxCubes::referenceToFilepath(reference)
        if !File.exists?(filepath) then
            raise "(error: 470f9b50-09ec-449b-a824-dcbfe1d7ba2e) file doesn't exist for reference: #{reference}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        flag = false
        db.execute("select _nhash_ from _datablobs_ where _nhash_=?", [nhash]) do |row|
            flag = true
        end
        db.close
        flag
    end

    # NxCubeDatablobs::putBlob(reference, blob) # nhash
    def self.putBlob(reference, blob) # nhash
        filepath = NxCubes::referenceToFilepath(reference)
        if !File.exists?(filepath) then
            raise "(error: b25af4e5-2fef-4cc8-8492-d5a76e99ffa5) file doesn't exist for reference: #{reference}"
        end
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        return nhash if NxCubeDatablobs::trueIfFileHasBlob(reference, nhash)
        puts "datablob: #{nhash} (at: #{filepath})".green
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _datablobs_ where _nhash_=?", [nhash] # this is actually not necessary considering the check we did above
        db.execute "insert into _datablobs_ (_nhash_, _datablob_) values (?, ?)", [nhash, blob]
        db.close
        nhash
    end

    # NxCubeDatablobs::getBlobOrNull(reference, nhash)
    def  self.getBlobOrNull(reference, nhash)
        filepath = NxCubes::referenceToFilepath(reference)
        if !File.exists?(filepath) then
            raise "(error: 369ca9fa-ab95-47f4-89ee-6dfb38e5bb5b) file doesn't exist for reference: #{reference}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _datablobs_ where _nhash_=?", [nhash]) do |row|
            blob = row["_datablob_"]
        end
        db.close
        blob
    end
end

class NxCubeElizabeth

    def initialize(reference)
        @reference = reference
    end

    def putBlob(datablob)
        NxCubeDatablobs::putBlob(@reference, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        NxCubeDatablobs::getBlobOrNull(@reference, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 585b8f91-4369-4dd7-a134-f00d9e7f4391) could not find blob, nhash: #{nhash}"
        raise "(error: 987f8b3e-ff09-4b6a-9809-da6732b39be1, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: d97f7216-afeb-40bd-a37c-0d5966e6a0d0) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
