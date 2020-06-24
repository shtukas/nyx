
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Metrics.rb"

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
end
