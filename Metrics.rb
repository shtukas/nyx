
# encoding: UTF-8

# require_relative "Metrics.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# -----------------------------------------------------------------

class Metrics
    # Metrics::metricNX1RequiredValueAndThenFall(basemetric, currentValue, targetValue)
    def self.metricNX1RequiredValueAndThenFall(basemetric, currentValue, targetValue)
        ratioDone = currentValue.to_f/targetValue
        if ratioDone < 1 then
            basemetric - 0.001*ratioDone
        else
            0.2 + (basemetric-0.2)*Math.exp( -20*(ratioDone-1) ) # exp(-1) at ratio: 1.05 ; +5% over target
        end
    end

    # Metrics::metricNX2OnGoing(basemetric, pinguuid)
    def self.metricNX2OnGoing(basemetric, pinguuid)
        # We look 7 samples over the past week.
        # Below 30 minutes per 24 hours, we are at basemetric , then we fall to zero
        bestratio = Ping::bestTimeRatioOverPeriod7Samples(pinguuid, 86400*7)
        targetRatio = (60*30).to_f/86400
        if bestratio < targetRatio then
            basemetric
        else
            coefficient = (bestratio-targetRatio).to_f/targetRatio
            # If bestratio = targetRatio, then coefficient is 0
            # if bestratio is twice targetRatio, then coeffient is 1
            0.2 + (basemetric-0.2)*Math.exp(-coefficient)
        end
    end
end
