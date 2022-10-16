
# encoding: UTF-8

class SystemEvents

    # SystemEvents::pathToCommsline()
    def self.pathToCommsline()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Commsline"
    end

    # SystemEvents::internal(event)
    def self.internal(event)

        #puts "SystemEvent(#{JSON.pretty_generate(event)})"

        # ordering: as they come

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEvent(event)
        end

        if event["mikuType"] == "bank-account-done-today" then
            BankAccountDoneForToday::processEvent(event)
        end

        if event["mikuType"] == "XCacheSet" then
            key = event["key"]
            value = event["value"]
            XCache::set(key, value)
        end

        if event["mikuType"] == "XCacheFlag" then
            key = event["key"]
            flag = event["flag"]
            XCache::setFlag(key, flag)
        end

        if event["mikuType"] == "bank-account-set-un-done-today" then
            BankAccountDoneForToday::processEvent(event)
        end

        if event["mikuType"] == "NxGraphEdge1" then
            FileSystemCheck::fsck_NxGraphEdge1(event, SecureRandom.hex, false)
            NetworkEdges::processEvent(event)
        end
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        Machines::theOtherInstanceIds().each{|targetInstanceId|
            filepath = "#{SystemEvents::pathToCommsline()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.system-event.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
        }
    end

    # SystemEvents::processIncomingEventsFromLine(verbose)
    def self.processIncomingEventsFromLine(verbose)
        # New style. Keep while we process the remaining items
        # We are reading from the instance folder

        instanceId = Config::get("instanceId")

        folderpath = "#{SystemEvents::pathToCommsline()}/#{instanceId}"

        LucilleCore::locationsAtFolder(folderpath)
            .each{|filepath1|

                next if !File.exists?(filepath1)
                next if File.basename(filepath1).start_with?(".")
                next if File.basename(filepath1).include?("sync-conflict")

                if verbose then
                    puts "SystemEvents::processIncomingEventsFromLine: processing: #{File.basename(filepath1)}"
                end

                if CommonUtils::ends_with?(filepath1, ".system-event.json") then
                    event = JSON.parse(IO.read(filepath1))
                    if verbose then
                       puts "system event from commsline: #{JSON.pretty_generate(event)}"
                    end
                    SystemEvents::internal(event)
                    FileUtils.rm(filepath1)
                    next
                end

                raise "(error: 600967d9-e9d4-4612-bf62-f8cc4f616fd1) I do not know how to process file: #{filepath1}"
            }
    end
end