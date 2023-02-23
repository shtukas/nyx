
# create table elements (uuid string primary key, mikuType string, nhash string)

class N1DataIO

    # --------------------------------------
    # Utils

    # N1DataIO::n1dataFolderpath()
    def self.n1dataFolderpath()
        "#{Config::pathToDataCenter()}/N1Data"
    end

    # N1DataIO::getIndicesExistingFilepaths()
    def self.getIndicesExistingFilepaths()
        LucilleCore::locationsAtFolder("#{N1DataIO::n1dataFolderpath()}/objects-indices")
            .select{|filepath| filepath[-7, 7] == ".sqlite" }
    end

    # N1DataIO::renameIndexFile(filepath)
    def self.renameIndexFile(filepath)
        filepath2 = "#{N1DataIO::n1dataFolderpath()}/objects-indices/SHA256-#{Digest::SHA256.file(filepath).hexdigest}.sqlite"
        return if filepath == filepath2
        return if File.exist?(filepath2)
        FileUtils.mv(filepath, filepath2)
    end

    # N1DataIO::indexFileCardinal(filepath)
    def self.indexFileCardinal(filepath)
        count = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _count_ from elements", []) do |row|
            count = row["_count_"]
        end
        db.close
        count
    end

    # N1DataIO::deleteUUIDAtIndexFilepath(filepath, uuid)
    def self.deleteUUIDAtIndexFilepath(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from elements where uuid=?", [uuid]
        db.close
        if N1DataIO::indexFileCardinal(filepath) > 0 then
            N1DataIO::renameIndexFile(filepath)
        else
            FileUtils.rm(filepath)
        end
    end

    # N1DataIO::destroyUUIDInIndexFiles(filepaths, uuid)
    def self.destroyUUIDInIndexFiles(filepaths, uuid)
        filepaths.each{|filepath|
            N1DataIO::deleteUUIDAtIndexFilepath(filepath, uuid)
        }
    end

    # N1DataIO::updateIndex(uuid, mikuType, nhash)
    def self.updateIndex(uuid, mikuType, nhash)
        filepaths = N1DataIO::getIndicesExistingFilepaths()

        filepath = "#{N1DataIO::n1dataFolderpath()}/objects-indices/#{CommonUtils::timeStringL22()}.sqlite"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table elements (uuid string primary key, mikuType string, nhash string)", [])
        db.execute "insert into elements (uuid, mikuType, nhash) values (?, ?, ?)", [uuid, mikuType, nhash]
        db.close

        N1DataIO::renameIndexFile(filepath)

        N1DataIO::destroyUUIDInIndexFiles(filepaths, uuid)
    end



    # --------------------------------------
    # Interface

    # N1DataIO::putBlob(datablob)
    def self.putBlob(datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        filename = "#{nhash}.data"
        folderpath = "#{N1DataIO::n1dataFolderpath()}/datablobs/#{nhash[7, 2]}"
        if !File.exist?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.write(datablob) }

        # -------------------------------------
        nhash_check = "SHA256-#{Digest::SHA256.hexdigest(N1DataIO::getBlobOrNull(nhash))}"
        if nhash_check != nhash then
            raise "(error: 43070006-dcaf-48b7-ac43-025ed2351336) something incredibly wrong just happened"
        end
        # -------------------------------------

        nhash
    end

    # N1DataIO::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filename = "#{nhash}.data"
        folderpath = "#{N1DataIO::n1dataFolderpath()}/datablobs/#{nhash[7, 2]}"
        filepath = "#{folderpath}/#{filename}"
        return nil if !File.exist?(filepath)
        blob = IO.read(filepath)

        # -------------------------------------
        nhash_check = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        if nhash_check != nhash then
            raise "(error: 38cb55a1-c7d4-49cd-9e22-3d0673e51bf2) something incredibly wrong just happened"
        end
        # -------------------------------------

        blob
    end

    # N1DataIO::commitObject(object)
    def self.commitObject(object)
        if object["uuid"].nil? then
            raise "object is missing uuid: #{JSON.pretty_generate(object)}"
        end
        if object["mikuType"].nil? then
            raise "object is missing mikuType: #{JSON.pretty_generate(object)}"
        end
        datablob = JSON.generate(object)
        nhash = N1DataIO::putBlob(datablob)
        N1DataIO::updateIndex(object["uuid"], object["mikuType"], nhash)
    end

    # N1DataIO::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        object = nil
        N1DataIO::getIndicesExistingFilepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from elements where uuid=?", [uuid]) do |row|
                nhash = row["nhash"]
                datablob = N1DataIO::getBlobOrNull(nhash)
                object = JSON.parse(datablob)
            end
            db.close
            break if object
        }
        object
    end

    # N1DataIO::getMikuType(mikuType)
    def self.getMikuType(mikuType)
        objects = []
        N1DataIO::getIndicesExistingFilepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from elements where mikuType=?", [mikuType]) do |row|
                nhash = row["nhash"]
                datablob = N1DataIO::getBlobOrNull(nhash)
                objects << JSON.parse(datablob)
            end
            db.close
        }
        objects
    end

    # N1DataIO::destroy(uuid)
    def self.destroy(uuid)
        filepaths = N1DataIO::getIndicesExistingFilepaths()
        N1DataIO::destroyUUIDInIndexFiles(filepaths, uuid)
    end
end

class DatablobStoreElizabeth

    def initialize()
    end

    def putBlob(datablob)
        N1DataIO::putBlob(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        N1DataIO::getBlobOrNull(nhash)
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