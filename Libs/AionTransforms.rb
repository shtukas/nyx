class AionTransforms

    # AionTransforms::extractTopName(operator, rootnhash)
    def self.extractTopName(operator, rootnhash)
        AionCore::getAionObjectByHash(operator, rootnhash)["name"]
    end

    # AionTransforms::rewriteThisAionRootWithNewTopName(operator, rootnhash, name1)
    def self.rewriteThisAionRootWithNewTopName(operator, rootnhash, name1)

        # nb: name1 can have an extension

        aionObject = AionCore::getAionObjectByHash(operator, rootnhash)
        name2 = aionObject["name"]

        # bn: name2 can also have an extension.

        # name1 : name we want
        # name2 : name we have, possibly with an .extension

        namef = (lambda{|name1, name2|
            if File.extname(name1) != "" and File.extname(name2) != "" and File.extname(name1) == File.extname(name2) then
                return name1
            end
            if File.extname(name1) != "" and File.extname(name2) != "" and File.extname(name1) != File.extname(name2) then
                puts "name1: #{name1}"
                puts "name2: #{name2}"
                raise "(error: 80102c05-5181-44be-9b45-8a0b91ebb67b)"
            end
            if File.extname(name1) != "" and File.extname(name2) == "" then
                puts "name1: #{name1}"
                puts "name2: #{name2}"
                raise "(error: b9ed4f40-e3e8-4c78-98e6-d8e04ac62349)"
            end
            if File.extname(name1) == "" and File.extname(name2) != "" then
                return "#{name1}#{File.extname(name2)}"
            end
            if File.extname(name1) == "" and File.extname(name2) == "" then
                return name1
            end
        }).call(name1, name2)

        aionObject["name"] = namef

        blob = JSON.generate(aionObject)
        operator.commitBlob(blob)
    end
end
