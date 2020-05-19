#!/Users/pascal/.rvm/rubies/ruby-2.5.1/bin/ruby

# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"

# -----------------------------------------------------------------------------

class OpenCycles

    # OpenCycles::getOpenCyclesIds()
    def self.getOpenCyclesIds()
        Dir.entries("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles")
            .select{|filename| filename[0, 1] != '.' }
    end

    # OpenCycles::getDataPoints()
    def self.getDataPoints()
        OpenCycles::getOpenCyclesIds()
            .map{|uuid| DataPoints::getOrNull(uuid) }
            .compact
            .sort{|d1, d2| d1["creationTimestamp"] <=> d2["creationTimestamp"] }
    end
end


