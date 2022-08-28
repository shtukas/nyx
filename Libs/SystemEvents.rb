
# encoding: UTF-8

class SystemEvents

    # SystemEvents::process(event)
    def self.process(event)

        #puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(bank account has been updated)" then
            Ax39forSections::processEvent(event)
        end

        if event["mikuType"] == "(object has been logically deleted)" then
            #
        end

        if event["mikuType"] == "(element has been done for today)" then
            Ax39forSections::processEvent(event)
        end

        if event["mikuType"] == "(owner-elements-mapping-update)" then
            OwnerMapping::processEvent(event)
        end

        if event["mikuType"] == "(do not show until has been updated)" then
            Ax39forSections::processEvent(event)
        end

        if event["mikuType"] == "NxBankEvent" then
            Bank::processEvent(event)
        end

        if event["mikuType"] == "Bank-records" then
            Bank::processEvent(event)
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEvent(event)
        end

        if event["mikuType"] == "SetDoneToday" then
            DoneForToday::processEvent(event)
        end

        if event["mikuType"] == "NxDeleted" then
            DxF1::deleteObjectLogicallyNoEvents(event["objectuuid"])
        end

        if event["mikuType"] == "OwnerMapping" then
            OwnerMapping::processEvent(event)
        end

        if event["mikuType"] == "OwnerMapping-records" then
            OwnerMapping::processEvent(event)
        end

        if event["mikuType"] == "NetworkLinks-records" then
            NetworkLinks::processEvent(event)
        end
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        Machines::theOtherInstanceIds().each{|targetInstanceId|
            e = event.clone
            # We technically no longer need to mark the instance with the recipient's id
            # because we are dropping the event in the right folder, but we keep it anyway.
            e["targetInstance"] = targetInstanceId
            filepath = "#{Config::starlightCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.event.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(e)) }
        }
    end

    # SystemEvents::processAndBroadcast(event)
    def self.processAndBroadcast(event)
        SystemEvents::process(event)
        SystemEvents::broadcast(event)
    end

    # SystemEvents::publishDxF1OnCommsline(objectuuid)
    def self.publishDxF1OnCommsline(objectuuid)
        filepath = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        return if filepath.nil?
        Machines::theOtherInstanceIds().each{|targetInstanceId|
            targetFilepath = "#{Config::starlightCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.dxf1.sqlite3"
            FileUtils.cp(filepath, targetFilepath)
        }
    end

    # SystemEvents::flushChannel1()
    def self.flushChannel1()
        channel = "e0fba9fd-c00b-4d0c-b884-4f058ef87653"
        objectuuids = []
        loop {
            packet = Mercury2::readFirstOrNull(channel)
            break if packet.nil?
            break if (Time.new.to_i - packet["unixtime"]) < 60
            objectuuid = packet["objectuuid"]
            if !objectuuids.include?(objectuuid) then
                objectuuids << objectuuid
                puts "SystemEvents::publishDxF1OnCommsline(#{objectuuid})"
                SystemEvents::publishDxF1OnCommsline(objectuuid)
            end
            Mercury2::dequeue(channel)
        }
    end

    # SystemEvents::processCommsLine(verbose)
    def self.processCommsLine(verbose)
        # New style. Keep while we process the remaining items
        # We are reading from the instance folder
        instanceId = Config::get("instanceId")
        LucilleCore::locationsAtFolder("#{Config::starlightCommsLine()}/#{instanceId}")
            .each{|filepath1|
                next if !File.exists?(filepath1)
                next if File.basename(filepath1).start_with?(".")

                if File.basename(filepath1)[-11, 11] == ".event.json" then
                    e = JSON.parse(IO.read(filepath1))
                    if verbose then
                        puts "SystemEvents::processCommsLine: event: #{JSON.pretty_generate(e)}"
                    end
                    SystemEvents::process(e)
                    FileUtils.rm(filepath1)
                    next
                end

                if File.basename(filepath1)[-13, 13] == ".dxf1.sqlite3" then
                    if verbose then
                        puts "SystemEvents::processCommsLine: reading: #{File.basename(filepath1)}"
                    end
                    db1 = SQLite3::Database.new(filepath1)
                    db1.busy_timeout = 117
                    db1.busy_handler { |count| true }
                    db1.results_as_hash = true
                    db1.execute("select * from _dxf1_", []) do |row|

                        objectuuid = row["_objectuuid_"]
                        eventuuid  = row["_eventuuid_"]
                        eventTime  = row["_eventTime_"]
                        eventType  = row["_eventType_"]
                        attname    = row["_name_"]
                        attvalue   = row["_value_"]

                        next if DxF1::eventExistsAtDxF1(objectuuid, eventuuid)
                        if verbose then
                            puts "SystemEvents::processCommsLine: writing event: #{eventuuid} at file: #{File.basename(filepath1)}"
                        end

                        db2 = SQLite3::Database.new(DxF1::filepath(objectuuid))
                        db2.busy_timeout = 117
                        db2.busy_handler { |count| true }
                        db2.results_as_hash = true
                        # I am commenting the next one out because we have checked that the record doesn't exists
                        # db2.execute "delete from _dxf1_ where _eventuuid_=?", [eventuuid]
                        db2.execute "insert into _dxf1_ (_objectuuid_, _eventuuid_, _eventTime_, _eventType_, _name_, _value_) values (?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, eventType, attname, JSON.generate(attvalue)]
                        db2.close

                    end
                    db1.close
                    FileUtils.rm(filepath1)
                    next
                end

                raise "(error: 600967d9-e9d4-4612-bf62-f8cc4f616fd1) I do not know how to process file: #{filepath1}"
            }
    end
end
