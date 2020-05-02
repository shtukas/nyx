
## InFlightControlSystem Aether files

kvstore
      uuid        :
      description :
      payloadType :
      position    : Float

The possible values for payloadType are

- aionpoint
- text
- url

When "aionpoint" a single aion reference hardcoded to "1815ea639314" pointing at a file or a folder.

When "text", the content is held in the kv store at key "472ec67c0dd6"

When "url", the url is held in the kv store at key "67c2db721728"

### Special Items

20200502-141331-226084 ; Guardian General Work
20200502-141716-483780 ; Interface 🛩️

### Mercury Channels

Text to become IFCS item payload `text`

- channel: 95df0a03-2bf5-4d7a-a911-b6d67bed8d09
- payload: {
    "description" : String Line
    "position"    : Float
    "text"        : String Multiline
}