
# encoding: UTF-8

class PhageInternals

    # PhageInternals::variantsToUniqueVariants(variants)
    def self.variantsToUniqueVariants(variants)
        answer = []
        phage_uuids_recorded = {}
        variants.each{|variant|
            next if phage_uuids_recorded[variant["phage_uuid"]]
            answer << variant
            phage_uuids_recorded[variant["phage_uuid"]] = true
        }
        answer
    end

    # PhageInternals::variantsToObjects(variants)
    def self.variantsToObjects(variants)
        higestOfTwo = lambda {|o1Opt, o2|
            if o1Opt.nil? then
                return o2
            end
            o1 = o1Opt
            if o1["phage_time"] < o2["phage_time"] then
                o2
            else
                o1
            end
        }
        projection = {}
        variants.each{|variant|
            projection[variant["uuid"]] = higestOfTwo.call(projection[variant["uuid"]], variant)
        }
        projection.values.select{|object| object["phage_alive"] }
    end

end
