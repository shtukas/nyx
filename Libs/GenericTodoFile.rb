
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
            if GenericTodoFile::determineTextUUID(text) == uuid then
                text = SectionsType0141::applyNextTransformationToText(text)
            end
            text
        }
        GenericTodoFile::sendStructureToDisk(filepath, structure)
    end

    # GenericTodoFile::edit(filepath, uuid)
    def self.edit(filepath, uuid)
        structure = GenericTodoFile::getStructure(filepath).map{|text|
            if GenericTodoFile::determineTextUUID(text) == uuid then
                text = Utils::editTextSynchronously(text)
            end
            text
        }
        GenericTodoFile::sendStructureToDisk(filepath, structure)
    end

    # GenericTodoFile::delete(filepath, uuid)
    def self.delete(filepath, uuid)
        structure = GenericTodoFile::getStructure(filepath).select{|text| GenericTodoFile::determineTextUUID(text) != uuid }
        GenericTodoFile::sendStructureToDisk(filepath, structure)
    end

    # GenericTodoFile::determineTextUUID(text)
    def self.determineTextUUID(text)
        getFragmentUuidOrNull = lambda {|fragment|
            KeyValueStore::getOrNull(nil, "4a4d8f20-1b36-4c33-abdf-d9797f9fd4c7:#{fragment}")
        }

        makeFragments = lambda {|text|
            text.lines
        }

        candidatesUUIDs = makeFragments.call(text).map{|fragment| getFragmentUuidOrNull.call(fragment) }.compact
        
        if candidatesUUIDs.empty? then
            uuid = SecureRandom.uuid
        else
            counts = candidatesUUIDs.inject(Hash.new(0)) {|h,x| h[x]+=1; h}.sort
            uuid = counts.last[0]
        end

        makeFragments.call(text).each{|fragment| KeyValueStore::set(nil, "4a4d8f20-1b36-4c33-abdf-d9797f9fd4c7:#{fragment}", uuid) }

        uuid
    end

    # GenericTodoFile::ns16s(announcePrefix, filepath)
    def self.ns16s(announcePrefix, filepath)
        GenericTodoFile::getStructure(filepath)
            .map
            .with_index{|text, i|
                uuid = GenericTodoFile::determineTextUUID(text)
                announce = (lambda{
                    if text.lines.size == 1 then
                        return "(#{"%5.3f" % BankExtended::recoveredDailyTimeInHours(uuid)}) #{announcePrefix} #{text.strip}"
                    end
                    "(#{"%5.3f" % BankExtended::recoveredDailyTimeInHours(uuid)}) #{announcePrefix}\n#{text.lines.first(3).map{|line| "             #{line}"}.join() + "\n\n"}".strip
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
                                asteroid = AsteroidsInterface::issueTextAsteroid(description, text)
                                Quarks::issueQuarkUsingNereiduuidAndPlaceAtLowOrdinal(asteroid["uuid"])
                                GenericTodoFile::delete(filepath, uuid)
                                break
                            end
                        }

                        thr.exit

                        timespan = Time.new.to_f - startUnixtime

                        puts "Time since start: #{Time.new.to_f - startUnixtime}"

                        timespan = [timespan, 3600*2].min
                        puts "putting #{timespan} seconds to todo: #{uuid}"
                        Bank::put(uuid, timespan)

                    },
                    "done"   => lambda{
                        puts text.green
                        GenericTodoFile::delete(filepath, uuid)
                    },
                    "isTodo"   => true,
                    "filepath" => filepath,
                    "recoveryTimeInHours" => BankExtended::recoveredDailyTimeInHours(uuid)
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end
end
