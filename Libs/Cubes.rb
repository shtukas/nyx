# encoding: utf-8

=begin
    Cubes::itemOrNull(uuid)
    Cubes::init(mikuType, uuid)
    Cubes::setAttribute2(uuid, attribute_name, value)
    Cubes::destroy(uuid)
    Cubes::mikuType(mikuType)
    Cubes::putDatablob2(uuid, datablob)
=end

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf(dir)

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'json'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'find'

require 'sqlite3'

require 'colorize'

=begin
    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)

    XCache::setFlag(key, flag)
    XCache::getFlag(key)

    XCache::filepath(key)
=end
require_relative "#{ENV['HOME']}/Galaxy/DataHub/Lucille-Ruby-Libraries/XCache.rb"

# -----------------------------------------------------------------------------------

class Cub3sX

    # Cub3sX::isCube(filepath) # boolean
    def self.isCube(filepath)
        File.basename(filepath)[-6, 6] == ".cub3x"
    end

    # Cub3sX::pathToGalaxy()
    def self.pathToGalaxy()
        "#{ENV["HOME"]}/Galaxy"
    end

    # Cub3sX::filepathsEnumerator()
    def self.filepathsEnumerator()
        Enumerator.new do |filepaths|
           begin
                Find.find(Cub3sX::pathToGalaxy()) do |path|
                    next if !File.file?(path)
                    if Cub3sX::isCube(path) then
                        filepaths << path
                    end
                end
            rescue
            end
        end
    end

    # Cub3sX::uuidToFilepathOrNull(uuid) # filepath or null
    def self.uuidToFilepathOrNull(uuid)
        # Let's try the uuid -> filepath mapping
        filepath = XCache::getOrNull("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuid}")
        return filepath if (filepath and File.exist?(filepath))

        # It could be that the file was renamed in its directory, let's search there
        if filepath and File.exist?(File.dirname(filepath)) then
            directory = File.dirname(filepath)
            puts "Running local search to find cube filepath for uuid: #{uuid}"
            Find.find(directory) do |filepath|
                next if !File.file?(filepath)
                next if !Cub3sX::isCube(filepath)
                uuidx = Cub3sX::getMandatoryAttribute1(filepath, "uuid")
                XCache::set("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuidx}", filepath)
                return filepath if uuidx == uuid
            end
        end

        # Got nothing from the uuid -> filepath mapping
        # Running exhaustive search.
        puts "Running exhaustive search to find cube filepath for uuid: #{uuid}"

        Find.find(Cub3sX::pathToGalaxy()) do |filepath|
            next if !File.file?(filepath)
            next if !Cub3sX::isCube(filepath)
            uuidx = Cub3sX::getMandatoryAttribute1(filepath, "uuid")
            XCache::set("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuidx}", filepath)
            return filepath if uuidx == uuid
        end

        nil
    end

    # Cub3sX::newFilepath(filepath, hash1)
    def self.newFilepath(filepath, hash1)
        dirname = File.dirname(filepath)
        basename = File.basename(filepath)
        "#{dirname}/#{basename[0, basename.length-13]}-#{hash1[0, 6]}.cub3x"
    end

    # Cub3sX::readFileAndUpdateCachedData1(filepath)
    def self.readFileAndUpdateCachedData1(filepath)
        return if !File.exist?(filepath)
        mikuType = Cub3sX::getMandatoryAttribute1(filepath, "mikuType")
        data = XCache::getOrNull("cubes:mikutype->data:-b33d-d50e1762cd8e:#{mikuType}")
        if data then
            data = JSON.parse(data)
        else
            data = {
                "lastPrunningTime" => 0,
                "entries"          => [], # Array[{uuid, filepath, item}]
            }
        end
        return if data["entries"].map{|entry| entry["filepath"] }.include?(filepath)
        item = CUtils3X::itemOrNull1(filepath)
        entry = {
            "filepath" => filepath,
            "item"     => item
        }
        data["entries"] = data["entries"].select{|entry| entry["item"]["uuid"] != item["uuid"] }
        data["entries"] << entry
        if (Time.new.to_i - data["lastPrunningTime"]) > 3600 then
            data["entries"] = data["entries"].select{|entry| File.exist?(entry["filepath"]) }
            data["lastPrunningTime"] = Time.new.to_i
        end
        XCache::set("cubes:mikutype->data:-b33d-d50e1762cd8e:#{mikuType}", JSON.generate(data))
    end

    # Cub3sX::itemHasBeenDestroyedMikuTypeDataUpdate2(uuid)
    def self.itemHasBeenDestroyedMikuTypeDataUpdate2(uuid)
        mikuType = XCache::getOrNull("cubes:uuid->mikutype:9709-7de503400fef:#{uuid}")
        return if mikuType.nil?
        data = XCache::getOrNull("cubes:mikutype->data:-b33d-d50e1762cd8e:#{mikuType}")
        return if data.nil?
        data = JSON.parse(data)
        data["entries"] = data["entries"].select{|entry| entry["item"]["uuid"] != uuid }
        data["entries"] = data["entries"].select{|entry| File.exist?(entry["filepath"]) }
        data["lastPrunningTime"] = Time.new.to_i
        XCache::set("cubes:mikutype->data:-b33d-d50e1762cd8e:#{mikuType}", JSON.generate(data))
    end

    # Cub3sX::rename(filepath1) # new filepath
    def self.rename(filepath1)
        raise "(error: da2fb2ae-a50e-4359-b453-8bc4f856571a) filepath: #{filepath1}" if !File.exist?(filepath1)
        hash1 = Digest::SHA1.file(filepath1).hexdigest
        filepath2 = Cub3sX::newFilepath(filepath1, hash1)
        if !File.exist?(File.dirname(filepath2)) then
            FileUtils.mkdir(File.dirname(filepath2))
        end
        if filepath1 != filepath2 then
            puts "renaming:".green
            puts "    old: #{filepath1}".green
            puts "    new: #{filepath2}".green
            FileUtils.mv(filepath1, filepath2)
        end
        uuidx = Cub3sX::getMandatoryAttribute1(filepath2, "uuid")
        XCache::set("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuidx}", filepath2)
        Cub3sX::readFileAndUpdateCachedData1(filepath2)
        filepath2
    end

    # Cub3sX::init(parentdirectory, mikuType, uuid) # String : filepath
    def self.init(parentdirectory, mikuType, uuid)
        puts "Cub3sX::init(mikuType: #{mikuType}, uuid: #{uuid})".green
        if parentdirectory.nil? then
            parentdirectory = "#{Cub3sX::pathToGalaxy()}/DataHub/Cubes/#{SecureRandom.hex[0, 2]}"
        end
        filepath = "#{parentdirectory}/#{SecureRandom.hex}-#{SecureRandom.hex[0, 6]}.cub3x"
        if !File.exist?(parentdirectory) then
            FileUtils.mkdir(parentdirectory)
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table entries (record_uuid string primary key, operation_unixtime float, operation_type string, _name1_ string, _name2_ string, _data_ blob)", [])
        db.execute "insert into entries (record_uuid, operation_unixtime, operation_type, _name1_, _name2_, _data_) values (?, ?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "attribute", "uuid", nil , JSON.generate(uuid)]
        db.execute "insert into entries (record_uuid, operation_unixtime, operation_type, _name1_, _name2_, _data_) values (?, ?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "attribute", "mikuType", nil, JSON.generate(mikuType)]
        db.close
        Cub3sX::rename(filepath)
        nil
    end

    # Cub3sX::merge(filepath1, filepath2) # filepath
    def self.merge(filepath1, filepath2)
        puts "> Cub3sX::merge(filepath1, filepath2) request with filepath1: #{filepath1}, filepath2: #{filepath2}".green

        if !File.exist?(filepath1) then
            raise "> incorrect Cub3sX::merge(filepath1, filepath2) request with filepath1: #{filepath1}, filepath2: #{filepath2}, filepath1 does not exist"
        end

        if !File.exist?(filepath2) then
            raise "> incorrect Cub3sX::merge(filepath1, filepath2) request with filepath1: #{filepath1}, filepath2: #{filepath2}, filepath2 does not exist"
        end

        if (filepath1 == filepath2) then
            raise "> incorrect Cub3sX::merge(filepath1, filepath2) request with filepath1: #{filepath1}, filepath2: #{filepath2}, identical locations"
        end

        uuid1 = Cub3sX::getMandatoryAttribute1(filepath1, "uuid")
        uuid2 = Cub3sX::getMandatoryAttribute1(filepath2, "uuid")

        if uuid1 != uuid2 then
            raise "> incorrect Cub3sX::merge(filepath1, filepath2) request with filepath1: #{filepath1}, filepath2: #{filepath2}, uuids are different, uuid1: #{uuid1}, uuids2: #{uuid2}"
        end

        db1 = SQLite3::Database.new(filepath1)
        db2 = SQLite3::Database.new(filepath2)

        # We move all the objects from db1 to db2
        # create table entries (record_uuid string primary key, operation_unixtime float, operation_type string, _name1_ string, _name2_ string, _data_ blob)

        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true
        db1.execute("select * from entries", []) do |row|
            db2.execute "delete from entries where record_uuid = ?", [row["record_uuid"]]
            db2.execute "insert into entries (record_uuid, operation_unixtime, operation_type, _name1_, _name2_, _data_) values (?, ?, ?, ?, ?, ?)", [row["record_uuid"], row["operation_unixtime"], row["operation_type"], row["_name1_"], row["_name2_"], row["_data_"]]
        end

        db1.close
        db2.close

        # Let's now delete the first file 
        FileUtils.rm(filepath1)

        # And rename the second one
        Cub3sX::rename(filepath2)
    end

    # Cub3sX::setAttribute1(filepath, attribute_name, value)
    def self.setAttribute1(filepath, attribute_name, value)
        puts "Cub3sX::setAttribute1(filepath: #{filepath}, attribute_name: #{attribute_name}, value: #{value})".green
        raise "(error: 042f0674-5b05-469c-adc1-db0012019e12) filepath: #{filepath}, attribute_name, #{attribute_name}" if !File.exist?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into entries (record_uuid, operation_unixtime, operation_type, _name1_, _data_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "attribute", attribute_name, JSON.generate(value)]
        db.close
        Cub3sX::rename(filepath)
        nil
    end

    # Cub3sX::setAttribute2(uuid, attribute_name, value)
    def self.setAttribute2(uuid, attribute_name, value)
        puts "Cub3sX::setAttribute2(uuid: #{uuid}, attribute_name: #{attribute_name}, value: #{value})".green
        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        raise "(error: cd0edf0c-c3d5-4743-852d-df9aae01632e) uuid: #{uuid}, attribute_name, #{attribute_name}" if filepath.nil?
        Cub3sX::setAttribute1(filepath, attribute_name, value)
    end

    # Cub3sX::getAttributeOrNull1(filepath, attribute_name)
    def self.getAttributeOrNull1(filepath, attribute_name)
        raise "(error: b1584ef9-20e9-4109-82d6-fef6d88e1265) filepath: #{filepath}, attribute_name, #{attribute_name}" if !File.exist?(filepath)
        value = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We go through all the values, because the one we want is the last one
        db.execute("select * from entries where operation_type=? and _name1_=? order by operation_unixtime", ["attribute", attribute_name]) do |row|
            value = JSON.parse(row["_data_"])
        end
        db.close
        value
    end

    # Cub3sX::getAttributeOrNull2(uuid, attribute_name)
    def self.getAttributeOrNull2(uuid, attribute_name)
        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        raise "(error: 0cda7fb0-9392-4f03-a34d-dd45fec1af2f) filepath: #{filepath}, attribute_name, #{attribute_name}" if !File.exist?(filepath)
        Cub3sX::getAttributeOrNull1(filepath, attribute_name)
    end

    # Cub3sX::getMandatoryAttribute1(filepath, attribute_name)
    def self.getMandatoryAttribute1(filepath, attribute_name)
        value = Cub3sX::getAttributeOrNull1(filepath, attribute_name)
        if value.nil? then
            raise "(error: f6d8c9d9-84cb-4f14-95c2-402d2471ef93) Failing mandatory attribute '#{attribute_name}' at cube '#{filepath}'"
        end
        value
    end

    # Cub3sX::getMandatoryAttribute2(uuid, attribute_name)
    def self.getMandatoryAttribute2(uuid, attribute_name)
        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        raise "(error: 4a99e1f9-4896-49b1-b766-05c39d5a0fa0) filepath: #{filepath}, attribute_name, #{attribute_name}" if !File.exist?(filepath)
        Cub3sX::getMandatoryAttribute1(filepath, attribute_name)
    end

    # Cub3sX::addToSet1(filepath, set_name, value_id, value)
    def self.addToSet1(filepath, set_name, value_id, value)
        puts "Cub3sX::addToSet1(filepath: #{filepath}, set_name: #{set_name}, value_id: #{value_id}, value: #{value})".green
        raise "(error: ab5c468b-e672-4465-9881-6c26f987cbb0) filepath: #{filepath}, set_name: #{set_name}, value_id: #{value_id}, value: #{value}" if !File.exist?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into entries (record_uuid, operation_unixtime, operation_type, _name1_, _name2_, _data_) values (?, ?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "set-add", set_name, value_id, JSON.generate(value)]
        db.close
        Cub3sX::rename(filepath)
        nil
    end

    # Cub3sX::addToSet2(uuid, set_name, value_id, value)
    def self.addToSet2(uuid, set_name, value_id, value)
        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        raise "(error: 85558d55-5d95-4df7-a8ab-143c260437d5) uuid: #{uuid}, set_name: #{set_name}, value_id: #{value_id}, value: #{value}" if filepath.nil?
        Cub3sX::addToSet1(filepath, set_name, value_id, value)
        nil
    end

    # Cub3sX::removeFromSet1(filpath, set_name, value_id)
    def self.removeFromSet1(filpath, set_name, value_id)
        puts "Cub3sX::removeFromSet1(filepath: #{filepath}, set_name: #{set_name}, value_id: #{value_id})".green
        raise "(error: e4675f2a-5a04-4fc0-b80d-e13db981461d) filepath: #{filepath}, set_name: #{set_name}, value_id: #{value_id}" if !File.exist?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into entries (record_uuid, operation_unixtime, operation_type, _name1_, _name2_, _data_) values (?, ?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "set-remove", set_name, value_id, nil]
        db.close
        Cub3sX::rename(filepath)
        nil
    end

    # Cub3sX::removeFromSet2(uuid, set_name, value_id)
    def self.removeFromSet2(uuid, set_name, value_id)
        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        raise "(error: 2aebe5d0-342a-4f65-ba55-dde43b723553) uuid: #{uuid}, set_name: #{set_name}, value_id: #{value_id}" if filepath.nil?
        Cub3sX::removeFromSet1(filpath, set_name, value_id)
        nil
    end

    # Cub3sX::getSet1(filepath, set_name)
    def self.getSet1(filepath, set_name)
        raise "(error: 1f4a372e-cc6f-4d8f-9d9b-ebd3e1149b93) filepath: #{filepath}, set_name: #{set_name}" if !File.exist?(filepath)
        hash_ = {} # Map[value_id, value]
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We go through all the values, because the one we want is the last one
        db.execute("select * from entries order by operation_unixtime", []) do |row|
            if row["operation_type"] == "set-add" and row["_name1_"] == set_name then
                hash_[row["_name2_"]] = JSON.parse(row["_data_"])
            end
            if row["operation_type"] == "set-remove" and row["_name1_"] == set_name then
                hash_.delete(row["_name2_"])
            end
        end
        db.close
        hash_.values
    end

    # Cub3sX::getSet2(uuid, set_name)
    def self.getSet2(uuid, set_name)
        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        raise "(error: d4f78bfc-4daa-430d-989d-60772d3309fa) uuid: #{uuid}, set_name: #{set_name}" if filepath.nil?
        Cub3sX::getSet1(filepath, set_name)
    end

    # Cub3sX::putDatablob1(filepath, datablob) # nhash
    def self.putDatablob1(filepath, datablob)
        Datablobs::putBlob(datablob)
    end

    # Cub3sX::putDatablob2(uuid, datablob) # nhash
    def self.putDatablob2(uuid, datablob)
        Datablobs::putBlob(datablob)
    end

    # Cub3sX::getDatablobOrNull1(filepath, nhash)
    def self.getDatablobOrNull1(filepath, nhash)
        blob = Datablobs::getBlobOrNull(nhash)
        return blob if blob

        puts "seeking datablob: #{nhash}".green

        raise "(error: 273139ba-e4ef-4345-a4de-2594ce77c563) filepath: #{filepath}" if !File.exist?(filepath)
        datablob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from entries where operation_type=? and _name1_=? order by operation_unixtime", ["datablob", nhash]) do |row|
            datablob = row["_data_"]
        end
        db.close

        if datablob then
            nhash_check = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
            if nhash_check == nhash then
                Datablobs::putBlob(datablob)
                return datablob
            else
                puts "[4eb9459c-401f-4a23-8cbb-fc9158c2ccc2] we got a datablob but it wasn't correct (filepath: #{filepath}, nhash: #{nhash})".green
                return nil # we got a datablob but it wasn't correct
            end
        end

        nextuuid = Cub3sX::getAttributeOrNull1(filepath, "next")
        if nextuuid then
            datablob = Cub3sX::getDatablobOrNull2(nextuuid, nhash)
            if datablob then
                Datablobs::putBlob(datablob)
                return datablob # 🎉
            end
        end

        nil
    end

    # Cub3sX::getDatablobOrNull2(uuid, nhash)
    def self.getDatablobOrNull2(uuid, nhash)
        blob = Datablobs::getBlobOrNull(nhash)
        return blob if blob
        puts "seeking datablob: #{nhash}".green

        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        raise "(error: bee6247e-c798-44a9-b72b-62773f75254e) uuid: #{uuid}" if filepath.nil?
        blob = Cub3sX::getDatablobOrNull1(filepath, nhash)

        Datablobs::putBlob(blob)
        blob
    end

    # Cub3sX::destroy(uuid)
    def self.destroy(uuid)
        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        if filepath then
            puts "> deleting file: #{filepath}"
            FileUtils.rm(filepath)
        end
        Cub3sX::itemHasBeenDestroyedMikuTypeDataUpdate2(uuid)
    end
end

class C3xElizabeth

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        Cub3sX::putDatablob2(@uuid, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Cub3sX::getDatablobOrNull2(@uuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: 6923aca5-2e83-4379-9d58-6c09c185d07c, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 63374c58-b2f3-4e79-9844-2a110c57674d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class CUtils3X

    # CUtils3X::scan_merge()
    def self.scan_merge()
        mapping = {} # uuid => Array[filepath]

        Cub3sX::filepathsEnumerator().each{|filepath|
            uuid = Cub3sX::getMandatoryAttribute1(filepath, "uuid")
            if mapping[uuid].nil? then
                mapping[uuid] = []
            end
            mapping[uuid] = (mapping[uuid] + [filepath]).uniq
        }

        mapping.values.select{|l| l.size > 1 }.each{|l|
            puts JSON.pretty_generate(l)
            l.reduce(l.first){|filepath1, filepath2|
                if filepath1 == filepath2 then
                    filepath1
                else
                    Cub3sX::merge(filepath1, filepath2)
                end
            }
        }
    end

    # CUtils3X::scan_mikuTypes_updates(verbose)
    def self.scan_mikuTypes_updates(verbose)
        puts "collecting filepaths" if verbose
        filepaths = Cub3sX::filepathsEnumerator()
            .to_a
        
        filepaths
            .each{|filepath|
                XCache::set("liveness:0340e024-58b3-4eb7", Time.new.to_i)
                next if XCache::getFlag("31ac9cc4-6ec1-4b1f-91ba-70ad71880d55:#{filepath}")
                puts filepath if verbose
                Cub3sX::readFileAndUpdateCachedData1(filepath)
                XCache::setFlag("31ac9cc4-6ec1-4b1f-91ba-70ad71880d55:#{filepath}", true)
            }
    end

    # CUtils3X::itemOrNull1(filepath)
    def self.itemOrNull1(filepath)
        raise "(error: f14287d8-a023-42fc-9cbb-9222bdfae30c) filepath does not exist" if !File.exist?(filepath)

        item = XCache::getOrNull("803c65a7-9c8d-4544-b1eb-b4cc20f7187c:#{filepath}")
        if item then
            return JSON.parse(item)
        end

        item = {}

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from entries where operation_type=? order by operation_unixtime", ["attribute"]) do |row|
            item[row["_name1_"]] = JSON.parse(row["_data_"])
        end
        db.close

        XCache::set("803c65a7-9c8d-4544-b1eb-b4cc20f7187c:#{filepath}", JSON.generate(item))

        item
    end

    # CUtils3X::itemOrNull2(uuid)
    def self.itemOrNull2(uuid)
        filepath = Cub3sX::uuidToFilepathOrNull(uuid)
        return nil if filepath.nil?
        Cub3sX::readFileAndUpdateCachedData1(filepath)
        CUtils3X::itemOrNull1(filepath)
    end
end

class Cubes

    # Cubes::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        CUtils3X::itemOrNull2(uuid)
    end

    # Cubes::init(parentdirectory, mikuType, uuid)
    def self.init(parentdirectory, mikuType, uuid)
        Cub3sX::init(parentdirectory, mikuType, uuid)
    end

    # Cubes::setAttribute2(uuid, attribute_name, value)
    def self.setAttribute2(uuid, attribute_name, value)
        Cub3sX::setAttribute2(uuid, attribute_name, value)
    end

    # Cubes::destroy(uuid)
    def self.destroy(uuid)
        Cub3sX::destroy(uuid)
    end

    # Cubes::mikuType(mikuType)
    def self.mikuType(mikuType)
        data = XCache::getOrNull("cubes:mikutype->data:-b33d-d50e1762cd8e:#{mikuType}")
        return [] if data.nil?
        data = JSON.parse(data)
        data["entries"]
            .select{|entry| File.exist?(entry["filepath"]) }
            .map{|entry| entry["item"] }
    end

    # Cubes::putDatablob2(uuid, datablob)
    def self.putDatablob2(uuid, datablob)
        Cub3sX::putDatablob2(uuid, datablob)
    end
end
