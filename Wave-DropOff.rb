#!/usr/bin/ruby

# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "net/http"
require "uri"

require 'json'

require 'date'

require 'colorize'

require "/Galaxy/LucilleOS/Misc-Resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Wave.rb"

require_relative "CatalystCore.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require_relative "Wave-Emails.rb"

# -------------------------------------------------------------------------------------

CATALYST_DROPOFF_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Wave-DropOff"

class DropOff
    def self.collect_objects()
        Dir.entries(CATALYST_DROPOFF_FOLDERPATH)
            .select{|filename| filename[0, 1] != '.' }
            .map{|filename| "#{CATALYST_DROPOFF_FOLDERPATH}/#{filename}" }
            .each{|sourcelocation|
                uuid = SecureRandom.hex(4)
                description = 
                    if sourcelocation[-4,4] == '.txt' and IO.read(sourcelocation).lines.to_a.size == 1 then
                        IO.read(sourcelocation).strip
                    else
                        File.basename(sourcelocation)
                    end
                schedule = WaveSchedules::makeScheduleObjectNew()
                folderpath = WaveTimelineUtils::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
                File.open("#{folderpath}/catalyst-description.txt", 'w') {|f| f.write(description) }
                WaveTimelineUtils::writeScheduleToDisk(uuid,schedule)
                if File.file?(sourcelocation) then
                    FileUtils.cp(sourcelocation,folderpath)
                else
                    FileUtils.cp_r(sourcelocation,folderpath)
                end
                File.open("#{folderpath}/wave-target-filename.txt", 'w') {|f| f.write(File.basename(sourcelocation)) }
                LucilleCore::removeFileSystemLocation(sourcelocation)
            }
    end
end
