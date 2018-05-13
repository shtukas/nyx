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

require_relative "Agent-Wave.rb"
require_relative "Agent-Ninja.rb"
require_relative "Agent-Stream.rb"
require_relative "Agent-Today.rb"
require_relative "Agent-TimeCommitments.rb"
require_relative "Agent-StreamKiller.rb"
require_relative "Agent-GuardianTime.rb"
require_relative "Agent-Kimchee.rb"
require_relative "Agent-Vienna.rb"
require_relative "Agent-ViennaKiller.rb"
require_relative "Agent-OpenProjects.rb"

# ----------------------------------------------------------------------

# CatalystObjects::all()
# CatalystObjects::structure1()

class CatalystObjects
    def self.structure1()
        structure1 = {}
        CatalystDataOperator::dataSources().each{|tuple|
            structure1[tuple[0]] = tuple[1].call()
        }
        structure1
    end
    def self.all()
        objects = CatalystObjects::structure1().values.flatten
        objects = DoNotShowUntil::transform(objects)
        objects
    end
end