
# encoding: UTF-8

=begin
    Mercury2::put(channel, value)
    Mercury2::readOrNull(channel)
    Mercury2::dequeue(channel)
=end

class SystemEvents

    # SystemEvents::publishGlobalEventStage1(event)
    def self.publishGlobalEventStage1(event)
        #puts "SystemEvents::publishGlobalEventStage1(#{JSON.pretty_generate(event)})"
        Mercury2::put("341307DD-A9C6-494F-B050-CD89745A66C6", event)
    end

    # SystemEvents::publishGlobalEventStage2(verbose)
    def self.publishGlobalEventStage2(verbose)

        return if Mercury2::empty?("341307DD-A9C6-494F-B050-CD89745A66C6")

        Aws.config.update({
           credentials: Aws::Credentials.new(Config::get("aws.AWS_ACCESS_KEY_ID"), Config::get("aws.AWS_SECRET_ACCESS_KEY"))
        })

        region = 'eu-west-1'

        machinesource = Machines::thisMachine()
        machinetarget = Machines::theOtherMachine()

        sqs_url = AWSSQS::sqs_url_or_null(machinesource, machinetarget)

        if sqs_url.nil? then
            puts "(error) AWSSQS::send, machinesource: #{machinesource}, machinetarget: #{machinetarget}, could not determine queue url"
            exit
        end

        sqs_client = Aws::SQS::Client.new(region: region)

        loop {
            event = Mercury2::readFirstOrNull("341307DD-A9C6-494F-B050-CD89745A66C6")
            break if event.nil?

            puts "AWSSQS::send(#{JSON.pretty_generate(event)})" if verbose

            begin 
                sqs_client.send_message(
                    queue_url: sqs_url,
                    message_body: JSON.generate(event)
                )
                Mercury2::dequeue("341307DD-A9C6-494F-B050-CD89745A66C6")
            rescue StandardError => e
                #puts "Error sending messages: #{e.message}"
                return false
            end
        }
    end

    # SystemEvents::getGlobalEventsFromSQS(verbose)
    def self.getGlobalEventsFromSQS(verbose)
        AWSSQS::pullAndProcessEvents(verbose)
    end

    # SystemEvents::sync(verbose)
    def self.sync(verbose)
        begin
            SystemEvents::publishGlobalEventStage2(verbose)
            AWSSQS::pullAndProcessEvents(verbose)
        rescue StandardError => e
            puts "To Machine Event Maintenance Thread Error: #{e.message}"
        end
    end

    # SystemEvents::processEvent(event, verbose)
    def self.processEvent(event, verbose)

        if verbose then
            puts "SystemEvent(#{JSON.pretty_generate(event)})"
        end

        if event["mikuType"] == "(object has been updated)" then
            filepath = Fx18Utils::computeLocalFx18Filepath(event["objectuuid"])
            return if !File.exists?(filepath) # object has been updated on one computer but has not yet been put on another
            Fx18Index1::updateIndexForFilepath(filepath)
        end

        if event["mikuType"] == "(object has been deleted)" then
            Fx18Index1::removeRecordForObjectUUID(event["objectuuid"])
        end

        if event["mikuType"] == "Fx18 File Event" then
            objectuuid = event["objectuuid"]
            Fx19Data::ensureFileForPut(objectuuid)
            eventi = event["Fx18FileEvent"]
            Fx18File::writeGenericFx18FileEvent(objectuuid, eventi["_eventuuid_"], eventi["_eventTime_"], eventi["_eventData1_"], eventi["_eventData2_"], eventi["_eventData3_"], eventi["_eventData4_"], eventi["_eventData5_"])
            return
        end

        if event["mikuType"] == "NxBankEvent" then
            Bank::processEvent(event)
            return
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEvent(event)
            return
        end

        if event["mikuType"] == "SetDoneToday" then
            DoneToday::processEvent(event)
            return
        end

        if event["mikuType"] == "RemoveFromListing" then
            Listing::remove(event["itemuuid"])
            return
        end

        if event["mikuType"] == "NxDeleted" then
            # Todo:
            return
        end
    end
end
