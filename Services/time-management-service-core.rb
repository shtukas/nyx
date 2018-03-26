#!/usr/bin/ruby

# encoding: UTF-8

require 'drb/drb'
require 'thread'

require "/Galaxy/local-resources/Ruby-Libraries/xstore.rb"
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

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# ---------------------------------------------------------------------------------------

# Chronos::isRunning(uid)
# Chronos::startUnixtimeOrNull(uid)
# Chronos::start(uid)
# Chronos::stop(uid)
# Chronos::addTimespan(uid,timespan)
# Chronos::totalTimespanAfterThisUnixtime(uid,horizonunixtime)
# Chronos::timepackets(uid)
# Chronos::metric2(uid, referencePeriodInDays, commitmentPerReferencePeriodInHours, metricAtFullyDone, metricAtZeroDone, metricRunning)
# Chronos::getEntityTotalTimespanForPeriod(entityuid, referencePeriodInDays)

class Chronos

    def self.isRunning(uid)
        defaultValue = '{"is-running":false}'
        status = JSON.parse(Xcache::getOrDefaultValue("CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}", defaultValue))
        status['is-running']
    end

    def self.startUnixtimeOrNull(uid)
        defaultValue = '{"is-running":false}'
        status = JSON.parse(Xcache::getOrDefaultValue("CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}", defaultValue))
        if status['is-running'] then
            status['starttime']
        else
            nil
        end
    end

    def self.start(uid)
        return if Chronos::isRunning(uid)
        status = {"is-running"=>true,"starttime"=>Time.new.to_i}
        Xcache::set("CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}", JSON.generate(status))
    end

    def self.stop(uid) # stop a run and returns the time spent running in seconds 
        return if !Chronos::isRunning(uid)
        status1 = JSON.parse(Xcache::getOrNull("CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}"))
        status2 = {"is-running"=>false}
        Xcache::set("CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}", JSON.generate(status2))
        Time.new.to_i - status1['starttime']
    end

    def self.addTimespan(uid,timespan)
        object = {
            "unixtime" => Time.new.to_i,
            "timespan" => timespan
        }
        XcacheSets::insert("f0da0e03-0ae9-44ce-9315-d870d4e2e851:#{uid}", SecureRandom.hex, object)
    end

    def self.timepackets(uid)
        XcacheSets::values("f0da0e03-0ae9-44ce-9315-d870d4e2e851:#{uid}")
    end

    def self.metric2(uid, referencePeriodInDays, commitmentPerReferencePeriodInHours, metricAtFullyDone, metricAtZeroDone, metricRunning)
        # When running, value is metricRunning
        # Between {zero done} and {totally done}, moves from metricAtZeroDone to metricAtFullyDone
        # Above {totally done} jumps 0.36*metricAtFullyDone and then collapse to zero
        return metricRunning if Chronos::isRunning(uid)
        doneTimeInSeconds = Chronos::getEntityTotalTimespanForPeriod(uid, referencePeriodInDays)
        totalTimeInSeconds = commitmentPerReferencePeriodInHours*3600
        if doneTimeInSeconds <= totalTimeInSeconds then
            metricAtZeroDone - (metricAtZeroDone-metricAtFullyDone)*(doneTimeInSeconds.to_f/totalTimeInSeconds)
        else
            metricAtFullyDone*Math.exp( -(doneTimeInSeconds.to_f/totalTimeInSeconds) )
        end
    end

    def self.getEntityTotalTimespanForPeriod(uid, referencePeriodInDays)
        answer = Chronos::timepackets(uid)
            .select{|timepacket| ( Time.new.to_i - timepacket['unixtime'] ) < referencePeriodInDays*86400 }
            .map{|timepacket| timepacket['timespan'] }
            .inject(0, :+)
        if Chronos::isRunning(uid) then
            answer = answer + (Time.new.to_i - Chronos::startUnixtimeOrNull(uid))
        end
        answer
    end

end
