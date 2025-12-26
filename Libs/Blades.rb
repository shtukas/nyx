
# encoding: UTF-8

=begin

Blades are the file where we store catalyst items data

create table version (version INTEGER primary key);
create table attributes (key TEXT primary key, value TEXT); # values are always JSON encoded
create table datablobs (nhash TEXT primary key, data BLOB);

There must at least be 
    - one attribute called uuid that is the unique identifier of the item
    - one attribute called mikuType

Note that although a unixtime is create at initialization, and unless required by the 
mikuType itsef, as far as blades go, we only require it for NxDeleted items,

=end

class Blades

    # -----------------------------------------------------------
    # Private

    # Blades::repository_path()
    def self.repository_path()
        "#{Config::pathToData()}/blades"
    end

    # Blades::ensure_content_addressing(filepath)
    def self.ensure_content_addressing(filepath)
        return if !File.exist?(filepath)
        canonical_filename = "#{Digest::SHA1.file(filepath).hexdigest}.blade.sqlite3"
        canonical_filepath = "#{Blades::repository_path()}/#{canonical_filename[0, 2]}/#{canonical_filename}"
        return if filepath == canonical_filepath
        if !File.exist?(File.dirname(canonical_filepath)) then
            FileUtils.mkdir(File.dirname(canonical_filepath))
        end
        FileUtils.mv(filepath, canonical_filepath)
        canonical_filepath
    end

    # Blades::filepaths_enumerator()
    def self.filepaths_enumerator()
        Enumerator.new do |filepaths|
            Find.find(Blades::repository_path()) do |path|
                if File.file?(path) and path[-14, 14] == ".blade.sqlite3" then
                    filepaths << path
                end
            end
        end
    end

    # Blades::read_uuid_from_file_or_null(filepath)
    def self.read_uuid_from_file_or_null(filepath)
        uuid = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from attributes where key=?", ["uuid"]) do |row|
            uuid = JSON.parse(row["value"])
        end
        db.close
        uuid
    end

    # Blades::uuidToFilepathOrNullUseTheForce(uuid)
    def self.uuidToFilepathOrNullUseTheForce(uuid)
        Blades::filepaths_enumerator().each{|filepath|
            if Blades::read_uuid_from_file_or_null(filepath) == uuid then
                return filepath
            end
        }
        nil
    end

    # Blades::uuidToFilepathOrNull(uuid)
    def self.uuidToFilepathOrNull(uuid)
        filepath = XCache::getOrNull("4e4d5752-a99a-4ed1-87b0-eb3fccb2b881:#{uuid}")
        if filepath and File.exist?(filepath) then
            if Blades::read_uuid_from_file_or_null(filepath) == uuid then
                return filepath
            end
        end

        puts "searching filepath for uuid: #{uuid}".yellow
        filepath = Blades::uuidToFilepathOrNullUseTheForce(uuid)
        return nil if filepath.nil?

        XCache::set("4e4d5752-a99a-4ed1-87b0-eb3fccb2b881:#{uuid}", filepath)
        filepath
    end

    # Blades::filepathToItem(filepath)
    def self.filepathToItem(filepath)
        if !File.exist?(filepath) then
            raise "(ae8cc132) filepath: #{filepath}"
        end
        item = {}
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from attributes", []) do |row|
            item[row["key"]] = JSON.parse(row["value"])
        end
        db.close
        item
    end

    # -----------------------------------------------------------
    # Public interface

    # -----------------------------------------------------------
    # Items

    # Blades::init(uuid, mikuType)
    def self.init(uuid, mikuType)
        # create a new blade

        filepath = "#{Blades::repository_path()}/#{SecureRandom.hex}.blade.sqlite3"

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table version (version INTEGER primary key)", [])
        db.execute("insert into version (version) values (?)", [1])
        db.execute("create table attributes (key TEXT primary key, value TEXT)", [])
        db.execute("insert into attributes (key, value) values (?, ?)", ["uuid", JSON.generate(uuid)])
        db.execute("insert into attributes (key, value) values (?, ?)", ["mikuType", JSON.generate(mikuType)])
        db.execute("insert into attributes (key, value) values (?, ?)", ["unixtime", JSON.generate(Time.new.to_i)])
        db.execute("create table datablobs (nhash TEXT primary key, data BLOB)", [])
        db.commit
        db.close

        # maintaining content addressing
        filepath = Blades::ensure_content_addressing(filepath)

        # updating the cache for reading later
        XCache::set("4e4d5752-a99a-4ed1-87b0-eb3fccb2b881:#{uuid}", filepath)
        nil
    end

    # Blades::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Blades::uuidToFilepathOrNull(uuid)
        return nil if filepath.nil?
        Blades::filepathToItem(filepath)
    end

    # Blades::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        filepath = Blades::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from attributes where key=?", [attrname])
        db.execute("insert into attributes (key, value) values (?, ?)", [attrname, JSON.generate(attrvalue)])
        db.commit
        db.close

        # maintaining content addressing
        filepath = Blades::ensure_content_addressing(filepath)

        # updating the cache for reading later
        XCache::set("4e4d5752-a99a-4ed1-87b0-eb3fccb2b881:#{uuid}", filepath)
        nil
    end

    # Blades::commitItem(item)
    def self.commitItem(item)
        uuid = item["uuid"]
        item.to_h.each{|attrname, attrvalue|
            next if key == "uuid"
            Blades::setAttribute(uuid, attrname, attrvalue)
        }
    end

    # Blades::items_enumerator()
    def self.items_enumerator()
        Enumerator.new do |items|
            Blades::filepaths_enumerator().each{|filepath|
                item = Blades::filepathToItem(filepath)
                items << item
            }
        end
    end

    # Blades::mikuTypes()
    def self.mikuTypes()
        mikuTypes = []
        Blades::items_enumerator().each{|item|
            mikuTypes << item["mikuType"]
        }
        mikuTypes.uniq
    end

    # Blades::mikuType(mikuType) -> Array[Item]
    def self.mikuType(mikuType)
        Blades::items_enumerator().select{|item| item["mikuType"] == mikuType }
    end

    # Blades::deleteItem(uuid)
    def self.deleteItem(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "mikuType", 'NxDeleted')
    end

    # -----------------------------------------------------------
    # Datablobs
    # create table datablobs (nhash TEXT primary key, data BLOB);

    # Blades::putBlob(uuid, datablob)
    def self.putBlob(uuid, datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        filepath = Blades::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from datablobs where nhash=?", [nhash])
        db.execute("insert into datablobs (nhash, data) values (?, ?)", [nhash, datablob])
        db.commit
        db.close

        # maintaining content addressing
        filepath = Blades::ensure_content_addressing(filepath)

        # updating the cache for reading later
        XCache::set("4e4d5752-a99a-4ed1-87b0-eb3fccb2b881:#{uuid}", filepath)
        nil

        nhash
    end

    # Blades::getBlobOrNull(uuid, nhash)
    def self.getBlobOrNull(uuid, nhash)
        filepath = Blades::uuidToFilepathOrNull(uuid)
        return nil if filepath.nil?
        blob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from datablobs where nhash=?", [nhash]) do |row|
            blob = row["data"]
        end
        db.close
        blob
    end
end
