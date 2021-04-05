
# encoding: UTF-8

# -----------------------------------------------------------------------

class Todos

    # Todos::getStructure()
    def self.getStructure()
        IO.read("/Users/pascal/Desktop/Todo.txt")
            .lines
            .reduce([""]){|structure, line|
                if line[0, 2] == "[]" then
                    structure = structure + [line]
                    structure
                else
                    i = structure.size
                    t = structure[i-1]
                    t = t + line
                    structure[i-1] = t
                    structure
                end
            }
            .map{|text| text.strip }
            .select{|text| text.size > 0 }
    end

    # Todos::sendStructureToDisk(structure)
    def self.sendStructureToDisk(structure)
        File.open("/Users/pascal/Desktop/Todo.txt", "w"){|f| f.puts(structure.join("\n\n")) }
    end

    # Todos::applyNextTransformation(uuid)
    def self.applyNextTransformation(uuid)
        structure = Todos::getStructure().map{|text|
            if Digest::SHA1.hexdigest(text) == uuid then
                text = SectionsType0141::applyNextTransformationToText(text)
            end
            text
        }
        Todos::sendStructureToDisk(structure)
    end

    # Todos::edit(uuid)
    def self.edit(uuid)
        structure = Todos::getStructure().map{|text|
            if Digest::SHA1.hexdigest(text) == uuid then
                text = CatalystUtils::editTextSynchronously(text)
            end
            text
        }
        Todos::sendStructureToDisk(structure)
    end

    # Todos::ns16s()
    def self.ns16s()
        Todos::getStructure()
            .map
            .with_index{|text, i|
                uuid = Digest::SHA1.hexdigest(text)
                announce = i == 0 ? "todo:\n#{text.lines.first(3).map{|line| "            #{line}"}.join() + "\n\n"}" : "todo: #{uuid}"
                {
                    "uuid"     => uuid,
                    "announce" => announce,
                    "lambda"   => lambda{ 

                        system("clear")
                        puts text.green

                        context = {"uuid" => uuid}
                        actions = [
                            ["[]", "[] Next transformation", lambda{|context, command|
                                uuid = context["uuid"]
                                Todos::applyNextTransformation(uuid)
                            }],
                            ["edit", "edit", lambda{|context, command|
                                uuid = context["uuid"]
                                Todos::edit(uuid)
                            }],
                            ["++", "++ (postpone today by one hour)", lambda{|context, command|
                                uuid = context["uuid"]
                                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                            }],
                        ]

                        returnvalue = Interpreting::interpreter(context, actions, {
                            "displayHelpInLineAtIntialization" => true
                        })
                    }
                }
            }
    end
end
