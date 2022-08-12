
# encoding: UTF-8

class SystemEvents

    # SystemEvents::processEventInternally(event)
    def self.processEventInternally(event)

        # puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(object has been updated)" then
            Lookup1::processEventInternally(event)
            return
        end

        if event["mikuType"] == "(object has been logically deleted)" then
            Fx18s::deleteObjectNoEvents(event["objectuuid"])
            Lookup1::processEventInternally(event)
            return
        end

        if event["mikuType"] == "NxBankEvent" then
            Bank::processEventInternally(event)
            return
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEventInternally(event)
            return
        end

        if event["mikuType"] == "SetDoneToday" then
            DoneForToday::processEventInternally(event)
            return
        end

        if event["mikuType"] == "NxDeleted" then
            Fx18s::deleteObjectNoEvents(event["objectuuid"])
            Lookup1::processEventInternally(event)
            return
        end

        if event["mikuType"] == "Fx18 File Event" then
            if event["Fx18FileEvent"]["_eventData1_"] == "datablob" then
                event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData3_"])
            end
            eventi = event["Fx18FileEvent"]
            objectuuid = eventi["_objectuuid_"]
            return if !File.exists?(Fx18s::objectuuidToLocalFx18Filepath(objectuuid))
            Fx18s::commit(eventi["_objectuuid_"], eventi["_eventuuid_"], eventi["_eventTime_"], eventi["_eventData1_"], eventi["_eventData2_"], eventi["_eventData3_"], eventi["_eventData4_"], eventi["_eventData5_"])
            Lookup1::reconstructEntry(eventi["_objectuuid_"])
            return
        end

        if event["mikuType"] == "ItemToGroupMapping" then
            groupuuid = event["groupuuid"]
            itemuuid  = event["itemuuid"]
            ItemToGroupMapping::issueNoEvent(groupuuid, itemuuid)
        end

        if event["mikuType"] == "ItemToGroupMapping-records" then
            db = SQLite3::Database.new(ItemToGroupMapping::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            event["records"].each{|row|
                db.execute "delete from _mapping_ where _eventuuid_=?", [row["_eventuuid_"]]
                db.execute "insert into _mapping_ (_eventuuid_, _eventTime_, _itemuuid_, _groupuuid_, _status_) values (?, ?, ?, ?, ?)", [row["_eventuuid_"], row["_eventTime_"], row["_itemuuid_"], row["_groupuuid_"], row["_status_"]]
            }
            db.close
        end

        if event["mikuType"] == "Bank-records" then
            db = SQLite3::Database.new(Bank::pathToBank())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            event["records"].each{|row|
                db.execute "delete from _bank_ where _eventuuid_=?", [row["_eventuuid_"]] # (1)
                db.execute "insert into _bank_ (_eventuuid_, _setuuid_, _unixtime_, _date_, _weight_) values (?, ?, ?, ?, ?)", [row["_eventuuid_"], row["_setuuid_"], row["_unixtime_"], row["_date_"], row["_weight_"]]
            }
            db.close
        end
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        if event["mikuType"] == "Fx18 File Event" then
            if event["Fx18FileEvent"]["_eventData1_"] == "datablob" then
                event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData3_"])
            end
        end
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        Machines::theOtherInstanceIds().each{|instanceName|
            e = event.clone
            e["targetInstance"] = instanceName
            filepath = "#{Config::starlightCommLine()}/#{CommonUtils::timeStringL22()}.event.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(e)) }
        }
    end
end
