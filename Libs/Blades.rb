
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

    # BladesConfig::cacheDirectory()
    def self.cacheDirectory()
        "#{Config::pathToNyxData()}/blades-cache"
    end

    # BladesConfig::getDataFromFSCacheOrNull()
    def self.getDataFromFSCacheOrNull()
        filepaths = LucilleCore::locationsAtFolder(BladesConfig::cacheDirectory()).select{|filepath| filepath[-12, 12] == ".items.cache" }
        if filepaths.size == 1 then
            filepath = filepaths.first
            return JSON.parse(IO.read(filepath))
        end
        nil
    end

    # BladesConfig::commitDataToFSCache(data)
    def self.commitDataToFSCache(data)
        filepaths = LucilleCore::locationsAtFolder(BladesConfig::cacheDirectory()).select{|filepath| filepath[-12, 12] == ".items.cache" }
        filepaths.each{|filepath|
            FileUtils.rm(filepath)
        }
        content = JSON.pretty_generate(data)
        filepath = "#{BladesConfig::cacheDirectory()}/#{Digest::SHA1.hexdigest(content)}.items.cache"
        File.open(filepath, "w"){|f| f.puts(content) }
    end
end

class Blades

    # --------------------------------------------------------------------------
    # The original version of this file is Catalyst's Blades.rb
    # Nyx has a copy of it.
    # Do not get rid of the cache prefix, that's how we maintain dataset difference
    # between Catalyst and Nyx.
    # --------------------------------------------------------------------------

    # --------------------------------------------------------------------------
    # Private

    # Blades::today()
    def self.today()
        Time.new.to_s[0, 10]
    end

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
            Find.find(BladesConfig::repository_path()) do |path|
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
        puts "uuidToFilepathOrNullUseTheForce: #{uuid}".yellow
        Blades::filepaths_enumerator().each{|filepath|
            # To speed up further searches, we pick locations mapping as we go,
            # but only once per location
            if !XCache::getFlag("filepath-has-been-picked-up-a9c8-98f5e8344a82:#{filepath}") then
                uuidx = Blades::read_uuid_from_file_or_null(filepath)
                XCache::set("uuid-to-filepath-87b0-eb3fccb2b881:#{uuidx}", filepath)
                XCache::setFlag("filepath-has-been-picked-up-a9c8-98f5e8344a82:#{filepath}", true)
            end
            if Blades::read_uuid_from_file_or_null(filepath) == uuid then
                return filepath
            end
        }
        nil
    end

    # Blades::uuidToFilepathOrNull(uuid)
    def self.uuidToFilepathOrNull(uuid)
        filepath = XCache::getOrNull("uuid-to-filepath-87b0-eb3fccb2b881:#{uuid}")
        if filepath and File.exist?(filepath) then
            if Blades::read_uuid_from_file_or_null(filepath) == uuid then
                return filepath
            end
        end

        filepath = Blades::uuidToFilepathOrNullUseTheForce(uuid)
        return nil if filepath.nil?

        XCache::set("uuid-to-filepath-87b0-eb3fccb2b881:#{uuid}", filepath)
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

    # Blades::destroyBlade(uuid)
    def self.destroyBlade(uuid)
        filepath = Blades::uuidToFilepathOrNull(uuid)
        if filepath then
            FileUtils.rm(filepath)
        end
        nil
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

    # Blades::init(uuid)
    def self.init(uuid)
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
        db.execute("insert into attributes (key, value) values (?, ?)", ["mikuType", JSON.generate("NxDeleted")])
        db.execute("insert into attributes (key, value) values (?, ?)", ["unixtime", JSON.generate(Time.new.to_i)])
        db.execute("create table datablobs (nhash TEXT primary key, data BLOB)", [])
        db.commit
        db.close

        # maintaining content addressing
        filepath = Blades::ensure_content_addressing(filepath)

        # updating the cache for reading later
        XCache::set("uuid-to-filepath-87b0-eb3fccb2b881:#{uuid}", filepath)
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
        XCache::set("uuid-to-filepath-87b0-eb3fccb2b881:#{uuid}", filepath)
        XCache::setFlag("filepath-has-been-picked-up-a9c8-98f5e8344a82:#{filepath}", true)

        if @memory1 then
            @memory1[uuid] = Blades::itemOrNull(uuid)
        end

        data = BladesConfig::getDataFromFSCacheOrNull()
        if data then
            data[uuid] = Blades::itemOrNull(uuid)
            BladesConfig::commitDataToFSCache(data)
        end

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
            #puts "returning items from memory".yellow
            return @memory1.values
        end

        # We try FSCache
        data = BladesConfig::getDataFromFSCacheOrNull()
        if data then
            @memory1 = data
            #puts "returning items from fs cache".yellow
            return @memory1.values
        end

        data = {}
        Blades::itemsEnumeratorUseTheForce().each{|item|
            if data[item["uuid"]] then
                puts "Looks like we have a duplicate uuid 🤔, this is not supposed to happen."
                puts item
                exit
            end
            data[item["uuid"]] = item
        }

        BladesConfig::commitDataToFSCache(data)
        @memory1 = data

        data.values
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
        #Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        #Blades::setAttribute(uuid, "mikuType", 'NxDeleted')

        Blades::destroyBlade(uuid)

        if @memory1 then
            @memory1.delete(uuid)
        end

        data = BladesConfig::getDataFromFSCacheOrNull()
        if data then
            data.delete(uuid)
            BladesConfig::commitDataToFSCache(data)
        end

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
        XCache::set("uuid-to-filepath-87b0-eb3fccb2b881:#{uuid}", filepath)
        XCache::setFlag("filepath-has-been-picked-up-a9c8-98f5e8344a82:#{filepath}", true)

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

