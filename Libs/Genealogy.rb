# encoding: UTF-8

class Genealogy

    # Genealogy::array1IsSubArrayOfArray2(array1, array2)
    def self.array1IsSubArrayOfArray2(array1, array2)
        array1.all?{|x| array2.include?(x) }
    end

    # Genealogy::object1IsAncestrorOfObject2(object1, object2)
    def self.object1IsAncestrorOfObject2(object1, object2)
        Genealogy::array1IsSubArrayOfArray2(object1["lxGenealogyAncestors"], object2["lxGenealogyAncestors"])
    end

    # Genealogy::object1ShouldBeReplacedByObject2(object1, object2)
    def self.object1ShouldBeReplacedByObject2(object1, object2)

        # Using the Genealogies
        b1 = Genealogy::object1IsAncestrorOfObject2(object1, object2)
        b2 = !Genealogy::object1IsAncestrorOfObject2(object2, object1)
        return true if (b1 and b2)

        # Using object identity
        o1 = object1.clone
        o2 = object2.clone
        o1.delete("lxGenealogyAncestors")
        o2.delete("lxGenealogyAncestors")
        o1.delete("variant")
        o2.delete("variant")
        if o1.to_s == o2.to_s then
            return true
        end

        false
    end
end
