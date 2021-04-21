
# encoding: UTF-8

# -----------------------------------------------------------------------

class WorkInterface

    # WorkInterface::determineTextUUID(text)
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

    # WorkInterface::ns16s()
    def self.ns16s()
        JSON.parse(`work api catalyst-preNS16s`)
            .map{|pns16|
                uuid = pns16["uuid"]
                {
                    "uuid"     => uuid,
                    "announce" => "(#{"%5.3f" % BankExtended::recoveredDailyTimeInHours(uuid)}) #{"[work]".green} #{pns16["description"]}",
                    "start"    => lambda {

                        startUnixtime = Time.new.to_f

                        thr = Thread.new {
                            sleep 3600
                            loop {
                                Utils::onScreenNotification("Catalyst", "Todo (work) running for more than an hour")
                                sleep 60
                            }
                        }

                        loop {

                            # This could be our re-entry in the loop after edition. We might want an updated object

                            begin
                                pns16 = JSON.parse(`work api catalyst-preNS16 #{pns16["uuid"]}`)
                            rescue
                            end

                            puts "[work] #{pns16["description"]}".green
                            if pns16["text"].strip.size > 0 then
                                puts ""
                                puts "------------------------------------".green
                                puts pns16["text"].green
                                puts "------------------------------------".green
                                puts ""
                            end


                            puts "[] (next transformation) | edit | ++ (postpone today by one hour) | done".yellow

                            command = LucilleCore::askQuestionAnswerAsString("> ")

                            break if command == ""

                            if Interpreting::match("[]", command) then
                                system("work api #{uuid} []")
                                next
                            end

                            if Interpreting::match("edit", command) then
                                system("work api #{uuid} edit")
                                next
                            end

                            if Interpreting::match("++", command) then
                                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                                break
                            end

                            if Interpreting::match("done", command) then
                                system("work api #{uuid} done")
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
                    "done" => lambda {
                        system("work api #{uuid} done")
                    }
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"])}
    end
end
