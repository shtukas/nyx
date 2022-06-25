
# encoding: UTF-8

=begin
    Mercury2::put(channel, value)
    Mercury2::readOrNull(channel)
    Mercury2::dequeue(channel)
=end



class EventsToCentral

    # EventsToCentral::publish(event)
    def self.publish(event)
        Mercury2::put("23c340bb-c4b3-4326-ba47-62461ba0d063", event)
    end

    # EventsToCentral::sendLocalEventsToCentral()
    def self.sendLocalEventsToCentral()
        loop {
            object = Mercury2::readFirstOrNull("23c340bb-c4b3-4326-ba47-62461ba0d063")
            break if object.nil?
            puts "EventsToCentral::sendLocalEventsToCentral(): record (from local object repo to central objects): #{JSON.pretty_generate(object)}"
            StargateCentralObjects::commit(object)
            Mercury2::dequeue("23c340bb-c4b3-4326-ba47-62461ba0d063")
        }
    end
end

class EventsToAWSQueue
    # Here we store the events to send fast to the other machine

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
end

class EventSync

    # EventSync::awsSync(verbose)
    def self.awsSync(verbose)
        #puts "To Machine Event Maintenance Thread"
        begin
            EventsToAWSQueue::sendEventsToSQS(verbose)
            AWSSQS::pullAndProcessEvents(verbose)
        rescue StandardError => e
            puts "To Machine Event Maintenance Thread Error: #{e.message}"
        end
    end

    # EventSync::infinityEventsSync()
    def self.infinityEventsSync()
        EventsToCentral::sendLocalEventsToCentral()
        StargateCentralObjects::objects().each{|object| Librarian::incomingEvent(object, "stargate central")}
    end
end
