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

require_relative "Commons.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require_relative "Stream.rb"

# -------------------------------------------------------------------------------------

# RequirementsReviewReminder::getCatalystObjects()

class RequirementsReviewReminder
    def self.getCatalystObjects()
        if KeyValueStore::getOrNull(nil, "e165addc-c72a-4a43-a234-e4189c59780b:#{Time.new.to_s[0,12]}").nil? then
            metric = 1
            [
                {
                    "uuid" => "f8e7c5f6",
                    "metric" => metric,
                    "announce" => "-> requirements review reminder",
                    "commands" => [],
                    "command-interpreter" => lambda{|object, command|
                        RequirementsOperator::currentlyUnsatisfifiedRequirements()
                        .each{|requirement|
                            puts "showing contents of #{requirement}"
                            Jupiter::doExecute(object, "show #{requirement}")
                        }
                        KeyValueStore::set(nil, "e165addc-c72a-4a43-a234-e4189c59780b:#{Time.new.to_s[0,12]}", "done")
                    }
                }
            ]
        else
            []
        end
    end
end

