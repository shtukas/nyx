# encoding: UTF-8

class Blades

    # Blades::blade_filepaths_enumeration()
    def self.blade_filepaths_enumeration()
        roots = [
            "#{Config::userHomeDirectory()}/Galaxy",
            "#{Config::userHomeDirectory()}/Desktop"
        ]
        Enumerator.new do |filepaths|
            roots.each{|root|
                Find.find(root) do |path|
                    if File.basename(path)[-10, 10] == ".nyx-blade" then
                        filepaths << path
                    end
                end
            }
        end
    end

    # Blades::uuidToBladeFilepathOrNull_UseTheForce(uuid) -> filepath or nil
    def self.uuidToBladeFilepathOrNull_UseTheForce(uuid)
        Blades::blade_filepaths_enumeration().each{|filepath|
            item = Blades::readItemFromBladeFile(filepath)
            if item["uuid"] == uuid then
                return filepath
            end
        }
        nil
    end

    # Blades::uuidToBladeFilepathOrNull(uuid) -> filepath or nil
    def self.uuidToBladeFilepathOrNull(uuid)
        # Takes a uuid and return the filepath to the blade if it could find it

        filepath = XCache::getOrNull("#{uuid}:8a8b4b72-a715-4cbf-a524-8f47a81fdbba")
        if filepath then
            if File.exist?(filepath) then
                item = Blades::readItemFromBladeFile(filepath)
                if item["uuid"] == uuid then
                    return filepath
                end
            end
        end

        filepath = Blades::uuidToBladeFilepathOrNull_UseTheForce(uuid)
        if filepath then
            XCache::set("#{uuid}:8a8b4b72-a715-4cbf-a524-8f47a81fdbba", filepath)
        end

        filepath
    end

    # Blades::makeNewFileForInProgressNodeCreation(uuid)
    def self.makeNewFileForInProgressNodeCreation(uuid)

        directory = "#{Config::userHomeDirectory()}/Galaxy/Timeline/#{Time.new.to_s[0, 4]}/Nyx-Blades/"
        if !File.exist?(directory) then
            FileUtils.mkpath(directory)
        end

        filename = "#{SecureRandom.hex(6)}.nyx-blade"
        filepath = "#{directory}/#{filename}"

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table blade (_key_ TEXT primary key, _data_ BLOB);", [])
        db.commit
        db.close

        item = {
            "uuid" => uuid
        }

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from blade where _key_=?", ["item"])
        db.execute("insert into blade (_key_, _data_) values (?, ?)", ["item", JSON.generate(item)])
        db.commit
        db.close

        XCache::set("#{uuid}:8a8b4b72-a715-4cbf-a524-8f47a81fdbba", filepath)

        filepath
    end

    # Blades::readItemFromBladeFile(filepath)
    def self.readItemFromBladeFile(filepath)
        item = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from blade where _key_=?", ["item"]) do |row|
            item = JSON.parse(row["_data_"])
        end
        db.close
        if item.nil? then
            raise "This is an extremelly odd condition. This blade file doesn't have an item, filepath: #{filepath}"
        end
        item
    end

    # Blades::getItemOrNull(uuid) -> item or nil
    def self.getItemOrNull(uuid)
        filepath = Blades::uuidToBladeFilepathOrNull(uuid)
        return nil if filepath.nil?
        Blades::readItemFromBladeFile(filepath)
    end

    # Blades::destroy(uuid) -> item or nil
    def self.destroy(uuid)
        filepath = Blades::uuidToBladeFilepathOrNull(uuid)
        if filepath then
            FileUtils.rm(filepath)
        end
        HardProblem::nodeHasBeenDestroyed(uuid)
    end

    # Blades::items()
    def self.items()
        Blades::blade_filepaths_enumeration().map{|filepath| Blades::readItemFromBladeFile(filepath) }
    end

    # Blades::commitItemToItsBladeFile(item)
    def self.commitItemToItsBladeFile(item)
        filepath = Blades::uuidToBladeFilepathOrNull(item["uuid"])
        if filepath.nil? then
            raise "(error: 192ba5e3) I could not find a blade file for item: #{item}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from blade where _key_=?", ["item"])
        db.execute("insert into blade (_key_, _data_) values (?, ?)", ["item", JSON.generate(item)])
        db.commit
        db.close
    end

    # Blades::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Blades::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 9c438e85) I could not find an item for uuid: #{uuid}"
        end
        item[attrname] = attrvalue
        Blades::commitItemToItsBladeFile(item)
        HardProblem::nodeHasBeenUpdated(uuid)
    end

    # Blades::getBlob(uuid, nhash)
    def self.getBlob(uuid, nhash)
        datablob = Datablocks::getDatablobOrNull(uuid, nhash)
        return datablob if datablob

        filepath = uuidToBladeFilepathOrNull(uuid)
        if filepath.nil? then
            raise "(error: ed215999) could not find the filepath for uuid: #{uuid}"
        end
        datablob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from blade where _key_=?", [nhash]) do |row|
            datablob = row["_data_"]
        end
        db.close
        if datablob and "SHA256-#{Digest::SHA256.hexdigest(datablob)}" != nhash then
            raise "This is an extremelly odd condition. Retrived the datablob, but its nhash doens't check. uuid: #{uuid}, nhash: #{nhash}"
        end

        if datablob then
            Datablocks::putDatablob(uuid, datablob)
        end

        datablob
    end
end

class ElizabethBlade

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        Datablocks::putDatablob(@uuid, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Blades::getBlob(@uuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: ff339aa3-b7ea-4b92-a211-5fc1048c048b, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 900a9a53-66a3-4860-be5e-dffa7a88c66d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
