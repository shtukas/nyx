#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require_relative "CatalystCommon.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

# -------------------------------------------------------------------------------------

class StreamKiller
    def self.getCatalystObjects()
        startingUnixtime = 1524341098
        endingUnixtime   = 1524341098 + 86400*100 # 100 days
        startingCount    = 995
        endingCount      = 0
        idealCount       = 995 - 995*(Time.new.to_i - startingUnixtime).to_f/(endingUnixtime - startingUnixtime)
        currentCount     = Dir.entries("/Galaxy/DataBank/Catalyst/Stream/strm1").size
        targetFoldername = Dir.entries("/Galaxy/DataBank/Catalyst/Stream/strm1").select{|filename| filename[0,1]!="." }.sample
        targetFolderUUID = IO.read("/Galaxy/DataBank/Catalyst/Stream/strm1/#{targetFoldername}/.uuid").strip
        objects = []
        if currentCount > idealCount then
            objects << {
                "uuid" => "2662371C-44C0-422B-83FF-FAB12B76FDED",
                "metric" => 1,
                "announce" => "-> stream killer (ideal: #{idealCount}, current: #{currentCount}): /Galaxy/DataBank/Catalyst/Stream/strm1/#{targetFoldername}",
                "commands" => [],
                "command-interpreter" => lambda{|object, command| 
                    targetuuid = object["target-uuid"]
                    searchobjects = CatalystCore::objects()
                        .select{|object| object['announce'].downcase.include?(targetuuid) }
                    if searchobjects.size>0 then
                        searchobject = searchobjects.first
                        Jupiter::putsObjectWithShellDisplay(searchobject, [])
                    end
                    return [nil, false]

                },
                "target-uuid" => targetFolderUUID
            }
        end
        objects
    end
end
