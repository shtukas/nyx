
# encoding: UTF-8

=begin
    Mercury2::put(channel, value)
    Mercury2::readOrNull(channel)
    Mercury2::dequeue(channel)
=end

class EventsToAWSQueue

    # EventsToAWSQueue::publish(event)
    def self.publish(event)
        #puts "EventsToAWSQueue::publish(#{JSON.pretty_generate(event)})"
        Mercury2::put("341307DD-A9C6-494F-B050-CD89745A66C6", event)
    end

    # EventsToAWSQueue::sendEventsToSQS(verbose)
    def self.sendEventsToSQS(verbose)

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

    # EventsToAWSQueue::pullEventsFromSQS(verbose)
    def self.pullEventsFromSQS(verbose)
        AWSSQS::pullAndProcessEvents(verbose)
    end

    # EventsToAWSQueue::incomingEventFromSQS(event, verbose)
    def self.incomingEventFromSQS(event, verbose)
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
            Stratification::removeItemByUUID(itemuuid)
            return
        end
        # If an event has not be catured, then we assume it's a database object 
        Librarian::incomingEvent(event, verbose ? "aws" : nil)
    end

    # EventsToAWSQueue::sync(verbose)
    def self.sync(verbose)
        begin
            EventsToAWSQueue::sendEventsToSQS(verbose)
            AWSSQS::pullAndProcessEvents(verbose)
        rescue StandardError => e
            puts "To Machine Event Maintenance Thread Error: #{e.message}"
        end
    end
end

class EventsInternal

    # EventsInternal::broadcast(event)
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

        if event["mikuType"] == "NxDoNotShowUntil" then
            targetuuid = event["targetuuid"]
            targetunixtime = event["targetunixtime"]
            Stratification::applyDoNotDisplayUntilUnixtime(targetuuid, targetunixtime)
        end
    end
end
