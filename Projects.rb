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

# -------------------------------------------------------------------------------------

TODOLISTS_FOLDERPATH = "/Galaxy/DataBank/Projects"

class TimeComputations
    # TimeComputations::getListNumberOfHourPerWeek(listuuid)
    def self.getListNumberOfHourPerWeek(listuuid)
        value = Xcache::getOrDefaultValue("3bc9710f-c18d-4d48-bbf0-74be6a7091ea:#{listuuid}", "1")
        value.to_f
    end
    # TimeComputations::getListDoneTimeInSecondsDuringThePastNDays(listuuid, n)
    def self.getListDoneTimeInSecondsDuringThePastNDays(listuuid, n)
        unixtime = Time.new.to_i-86400*n
        DRbObject.new(nil, "druby://:10423").totalTimeSpanAfterUnixtime(listuuid, unixtime)
    end
    # TimeComputations::getProportionOfTimeDoneBasingOnThePastNDays(listuuid, n)
    def self.getProportionOfTimeDoneBasingOnThePastNDays(listuuid, n)
        timedoneInSeconds = TimeComputations::getListDoneTimeInSecondsDuringThePastNDays(listuuid, n)
        if DRbObject.new(nil, "druby://:10423").isRunning(listuuid) then
            startunixtime = DRbObject.new(nil, "druby://:10423").lastStartUnixtime(listuuid)
            timedoneInSeconds = timedoneInSeconds + ( Time.new.to_i - startunixtime )
        end
        timedoneInSeconds.to_f/((n.to_f/7)*TimeComputations::getListNumberOfHourPerWeek(listuuid)*3600)        
    end

    # TimeComputations::getProportionOfTimeDone(listuuid)
    def self.getProportionOfTimeDone(listuuid)
        (1..7).map{ |n| TimeComputations::getProportionOfTimeDoneBasingOnThePastNDays(listuuid, n) }.max
    end

    # TimeComputations::commands(listuuid)
    def self.commands(listuuid)
        DRbObject.new(nil, "druby://:10423").isRunning(listuuid) ? ['stop'] : ['start','set time']
    end

end

class ProjectsCore

    # ProjectsCore::getProjectsNames()
    def self.getProjectsNames()
        Dir.entries(TODOLISTS_FOLDERPATH)
            .select{|filename| filename[0, 1] != '.' }
    end

    # ProjectsCore::getProjectItem(listname)
    def self.getProjectItem(listname)
        Dir.entries("#{TODOLISTS_FOLDERPATH}/#{listname}")
            .select{|filename| filename[0, 1] != '.' }
    end

    # ProjectsCore::projectNameToUuid(listname)
    def self.projectNameToUuid(listname)
        uuidfilepath = "#{TODOLISTS_FOLDERPATH}/#{listname}/.todolistuuid"
        if !File.exists?(uuidfilepath) then
            File.open(uuidfilepath,'w'){|f| f.write(SecureRandom.hex) }
        end
        IO.read(uuidfilepath).strip
    end

    # ProjectsCore::projectNameToCatalystObject(listname)
    def self.projectNameToCatalystObject(listname)
        listuuid = ProjectsCore::projectNameToUuid(listname)
        hoursCommitmentPerWeek = Xcache::getOrDefaultValue("3bc9710f-c18d-4d48-bbf0-74be6a7091ea:#{listuuid}", "1").to_f
        metric = DRbObject.new(nil, "druby://:10423").metric(listuuid, hoursCommitmentPerWeek, 0.3, 2.1)
        Xcache::set("dd60d5ac-9fc1-4388-ad30-3cb92f954a61:#{listname}", listuuid)
        object = {}
        object['uuid'] = listuuid
        object['metric'] = metric
        object['announce'] = "           (#{"%.3f" % metric}) project folder: #{listname}"
        object['commands'] = TimeComputations::commands(listuuid)
        object['command-interpreter'] = lambda{|object, command| ProjectsInterface::interpreter(object, command) }
        object['listname'] = listname
        object
    end
end

class ProjectsInterface
    # ProjectsInterface::getCatalystObjects()
    def self.getCatalystObjects()
        ProjectsCore::getProjectsNames()
            .map{|listname|  
                ProjectsCore::projectNameToCatalystObject(listname)
            }
            .sort{|o1,o2| o1['metric']<=>o2['metric'] }
            .reverse
    end
    # ProjectsInterface::interpreter(object, command)
    def self.interpreter(object, command)
        if command=='start' then
            DRbObject.new(nil, "druby://:10423").start(object['uuid'])
        end
        if command=='stop' then
            DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(object['uuid'])
        end
        if command=='set time' then
            listuuid = object['uuid']
            weeklyTimeInHours = LucilleCore::askQuestionAnswerAsString("Weekly time in hours: ").to_f
            Xcache::set("3bc9710f-c18d-4d48-bbf0-74be6a7091ea:#{listuuid}", weeklyTimeInHours)
            puts "weekly commitment has been set to #{weeklyTimeInHours} hours"
        end
    end
end
