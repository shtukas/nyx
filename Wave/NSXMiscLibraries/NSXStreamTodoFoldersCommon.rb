#!/usr/bin/ruby

# encoding: UTF-8

class NSXStreamTodoFoldersCommon

    # NSXStreamTodoFoldersCommon::metric1(ordinal, schedule, generalRuntimePoints, isRunning)
    def self.metric1(ordinal, schedule, generalRuntimePoints, isRunning)
        return 1 if isRunning
        m0 = Math.exp(-ordinal.to_f/100).to_f/100
        if schedule.nil? then
            m1 = NSXMiscUtils::runtimePointsToMetricShift(generalRuntimePoints, 86400, 12*3600)
            return (0.50 + m0 + m1)
        end
        if schedule["type"] == "inbox" then
            return (0.75 + m0)
        end
        raise "4f2e-43a5"
    end
end