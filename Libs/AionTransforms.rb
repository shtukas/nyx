class AionTransforms

    # AionTransforms::extractTopName(operator, rootnhash)
    def self.extractTopName(operator, rootnhash)
        AionCore::getAionObjectByHash(operator, rootnhash)["name"]
    end

    # AionTransforms::rewriteThisAionRootWithNewTopName(operator, rootnhash, name1)
    def self.rewriteThisAionRootWithNewTopName(operator, rootnhash, name1)

        # name1 can have an extension

        aionObject = AionCore::getAionObjectByHash(operator, rootnhash)
        name2 = aionObject["name"]

        # name2 can also have an extension.

        # name1 : name we want
        # name2 : name we have, possibly with an .extension

        namef = (lambda{|name1, name2|

            aBetterExtension = lambda {|na|
                if na.size < 10 then
                    return File.extname(na)
                end
                File.extname(na[-10, 10])
            }

            if aBetterExtension.call(name1) != "" and aBetterExtension.call(name2) != "" and aBetterExtension.call(name1) == aBetterExtension.call(name2) then
                return name1
            end
            if aBetterExtension.call(name1) != "" and aBetterExtension.call(name2) != "" and aBetterExtension.call(name1) != aBetterExtension.call(name2) then
                puts "name1: #{name1}"
                puts "name2: #{name2}"
                raise "(error: 80102c05-5181-44be-9b45-8a0b91ebb67b)"
            end
            if aBetterExtension.call(name1) != "" and aBetterExtension.call(name2) == "" then
                puts "name1: #{name1}"
                puts "name2: #{name2}"
                raise "(error: b9ed4f40-e3e8-4c78-98e6-d8e04ac62349)"
            end
            if aBetterExtension.call(name1) == "" and aBetterExtension.call(name2) != "" then
                return "#{name1}#{File.extname(name2)}"
            end
            if aBetterExtension.call(name1) == "" and aBetterExtension.call(name2) == "" then
                return name1
            end
        }).call(name1, name2)

        aionObject["name"] = namef

        blob = JSON.generate(aionObject)
        operator.commitBlob(blob)
    end
end
