
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

class BladesConfig
    # BladesConfig::repository_path()
    def self.repository_path()
        "#{Config::pathToNyxData()}/blades"
    end

    # BladesConfig::cache_prefix()
    def self.cache_prefix()
        "d5b50dac-4562-4189-8022-b47d9c011c3d"
    end
end

class Blades

    # --------------------------------------------------------------------------
    # The original version of this file is Catalyst's Blades.rb
    # Nyx has a copy of it
    # --------------------------------------------------------------------------

    # --------------------------------------------------------------------------
    # Private

    # Blades::ensure_content_addressing(filepath)
    def self.ensure_content_addressing(filepath)
        return if !File.exist?(filepath)
        canonical_filename = "#{Digest::SHA1.file(filepath).hexdigest}.blade.sqlite3"
        canonical_filepath = "#{BladesConfig::repository_path()}/#{canonical_filename[0, 2]}/#{canonical_filename}"
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
            Find.find(Config::pathToGalaxy()) do |path|
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

    # --------------------------------------------------------------------------
    # Public interface

    # --------------------------------------------------------------------------
    # The original version of this file is Catalyst's Blades.rb
    # Nyx has a copy of it
    # --------------------------------------------------------------------------

    # --------------------------------------------------------------------------
    # Public interface

    @memory1 = {}

    # Blades::init(uuid, mikuType)
    def self.init(uuid, mikuType)
        # create a new blade

        filepath = "#{BladesConfig::repository_path()}/#{SecureRandom.hex}.blade.sqlite3"

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

        # Maintaining: #{BladesConfig::cache_prefix()}:44a38835-4c00-4af9-a3c6-d5340b202831
        items = XCache::getOrNull("#{BladesConfig::cache_prefix()}:44a38835-4c00-4af9-a3c6-d5340b202831")
        if items then
            items = JSON.parse(items)
            item = Blades::itemOrNull(uuid)
            if item then
                items[uuid] = item
                XCache::set("#{BladesConfig::cache_prefix()}:44a38835-4c00-4af9-a3c6-d5340b202831", JSON.generate(items))
            end
        end

        # Maintaining: @memory1
        @memory1[uuid] = Blades::itemOrNull(uuid)

        nil
    end

    # Blades::commitItem(item)
    def self.commitItem(item)
        uuid = item["uuid"]
        item.to_h.each{|attrname, attrvalue|
            next if attrname == "uuid"
            Blades::setAttribute(uuid, attrname, attrvalue)
        }
    end

    # Blades::itemsEnumeratorUseTheForce()
    def self.itemsEnumeratorUseTheForce()
        Enumerator.new do |items|
            Blades::filepaths_enumerator().each{|filepath|
                item = Blades::filepathToItem(filepath)
                items << item
            }
        end
    end

    # Blades::items()
    def self.items()

        # We try @memory1
        if @memory1.values.size > 0 then
            return @memory1.values
        end

        # We try XCache
        data = XCache::getOrNull("#{BladesConfig::cache_prefix()}:44a38835-4c00-4af9-a3c6-d5340b202831")
        if data then
            data = JSON.parse(data)
            @memory1 = data
            return @memory1.values
        end

        data = {}
        Blades::itemsEnumeratorUseTheForce().each{|item|
            data[item["uuid"]] = item
        }

        @memory1 = data
        XCache::set("#{BladesConfig::cache_prefix()}:44a38835-4c00-4af9-a3c6-d5340b202831", JSON.generate(data))

        @memory1.values
    end

    # Blades::mikuTypes()
    def self.mikuTypes()
        mikuTypes = []
        Blades::items().each{|item|
            mikuTypes << item["mikuType"]
        }
        mikuTypes.uniq
    end

    # Blades::mikuType(mikuType) -> Array[Item]
    def self.mikuType(mikuType)
        Blades::items().select{|item| item["mikuType"] == mikuType }
    end

    # Blades::deleteItem(uuid)
    def self.deleteItem(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "mikuType", 'NxDeleted')

        # Delete from XCache
        items = XCache::getOrNull("#{BladesConfig::cache_prefix()}:44a38835-4c00-4af9-a3c6-d5340b202831")
        if items then
            items = JSON.parse(items)
            items.delete(uuid)
            XCache::set("#{BladesConfig::cache_prefix()}:44a38835-4c00-4af9-a3c6-d5340b202831", JSON.generate(items))
        end

        # Delete from @memory1
        @memory1.delete(uuid)
        nil
    end

    # --------------------------------------------------------------------------
    # Datablobs
    # create table datablobs (nhash TEXT primary key, data BLOB);

    # --------------------------------------------------------------------------
    # The original version of this file is Catalyst's Blades.rb
    # Nyx has a copy of it
    # --------------------------------------------------------------------------

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
