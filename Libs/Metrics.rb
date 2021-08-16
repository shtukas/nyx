# encoding: UTF-8

class Metrics

    # Metrics::lift1(ns16s, starting)
    def self.lift1(ns16s, starting)
        cursor = -1
        ns16s.map{|ns16|
            cursor = cursor + 1
            ns16["metric"] = starting + cursor.to_f/1000
            ns16
        }
    end
end
