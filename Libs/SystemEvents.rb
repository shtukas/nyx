
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

        if event["mikuType"] == "AttributeUpdate" then
            objectuuid = event["objectuuid"]
            eventuuid  = event["eventuuid"]
            eventTime  = event["eventTime"]
            attname    = event["attname"]
            attvalue   = event["attvalue"]
            DxF1::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
            begin
                # This cane fail when we are using a new program, which doesn't expect old mikuTypes 
                # (for instance generic-description is failing)
                # on data that is still old.
                TheIndex::updateIndexAtObjectAttempt(objectuuid)
            rescue
            end
        end

        if event["mikuType"] == "XSyncStep0-a369" then
            # We are sending this to tell the recipient that we want to know what they have
            SystemEvents::broadcast({
                "mikuType" => "XSyncStep1-93b7",
                "sourceId" => Config::get("instanceId"),
            })
        end

        if event["mikuType"] == "XSyncStep1-93b7" then
            # We are sending this to tell the recipient what they have
            callerId = event["sourceId"]
            SystemEvents::sendTo({
                "mikuType"                  => "XSyncStep2-e6db",
                "sourceId"                  => Config::get("instanceId"),
                "nx1915s"                   => DxF1Extended::nx1915s(),
                "bankEventsuuids"           => Bank::eventuuids(),
                "elementToOwnerEventsuuids" => OwnerMapping::eventuuids(),
                "networkLinksEventsuuids"   => NetworkLinks::eventuuids()
            }, callerId)
        end

        if event["mikuType"] == "XSyncStep2-e6db" then
            # We are sending this to tell the receipient what we want
            callerId = event["sourceId"]
            remoteNx1915s = event["nx1915s"]
            remoteBankEventsuuids = event["bankEventsuuids"]
            remoteElementToOwnerEventsuuids = event["elementToOwnerEventsuuids"]
            remoteNetworkLinksEventsuuids = event["networkLinksEventsuuids"]
            SystemEvents::sendTo({
                "mikuType"                  => "XSyncStep3-b82e",
                "sourceId"                  => Config::get("instanceId"),
                "nx1915s"                   => DxF1Extended::nx1915Wanted(remoteNx1915s),
                "bankEventsuuids"           => remoteBankEventsuuids - Bank::eventuuids(),
                "elementToOwnerEventsuuids" => remoteElementToOwnerEventsuuids - OwnerMapping::eventuuids(),
                "networkLinksEventsuuids"   => remoteNetworkLinksEventsuuids - NetworkLinks::eventuuids()
            }, callerId)
        end

        if event["mikuType"] == "XSyncStep3-b82e" then
            # We are sending this to tell the receipient what we want
            callerId = event["sourceId"]
            nx1915s = event["nx1915s"]
            bankEventsuuids = event["bankEventsuuids"]
            elementToOwnerEventsuuids = event["elementToOwnerEventsuuids"]
            networkLinksEventsuuids = event["networkLinksEventsuuids"]

            nx1915s.each{|nx1915|
                objectuuid = nx1915["objectuuid"]
                puts "SystemEvents::publishDxF1OnCommsline(#{objectuuid})"
                SystemEvents::publishDxF1OnCommsline(objectuuid)
            }

            bankEventsuuids.each{|eventuuid|
                row = Bank::recordOrNull(eventuuid)
                next if row.nil?
                SystemEvents::broadcast({
                  "mikuType"  => "NxBankEvent",
                  "eventuuid" => row["_eventuuid_"],
                  "setuuid"   => row["_setuuid_"],
                  "unixtime"  => row["_unixtime_"],
                  "date"      => row["_date_"],
                  "weight"    => row["_weight_"]
                })
            }

            elementToOwnerEventsuuids.each{|eventuuid|
                row = OwnerMapping::recordOrNull(eventuuid)
                next if row.nil?
                SystemEvents::broadcast({
                    "mikuType"  => "OwnerMapping",
                    "eventuuid" => row["_eventuuid_"],
                    "owneruuid" => row["_groupuuid_"],
                    "itemuuid"  => row["_itemuuid_"]
                })
            }

            networkLinksEventsuuids.each{|eventuuid|
                row = NetworkLinks::recordOrNull(eventuuid)
                next if row.nil?
                SystemEvents::broadcast({
                    "mikuType"   => "NetworkLinks",
                    "eventuuid"  => row["_eventuuid_"],
                    "sourceuuid" => row["_sourceuuid_"],
                    "operation"  => row["_operation_"],
                    "targetuuid" => row["_targetuuid_"]
                })
            }
        end
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        Machines::theOtherInstanceIds().each{|targetInstanceId|
            SystemEvents::sendTo(event.clone, targetInstanceId)
        }
    end

    # SystemEvents::sendTo(event, targetInstanceId)
    def self.sendTo(event, targetInstanceId)
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        # We technically no longer need to mark the instance with the recipient's id
        # because we are dropping the event in the right folder, but we keep it anyway.
        event["targetInstance"] = targetInstanceId
        filepath = "#{Config::starlightCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.event.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
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
            if File.size(targetFilepath) > 1024*1024*100 then
                # The target is big, let's remove the datablobs and only keep the attributes
                db = SQLite3::Database.new(targetFilepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute "delete from _dxf1_ where _eventType_=?", ["datablob"]
                db.execute "vacuum", []
                db.close
            end
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

        updatedObjectuuids = []

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
                        attvalue   = row["_value_"] # We cannot deserialise that, could be a datablob

                        next if DxF1::eventExistsAtDxF1(objectuuid, eventuuid)

                        filepath2 = DxF1::filepath(objectuuid)

                        if verbose then
                            puts "SystemEvents::processCommsLine: writing event: #{eventuuid} at file: #{File.basename(filepath2)}"
                        end

                        db2 = SQLite3::Database.new(filepath2)
                        db2.busy_timeout = 117
                        db2.busy_handler { |count| true }
                        db2.results_as_hash = true
                        # I am commenting the next one out because we have checked that the record doesn't exists
                        # db2.execute "delete from _dxf1_ where _eventuuid_=?", [eventuuid]
                        db2.execute "insert into _dxf1_ (_objectuuid_, _eventuuid_, _eventTime_, _eventType_, _name_, _value_) values (?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, eventType, attname, attvalue]
                        db2.close

                        updatedObjectuuids << objectuuid
                    end
                    db1.close

                    FileUtils.rm(filepath1)
                    next
                end

                raise "(error: 600967d9-e9d4-4612-bf62-f8cc4f616fd1) I do not know how to process file: #{filepath1}"
            }

        updatedObjectuuids.each{|objectuuid| TheIndex::updateIndexAtObjectAttempt(objectuuid) }
    end

end
