#!/usr/bin/ruby

require 'json'

require 'date'

require 'find'

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

require "/Galaxy/LucilleOS/Misc-Resources/Ruby-Libraries/LucilleCore.rb"

require "/Galaxy/LucilleOS/Misc-Resources/Ruby-Libraries/xstore.rb"
=begin

    Xcache::set(key, value)
    Xcache::getOrNull(key)
    Xcache::getOrDefaultValue(key, defaultValue)
    Xcache::destroy(key)

    XcacheSets::values(setuid)
    XcacheSets::insert(setuid, valueuid, value)
    XcacheSets::remove(setuid, valueuid)

    XStore::set(repositorypath, key, value)
    XStore::getOrNull(repositorypath, key)
    XStore::getOrDefaultValue(repositorypath, key, defaultValue)
    XStore::destroy(repositorypath, key)

    XStoreSets::values(repositorypath, setuid)
    XStoreSets::insert(repositorypath, setuid, valueuid, value)
    XStoreSets::remove(repositorypath, setuid, valueuid)

    Xcache and XStore have identical interfaces
    Xcache is XStore with a repositorypath defaulting to x-space

=end

require 'drb/drb'

# -------------------------------------------------------------------------

PATH_TO_SEQUENCES_FOLDER = "/Galaxy/DataBank/Catalyst/Finite-Bursts"

=begin
(schedule) {
    "begin" : "2018-02-03 18:11:10 +0000",
    "end" : "2018-02-04 18:11:10 +0000"
}
=end

class FiniteBurstsUtils
    def self.sequence_folderpaths()
        Dir.entries(PATH_TO_SEQUENCES_FOLDER)
            .select{|filename| filename[0, 1] != "." }
            .map{|filename| "#{PATH_TO_SEQUENCES_FOLDER}/#{filename}"}
    end
    def self.ideal_number_of_lines_done(schedule, numberoflines)
        beginunixtime = DateTime.parse(schedule['begin']).to_time.to_i
        endunixtime = DateTime.parse(schedule['end']).to_time.to_i
        speed_lines_per_second = (numberoflines+1).to_f/(endunixtime-beginunixtime)
        time_since_begin = Time.new.to_i - beginunixtime
        ideal_lines_since_begin = time_since_begin*speed_lines_per_second
        ideal_lines_since_begin
    end
    def self.get_uuid(folderpath)
        uuidfilepath = "#{folderpath}/uuid"
        if !File.exists?(uuidfilepath) then
            File.open(uuidfilepath, 'w'){|f| f.write(SecureRandom.hex(4)) }
        end
        IO.read(uuidfilepath).strip
    end
    def self.get_sequences()
        FiniteBurstsUtils::sequence_folderpaths()
            .map{|folderpath|  
                object = {}
                object['folderpath']    = folderpath
                object['uuid']          = FiniteBurstsUtils::get_uuid(folderpath)
                object['lines']         = IO.read("#{folderpath}/sequence.txt").lines.to_a.map{|line| line.strip }.select{|line| line.size>0 }
                object['schedule']      = JSON.parse(IO.read("#{folderpath}/schedule.json"))
                object['initial-count'] = IO.read("#{folderpath}/initial-count").to_i
                object['ideal-done-count'] = FiniteBurstsUtils::ideal_number_of_lines_done(object['schedule'], object['initial-count'])
                object['current-done-count'] = object['initial-count'] - object['lines'].count
                object
            }
    end
    def self.commands(itemuuid)
        if Xcache::getOrNull("61c39302-4427-4668-8d44-7f4f9ddd6abd:#{itemuuid}")=='true' then
            ['stop', 'done']
        else
            ['start', 'done']
        end
    end
end

# -------------------------------------------------------------------------

class FiniteBursts

    # FiniteBursts::getCatalystObjects()
    def self.getCatalystObjects()
        objects = []
        FiniteBurstsUtils::get_sequences()
            .each{|sequenceobject|
                if sequenceobject['lines'].count!=0 then
                    line = sequenceobject['lines'].first
                    uuid = Digest::SHA1.hexdigest("#{sequenceobject['uuid']}:#{line}")[0, 8]
                    isrunning = Xcache::getOrNull("61c39302-4427-4668-8d44-7f4f9ddd6abd:#{uuid}")=='true'
                    metric = [ 0.3*Math.exp( ( sequenceobject['ideal-done-count'] - sequenceobject['current-done-count'] ).to_f / sequenceobject['initial-count'] ), 0.4 ].min
                    metric = isrunning ? 2.2 : metric
                    announce = "[#{uuid}] (#{"%.3f" % metric}) finite burst: #{File.basename(sequenceobject['folderpath'])}, item: #{line}"
                    item = {}
                    item['uuid']       = uuid
                    item['metric']     = metric
                    item['announce']   = announce
                    item['commands']   = FiniteBurstsUtils::commands(uuid)
                    item['default-commands'] = isrunning ? ['stop'] : ['start']
                    item['command-interpreter'] = lambda {|object, command| FiniteBursts::interpreter(object, command) }
                    item['folderpath'] = sequenceobject['folderpath']
                    objects << item
                else
                    object = {}
                    object['uuid'] = SecureRandom.hex
                    object['metric'] = 1
                    object['announce'] = "finite bursts: You are done with sequence: #{sequenceobject['folderpath']}"
                    object["commands"] = []
                    object["command-interpreter"] = lambda {|object, command| }
                    object['folderpath'] = sequenceobject['folderpath']
                    objects << object                  
                end
            }
        objects
    end

    # FiniteBursts::interpreter(object, command)
    def self.interpreter(object, command)
        if command=='start' then
            Xcache::set("61c39302-4427-4668-8d44-7f4f9ddd6abd:#{object['uuid']}",'true')
        end
        if command=='stop' then
            Xcache::set("61c39302-4427-4668-8d44-7f4f9ddd6abd:#{object['uuid']}",'false')
        end
        if command=='done' then
            if Xcache::getOrNull("61c39302-4427-4668-8d44-7f4f9ddd6abd:#{object['uuid']}")=='true' then
                FiniteBursts::interpreter(object, 'stop')
            end
            filepath = "#{object['folderpath']}/sequence.txt"
            newlines = IO.read(filepath).lines.to_a.drop(1)
            File.open(filepath,'w'){|f| f.write(newlines.join())}
        end
    end
end

