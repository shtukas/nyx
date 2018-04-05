#!/usr/bin/ruby

# encoding: UTF-8

require 'drb/drb'
require 'thread'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require "/Galaxy/local-resources/Ruby-Libraries/SetsOperator.rb"
=begin
    SetsOperator::insert(repositorylocation or nil, setuuid, valueuuid, value)
    SetsOperator::getOrNull(repositorylocation or nil, setuuid, valueuuid)
    SetsOperator::delete(repositorylocation or nil, setuuid, valueuuid)
    SetsOperator::values(repositorylocation or nil, setuuid)
=end

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
        status = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}", defaultValue))
        status['is-running']
    end

    def self.startUnixtimeOrNull(uid)
        defaultValue = '{"is-running":false}'
        status = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}", defaultValue))
        if status['is-running'] then
            status['starttime']
        else
            nil
        end
    end

    def self.start(uid)
        return if Chronos::isRunning(uid)
        status = {"is-running"=>true,"starttime"=>Time.new.to_i}
        KeyValueStore::set(nil, "CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}", JSON.generate(status))
    end

    def self.stop(uid) # stop a run and returns the time spent running in seconds 
        return if !Chronos::isRunning(uid)
        status1 = JSON.parse(KeyValueStore::getOrNull(nil, "CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}"))
        status2 = {"is-running"=>false}
        KeyValueStore::set(nil, "CEE6080B-63DA-4FE6-8CC9-94DDBB58B0DD:#{uid}", JSON.generate(status2))
        Time.new.to_i - status1['starttime']
    end

    def self.addTimespan(uid,timespan)
        object = {
            "unixtime" => Time.new.to_i,
            "timespan" => timespan
        }
        SetsOperator::insert(nil, "f0da0e03-0ae9-44ce-9315-d870d4e2e851:#{uid}", SecureRandom.hex, object)
    end

    def self.timepackets(uid)
        SetsOperator::values(nil, "f0da0e03-0ae9-44ce-9315-d870d4e2e851:#{uid}")
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
