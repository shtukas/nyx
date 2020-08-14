
# encoding: utf-8

# require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/Dionysus1.rb"
=begin

Dionysus1::kvstore_set(filepath, key, value)
Dionysus1::kvstore_getOrNull(filepath, key): null or String
Dionysus1::kvstore_setObject(filepath, key, object)
Dionysus1::kvstore_getObjectOrNull(filepath, key): null or Object
Dionysus1::kvstore_destroy(filepath, key)

Dionysus1::sets_putObject(filepath, _setuuid_, _objectuuid_, _object_)
Dionysus1::sets_getObjectOrNull(filepath, _setuuid_, _objectuuid_): null or Object
Dionysus1::sets_getObjects(filepath, _setuuid_): Array[Object]

=end


# ------------------------------------------------------------------------

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'find'

require 'json'

require "sqlite3"

# ------------------------------------------------------------------------

=begin

Dionysus1 is a library to manipulate single files as key value stores and set stores

They are Sqlite3 files with a single table

table: table1
    _key_      text
    _value_    blob

table: table2
    _setuuid_       text
    _objectuuid_    text
    _object_        text

$ sqlite3 testing.db
SQLite version 3.28.0 2019-04-15 14:49:49
Enter ".help" for usage hints.
sqlite> create table table1 (_key_ text, _value_ blob);
sqlite> create table table2 (_setuuid_ text, _objectuuid_ text, _object_ text);
sqlite> .schema
CREATE TABLE table1 (_key_ text, _value_ blob);
sqlite> .exit

=end

# ------------------------------------------------------------------------

class Dionysus1

    # Dionysus1::private_makeFile(filepath)
    def self.private_makeFile(filepath)
        db = SQLite3::Database.new(filepath)
        db.execute("create table table1 (_key_ text, _value_ blob);")
        db.execute("create table table2 (_setuuid_ text, _objectuuid_ text, _object_ text);")
        db.close
    end

    # Key Value store

    # Dionysus1::kvstore_set(filepath, key, value)
    def self.kvstore_set(filepath, key, value)
        if !File.exists?(filepath) then
            Dionysus1::private_makeFile(filepath)
        end
        db = SQLite3::Database.new(filepath)
        db.transaction 
        db.execute "delete from table1 where _key_=?", [key]
        db.execute "insert into table1 (_key_, _value_) values ( ?, ? )", [key, value]
        db.commit 
        db.close
        nil
    end

    # Dionysus1::kvstore_getOrNull(filepath, key)
    def self.kvstore_getOrNull(filepath, key)
        if !File.exists?(filepath) then
            Dionysus1::private_makeFile(filepath)
        end
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from table1 where _key_=?" , [key] ) do |row|
            answer = row['_value_']
        end
        db.close
        answer
    end

    # Dionysus1::kvstore_setObject(filepath, key, object)
    def self.kvstore_setObject(filepath, key, object)
        if !File.exists?(filepath) then
            Dionysus1::private_makeFile(filepath)
        end
        db = SQLite3::Database.new(filepath)
        db.transaction 
        db.execute "delete from table1 where _key_=?", [key]
        db.execute "insert into table1 (_key_, _value_) values ( ?, ? )", [key, JSON.generate(object)]
        db.commit 
        db.close
        nil
    end

    # Dionysus1::kvstore_getObjectOrNull(filepath, key)
    def self.kvstore_getObjectOrNull(filepath, key)
        if !File.exists?(filepath) then
            Dionysus1::private_makeFile(filepath)
        end
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from table1 where _key_=?" , [key] ) do |row|
            answer = JSON.parse(row['_value_'])
        end
        db.close
        answer
    end

    # Dionysus1::kvstore_destroy(filepath, key)
    def self.kvstore_destroy(filepath, key)
        if !File.exists?(filepath) then
            Dionysus1::private_makeFile(filepath)
        end
        db = SQLite3::Database.new(filepath)
        db.execute "delete from table1 where _key_=?", [key]
        db.close
        nil
    end

    #  Sets

    # Dionysus1::sets_putObject(filepath, _setuuid_, _objectuuid_, _object_)
    def self.sets_putObject(filepath, _setuuid_, _objectuuid_, _object_)
        if !File.exists?(filepath) then
            Dionysus1::private_makeFile(filepath)
        end
        db = SQLite3::Database.new(filepath)
        db.transaction 
        db.execute "delete from table2 where _setuuid_=? and _objectuuid_=?", [_setuuid_, _objectuuid_]
        db.execute "insert into table2 (_setuuid_, _objectuuid_, _object_) values ( ?, ?, ? )", [_setuuid_, _objectuuid_, JSON.generate(_object_)]
        db.commit 
        db.close
        nil
    end

    # Dionysus1::sets_getObjectOrNull(filepath, _setuuid_, _objectuuid_)
    def self.sets_getObjectOrNull(filepath, _setuuid_, _objectuuid_)
        if !File.exists?(filepath) then
            Dionysus1::private_makeFile(filepath)
        end
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from table2 where _setuuid_=? and _objectuuid_=?" , [_setuuid_, _objectuuid_] ) do |row|
            answer = JSON.parse(row['_value_'])
        end
        db.close
        answer
    end

    # Dionysus1::sets_getObjects(filepath, _setuuid_)
    def self.sets_getObjects(filepath, _setuuid_)
        if !File.exists?(filepath) then
            Dionysus1::private_makeFile(filepath)
        end
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true
        answer = []
        db.execute( "select * from table2 where _setuuid_=?" , [_setuuid_] ) do |row|
            answer << JSON.parse(row['_value_'])
        end
        db.close
        answer
    end

end
