# encoding: UTF-8

class BladeElizabeth

    def initialize(filepath)
        @filepath = filepath
    end

    def putBlob(datablob) # nhash
        BladeCore::putBlob(@filepath, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        BladeCore::getBlobOrNull(@filepath, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: 7890252a-db08-4e84-9ebb-e2d2b7d3c30f, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: a87f7406-fc60-4662-a9f9-5b222f00b3a7) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class BladeCore

    # BladeCore::getBlobOrNull(filepath, nhash)
    def self.getBlobOrNull(filepath, nhash)
        blob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from blade where _key_=?", [nhash]) do |row|
            bx = row["_value_"]
            if "SHA256-#{Digest::SHA256.hexdigest(bx)}" == nhash then
                blob = bx
            end
        end
        db.close
        blob
    end

    # BladeCore::putBlob(filepath, blob)
    def self.putBlob(filepath, blob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into blade (_key_, _value_) values (?, ?)", [nhash, blob]
        db.close
        nhash
    end

    # BladeCore::init()
    def self.init()
        filepath = "/tmp/#{SecureRandom.hex}"
        puts "> create item file: #{filepath}".yellow
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table blade (_key_ text primary key, _value_ blob)", [])
        db.execute "insert into blade (_key_, _value_) values (?, ?)", ["random-#{SecureRandom.hex}", SecureRandom.hex]
        db.close
        filepath
    end

    # BladeCore::filenameToFilepath(filename)
    def self.filenameToFilepath(filename)
        "#{Config::pathToData()}/Blades/#{filename}"
    end

end

class Blades

    # Blades::forge(location) # location -> Bx26
    def self.forge(location)
        # This function takes a location and return the name of the blade
        if !File.exist?(location) then
            raise "(error: 648e67cd-846b-40d2-8930-f58599c50573) location '#{location}' does not exist"
        end
        filepath1 = BladeCore::init()
        operator = BladeElizabeth.new(filepath1)
        nhash = AionCore::commitLocationReturnHash(operator, location)
        # The blade has been forged but is still in /tmp
        filename2 = "blade-#{Digest::SHA1.file(filepath1).hexdigest}"
        filepath2 = BladeCore::filenameToFilepath(filename2) # the filepath we are moving to
        FileUtils.mv(filepath1, filepath2)
        # Bx26
        {
            "filename" => filename2,
            "nhash" => nhash
        }
    end

    # Blades::access(bx26)
    def self.access(bx26)
        filename = bx26["filename"]
        nhash    = bx26["nhash"]
        filepath = BladeCore::filenameToFilepath(filename)
        puts "accessing blade: #{filepath}"
        exportId = SecureRandom.hex(4)
        exportFoldername = "aion-point-#{exportId}"
        exportFolder = "#{Config::userHomeDirectory()}/x-space/xcache-v1-days/#{exportFoldername}"
        FileUtils.mkdir(exportFolder)
        operator = BladeElizabeth.new(filepath)
        AionCore::exportHashAtFolder(operator, nhash, exportFolder)
        system("open '#{exportFolder}'")
        LucilleCore::pressEnterToContinue()
    end
end


