
# encoding: UTF-8

# -----------------------------------------------------------------------

class WorkTxt

    # WorkTxt::filepath()
    def self.filepath()
        "/Users/pascal/Desktop/Work.txt"
    end

    # WorkTxt::getStructure(filepath)
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

    # WorkTxt::sendStructureToDisk(filepath, structure)
    def self.sendStructureToDisk(filepath, structure)
        File.open(filepath, "w"){|f| f.puts(structure.join("\n\n")) }
    end

    # WorkTxt::applyNextTransformation(filepath, uuid)
    def self.applyNextTransformation(filepath, uuid)
        structure = WorkTxt::getStructure(filepath).map{|text|
            if WorkTxt::determineTextUUID(text) == uuid then
                text = SectionsType0141::applyNextTransformationToText(text)
            end
            text
        }
        WorkTxt::sendStructureToDisk(filepath, structure)
    end

    # WorkTxt::edit(filepath, uuid)
    def self.edit(filepath, uuid)
        structure = WorkTxt::getStructure(filepath).map{|text|
            if WorkTxt::determineTextUUID(text) == uuid then
                text = Utils::editTextSynchronously(text)
            end
            text
        }
        WorkTxt::sendStructureToDisk(filepath, structure)
    end

    # WorkTxt::delete(filepath, uuid)
    def self.delete(filepath, uuid)
        structure = WorkTxt::getStructure(filepath).select{|text| WorkTxt::determineTextUUID(text) != uuid }
        WorkTxt::sendStructureToDisk(filepath, structure)
    end

    # WorkTxt::determineTextUUID(text)
    def self.determineTextUUID(text)
        getFragmentUuidOrNull = lambda {|fragment|
            v1 = KeyValueStore::getOrNull(nil, "4a4d8f20-1b36-4c33-abdf-d9797f9fd4c7:#{Utils::nDaysInTheFuture(0)}:#{fragment}")
            if v1 then
                return v1
            end
            v2 = KeyValueStore::getOrNull(nil, "4a4d8f20-1b36-4c33-abdf-d9797f9fd4c7:#{Utils::nDaysInTheFuture(-1)}:#{fragment}")
            if v2 then 
                KeyValueStore::set(nil, "4a4d8f20-1b36-4c33-abdf-d9797f9fd4c7:#{Utils::nDaysInTheFuture(0)}:#{fragment}", v2)
                return v2
            end
            nil
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

        makeFragments.call(text).each{|fragment| KeyValueStore::set(nil, "4a4d8f20-1b36-4c33-abdf-d9797f9fd4c7:#{Utils::nDaysInTheFuture(0)}:#{fragment}", uuid) }

        uuid
    end

    # WorkTxt::ns16s()
    def self.ns16s()
        WorkTxt::getStructure(WorkTxt::filepath())
            .map
            .with_index{|text, i|
                uuid = WorkTxt::determineTextUUID(text)
                announce = (lambda{
                    if text.lines.size == 1 then
                        return "(#{"%5.3f" % BankExtended::recoveredDailyTimeInHours(uuid)}) #{"[work]".green} #{text.strip}"
                    end
                    "(#{"%5.3f" % BankExtended::recoveredDailyTimeInHours(uuid)}) #{"[work]".green}\n#{text.lines.first(3).map{|line| "             #{line}"}.join() + "\n\n"}".strip
                }).call()
                {
                    "uuid"     => uuid,
                    "announce" => announce,
                    "start"    => lambda{ 

                        filepath = WorkTxt::filepath()

                        startUnixtime = Time.new.to_f

                        thr = Thread.new {
                            sleep 3600
                            loop {
                                Utils::onScreenNotification("Catalyst", "Todo running for more than an hour")
                                sleep 60
                            }
                        }

                        loop {

                            text = WorkTxt::getStructure(filepath)
                                .select{|text| 
                                    WorkTxt::determineTextUUID(text) == uuid
                                }
                                .first

                            break if text.nil?

                            puts "[todo]"
                            puts text.green

                            puts "[] (next transformation) | edit | ++ (postpone today by one hour) | done | >quarks".yellow

                            command = LucilleCore::askQuestionAnswerAsString("> ")

                            break if command == ""

                            if Interpreting::match("[]", command) then
                                WorkTxt::applyNextTransformation(filepath, uuid)
                                next
                            end

                            if Interpreting::match("edit", command) then
                                WorkTxt::edit(filepath, uuid)
                                next
                            end

                            if Interpreting::match("++", command) then
                                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                                break
                            end

                            if Interpreting::match("done", command) then
                                WorkTxt::delete(filepath, uuid)
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

                                marbleFilepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles/quarks/#{Quarks::computeLowL22()}.marble"

                                marble = Marbles::issueNewEmptyMarble(marbleFilepath)

                                marble.set("uuid", SecureRandom.uuid)
                                marble.set("unixtime", Time.new.to_i)
                                marble.set("domain", "quarks")
                                marble.set("description", description)

                                marble.set("type", "Text")
                                payload = MarbleElizabeth.new(marble.filepath()).commitBlob(text)
                                marble.set("payload", payload)

                                WorkTxt::delete(filepath, uuid)
                                break
                            end
                        }

                        thr.exit

                        timespan = Time.new.to_f - startUnixtime

                        puts "Time since start: #{Time.new.to_f - startUnixtime}"

                        timespan = [timespan, 3600*2].min

                        puts "putting #{timespan} seconds to todo: #{uuid}"
                        Bank::put(uuid, timespan)

                        Synthetic::register(Time.now.utc.iso8601, uuid, timespan)

                    },
                    "done"   => lambda{
                        puts text.green
                        WorkTxt::delete(filepath, uuid)
                    },
                    "isTodo"   => true,
                    "filepath" => filepath
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end
end
