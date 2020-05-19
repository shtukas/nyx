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

=begin
{
    "datapointuuid": "aedbda15-4227-4652-9e4b-b443d38da538",
    "creationTimestamp": 9
}
=end

class OpenCycles
    # OpenCycles::getOpenCyclesItems()
    def self.getOpenCyclesItems()
        Dir.entries("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles")
            .select{|filename| filename[-5, 5] == '.json' }
            .map{|filename| JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{filename}")) }
            .sort{|d1, d2| d1["creationTimestamp"] <=> d2["creationTimestamp"] }
    end
end


