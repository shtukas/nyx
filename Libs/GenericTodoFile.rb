
# encoding: UTF-8

# -----------------------------------------------------------------------

class GenericTodoFile

    # GenericTodoFile::getStructure(filepath)
    def self.getStructure(filepath)
        IO.read(filepath)
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

    # GenericTodoFile::sendStructureToDisk(filepath, structure)
    def self.sendStructureToDisk(filepath, structure)
        File.open(filepath, "w"){|f| f.puts(structure.join("\n\n")) }
    end

    # GenericTodoFile::applyNextTransformation(filepath, uuid)
    def self.applyNextTransformation(filepath, uuid)
        structure = GenericTodoFile::getStructure(filepath).map{|text|
            if Digest::SHA1.hexdigest(text) == uuid then
                text = SectionsType0141::applyNextTransformationToText(text)
            end
            text
        }
        GenericTodoFile::sendStructureToDisk(filepath, structure)
    end

    # GenericTodoFile::edit(filepath, uuid)
    def self.edit(filepath, uuid)
        structure = GenericTodoFile::getStructure(filepath).map{|text|
            if Digest::SHA1.hexdigest(text) == uuid then
                text = Utils::editTextSynchronously(text)
            end
            text
        }
        GenericTodoFile::sendStructureToDisk(filepath, structure)
    end

    # GenericTodoFile::delete(filepath, uuid)
    def self.delete(filepath, uuid)
        structure = GenericTodoFile::getStructure(filepath).select{|text| Digest::SHA1.hexdigest(text) != uuid }
        GenericTodoFile::sendStructureToDisk(filepath, structure)
    end

    # GenericTodoFile::ns16s(announcePrefix, filepath)
    def self.ns16s(announcePrefix, filepath)
        GenericTodoFile::getStructure(filepath)
            .map
            .with_index{|text, i|
                uuid = Digest::SHA1.hexdigest(text)
                announce = (lambda{
                    if text.lines.size == 1 then
                        return "#{announcePrefix} #{text.strip}"
                    end
                    "#{announcePrefix}\n#{text.lines.first(3).map{|line| "             #{line}"}.join() + "\n\n"}".strip
                }).call()
                {
                    "uuid"     => uuid,
                    "announce" => announce,
                    "start"   => lambda{ 

                        startUnixtime = Time.new.to_f

                        thr = Thread.new {
                            sleep 3600
                            loop {
                                Utils::onScreenNotification("Catalyst", "Todo running for more than an hour")
                                sleep 60
                            }
                        }

                        puts "[todo]"
                        puts text.green

                        loop {
                            puts "[] (next transformation) | edit | ++ (postpone today by one hour) | done | >quarks".yellow

                            command = LucilleCore::askQuestionAnswerAsString("> ")

                            break if command == ""

                            if Interpreting::match("[]", command) then
                                GenericTodoFile::applyNextTransformation(filepath, uuid)
                                break
                            end

                            if Interpreting::match("edit", command) then
                                GenericTodoFile::edit(filepath, uuid)
                                break
                            end

                            if Interpreting::match("++", command) then
                                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                                break
                            end

                            if Interpreting::match("done", command) then
                                GenericTodoFile::delete(filepath, uuid)
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
                                GenericTodoFile::delete(filepath, uuid)
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
                    "done"   => lambda{
                        puts text.green
                        GenericTodoFile::delete(filepath, uuid)
                    },
                    "isTodo"   => true,
                    "filepath" => filepath,
                }
            }
    end
end
