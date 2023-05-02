# encoding: utf-8

=begin
Blades
    Blades::decideInitLocation(uuid)
    Blades::locateBlade(token)

    Blades::init(uuid)
    Blades::setAttribute(uuid, attribute_name, value)
    Blades::getAttributeOrNull(uuid, attribute_name)
    Blades::addToSet(uuid, set_id, element_id, value)
    Blades::removeFromSet(uuid, set_id, element_id)
    Blades::putDatablob(uuid, key, datablob)
    Blades::getDatablobOrNull(uuid, key)
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

# -----------------------------------------------------------------------------------

=begin

A blade is a log of events in a sqlite file.
It offers a key/value store interface and a set interface.

Each record is of the form
    (record_uuid string primary key, operation_unixtime float, operation_type string, _name_ string, _data_ blob)

Conventions:
    ----------------------------------------------------------------------------------
    | operation_name     | meaning of name                  | data conventions       |
    ----------------------------------------------------------------------------------
    | "attribute"        | name of the attribute            | value is json encoded  |
    | "set-add"          | expression <set_name>/<value_id> | value is json encoded  |
    | "set-remove"       | expression <set_name>/<value_id> |                        |
    | "datablob"         | key (for instance a nhash)       | blob                   |
    ----------------------------------------------------------------------------------

reserved attributes:
    - uuid     : unique identifier of the blade.
    - mikuType : String
    - next     : (optional) uuid of the next blade in the sequence

=end

class Blades

    # Blades::decideInitLocation(uuid)
    def self.decideInitLocation(uuid)
        "#{ENV["HOME"]}/Galaxy/DataHub/Blades/#{uuid}.blade"
    end

    # Blades::init(uuid) # String : filepath
    def self.init(uuid)
        filepath = Blades::decideInitLocation(uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table records (record_uuid string primary key, operation_unixtime float, operation_type string, _name_ string, _data_ blob)", [])
        db.close
        Blades::setAttribute(uuid, "uuid", uuid)
        filepath
    end

    # Blades::locateBlade(token) # filepath
    # Token is either a uuid or a filepath
    def self.locateBlade(token)
        # We start by interpreting the token as a filepath
        return token if File.exist?(token)
        
        uuid =
            if token.include?(".blade") then
                # filepath
                return token if File.exist?(token)
                File.basename(token).split("@").first
            else
                uuid = token
            end

        # We have the uuid, let's try the uuid -> filepath mapping
        filepath = XCache::getOrNull("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuid}")
        return filepath if File.exist?(filepath)

        # We have the uuid, but got noting from the uuid -> filepath mapping
        # running exaustive search.

        root = "#{ENV["HOME"]}/Galaxy/DataHub/Blades"

        Find.find(root) do |filepath|
            next if !File.file?(filepath)
            next if filepath[-6, 6] != ".blade"

            readUUIDFromBlade = lambda {|filepath|
                value = nil
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                # We go through all the values, because the one we want is the last one
                db.execute("select * from records where operation_type=? and _name_=? order by operation_unixtime", ["attribute", attribute_name]) do |row|
                    value = JSON.parse(row["_data_"])
                end
                db.close
                raise "(error: 22749e93-77e0-4907-8226-f2e620d4a372)" if value.nil?
                value
            }

            if readUUIDFromBlade.call(filepath) == uuid then
                XCache::set("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuid}", filepath)
                return filepath
            end
        end

        nil
    end

    # Blades::rename(filepath1)
    def self.rename(filepath1)
        return if !File.exist?(filepath1)
        hash1 = Digest::SHA1.hexdigest(filepath1)
        dirname = File.dirname(filepath1)
        uuid = File.basename(filepath1).split("@").first
        filepath2 = "#{dirname}/#{uuid}@#{hash1}.blade"
        return if filepath1 == filepath2
        FileUtils.mv(filepath1, filepath2)
        XCache::set("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuid}", filepath2)
        MikuTypes::registerFilepath(filepath2)
    end

    # Blades::setAttribute(token, attribute_name, value)
    def self.setAttribute(token, attribute_name, value)
        filepath = Blades::locateBlade(token)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into records (record_uuid, operation_unixtime, operation_type, _name_, _data_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "attribute", attribute_name, JSON.generate(value)]
        db.close
        Blades::rename(filepath)
    end

    # Blades::getAttributeOrNull(token, attribute_name)
    def self.getAttributeOrNull(token, attribute_name)
        value = nil
        filepath = Blades::locateBlade(token)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We go through all the values, because the one we want is the last one
        db.execute("select * from records where operation_type=? and _name_=? order by operation_unixtime", ["attribute", attribute_name]) do |row|
            value = JSON.parse(row["_data_"])
        end
        db.close
        value
    end

    # Blades::getMandatoryAttribute(token, attribute_name)
    def self.getMandatoryAttribute(token, attribute_name)
        value = nil
        filepath = Blades::locateBlade(token)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We go through all the values, because the one we want is the last one
        db.execute("select * from records where operation_type=? and _name_=? order by operation_unixtime", ["attribute", attribute_name]) do |row|
            value = JSON.parse(row["_data_"])
        end
        db.close
        raise "Failing mandatory attribute '#{attribute_name}' at blade '#{filepath}'" if value.nil?
        value
    end

    # Blades::addToSet(token, set_id, element_id, value)
    def self.addToSet(token, set_id, element_id, value)

    end

    # Blades::removeFromSet(token, set_id, element_id)
    def self.removeFromSet(token, set_id, element_id)

    end

    # Blades::getSet(token, set_id)
    def self.getSet(token, set_id)

    end

    # Blades::putDatablob(token, key, datablob)
    def self.putDatablob(token, key, datablob)

    end

    # Blades::getDatablobOrNull(token, key)
    def self.getDatablobOrNull(token, key)

    end
end
