
# encoding: UTF-8

=begin
    Mercury2::put(channel, value)
    Mercury2::readOrNull(channel)
    Mercury2::dequeue(channel)
=end

class ExternalEvents

    # ExternalEvents::sendEventToSQSStage1(event)
    def self.sendEventToSQSStage1(event)
        #puts "ExternalEvents::sendEventToSQSStage1(#{JSON.pretty_generate(event)})"
        Mercury2::put("341307DD-A9C6-494F-B050-CD89745A66C6", event)
    end

    # ExternalEvents::sendEventsToSQSStage2(verbose)
    def self.sendEventsToSQSStage2(verbose)

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

    # ExternalEvents::pullEventsFromSQS(verbose)
    def self.pullEventsFromSQS(verbose)
        AWSSQS::pullAndProcessEvents(verbose)
    end

    # ExternalEvents::incomingEventFromSQS(event, verbose)
    def self.incomingEventFromSQS(event, verbose)
        if verbose then
            puts "ExternalEvents::incomingEventFromSQS(#{JSON.pretty_generate(event)})"
        end
        if event["mikuType"] == "NxBankEvent" then
            Bank::incomingEvent(event)
            return
        end
        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::incomingEvent(event)
            return
        end
        if event["mikuType"] == "SetDoneToday" then
            DoneToday::incomingEvent(event)
            return
        end
        if event["mikuType"] == "StratificationRemove" then
            itemuuid = event["itemuuid"]
            Listing::remove(itemuuid)
            return
        end
        if event["mikuType"] == "NxDeleted" then
            # Todo:
            return
        end
    end

    # ExternalEvents::sync(verbose)
    def self.sync(verbose)
        begin
            ExternalEvents::sendEventsToSQSStage2(verbose)
            AWSSQS::pullAndProcessEvents(verbose)
        rescue StandardError => e
            puts "To Machine Event Maintenance Thread Error: #{e.message}"
        end
    end
end

class InternalEvents

    # InternalEvents::broadcast(event)
    def self.broadcast(event)

        puts "broadcast: #{JSON.pretty_generate(event)}"

        if event["mikuType"] == "(target is getting a new principal)" then
            principaluuid = event["principaluuid"]
            targetuuid = event["targetuuid"]
            XCache::set("a2f66362-9959-424a-ae64-759998f1119b:#{targetuuid}", principaluuid) # natural target -> owner mapping
            XCache::destroy("cfbe45a9-aea6-4399-85b6-211d185f7f57:#{targetuuid}") # task toString 
        end

        if event["mikuType"] == "(principal has been updated)" then
            XCache::destroy("78fe9aa9-99b2-4430-913b-1512880bf323:#{event["principaluuid"]}") # decaching queue size
        end
    end
end
