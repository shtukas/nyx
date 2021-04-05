
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
                text = Utils::editTextSynchronously(text)
            end
            text
        }
        Todos::sendStructureToDisk(structure)
    end

    # Todos::delete(uuid)
    def self.delete(uuid)
        structure = Todos::getStructure().select{|text| Digest::SHA1.hexdigest(text) != uuid }
        Todos::sendStructureToDisk(structure)
    end

    # Todos::ns16s()
    def self.ns16s()
        Todos::getStructure()
            .map
            .with_index{|text, i|
                uuid = Digest::SHA1.hexdigest(text)
                announce = "todo:\n#{text.lines.first(3).map{|line| "            #{line}"}.join() + "\n\n"}".strip
                {
                    "uuid"     => uuid,
                    "announce" => announce,
                    "lambda"   => lambda{ 

                        startUnixtime = Time.new.to_f

                        thr = Thread.new {
                            sleep 3600
                            loop {
                                Utils::onScreenNotification("Catalyst", "Todo running for more than an hour")
                                sleep 60
                            }
                        }

                        system("clear")
                        puts text.green

                        loop {
                            puts "[] (next transformation) | edit | ++ (postpone today by one hour) | done | >quarks".yellow

                            command = LucilleCore::askQuestionAnswerAsString("> ")

                            break if command == ""

                            if Interpreting::match("[]", command) then
                                Todos::applyNextTransformation(uuid)
                                break
                            end

                            if Interpreting::match("edit", command) then
                                Todos::edit(uuid)
                                break
                            end

                            if Interpreting::match("++", command) then
                                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                                break
                            end

                            if Interpreting::match("done", command) then
                                Todos::delete(uuid)
                                break
                            end

                            if Interpreting::match(">quarks", command) then

                                description = (lambda{
                                    if text.lines.size == 1 then
                                        text.strip
                                    else
                                        LucilleCore::askQuestionAnswerAsString("description: ")
                                    end
                                }).call()
                                element = NereidInterface::issueTextElement(description, text)
                                Quarks::issueQuarkUsingNereiduuidAndPlaceAtLowOrdinal(element["uuid"])
                                Todos::delete(uuid)
                                break
                            end
                        }

                        thr.exit

                        timespan = Time.new.to_f - startUnixtime

                        puts "Time since start: #{Time.new.to_f - startUnixtime}"

                        timespan = [timespan, 3600*2].min
                        puts "putting #{timespan} seconds to [todo]"
                        Bank::put("da2a8102-633b-4b1b-bf98-8eef3a5d8a8e", timespan)

                    },
                    "isTodo"   => true,
                }
            }
    end
end
