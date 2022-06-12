
# encoding: UTF-8

# -----------------------------------------------------------------------

class Genealogy

    # Genealogy::array1IsSubarrayOfArray2(array1, array2)
    def self.array1IsSubarrayOfArray2(array1, array2)
        array1.all?{|id| array2.include?(id) }
    end

    # Genealogy::firstIsStrictAncestorOfSecond(first, second)
    def self.firstIsStrictAncestorOfSecond(first, second)
        # Meaning that second can replace first
        b1 = Genealogy::array1IsSubarrayOfArray2(first["lxHistory"], second["lxHistory"])
        b2 = (first["lxHistory"].size < second["lxHistory"].size)
        b1 and b2
    end

    # Genealogy::areEquivalent(first, second)
    def self.areEquivalent(first, second)
        Genealogy::array1IsSubarrayOfArray2(first["lxHistory"], second["lxHistory"]) and Genealogy::array1IsSubarrayOfArray2(second["lxHistory"], first["lxHistory"])
    end
end
