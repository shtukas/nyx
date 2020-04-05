
module Main exposing (..)

import Browser
import Html exposing (Html, Attribute, div, input, text, button, h2, a, select, option)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Json.Decode
import Set



-- Types

type PrimaryViewId = 
    MainViewId
  | TimelineListingViewId
  | SettingsViewId

type PermanodeTarget =
    PermanodeFolderTarget String String     -- uuid mark
  | PermanodeTargetUrl String String        -- uuid url
  | PermanodeTargetUniqueName String String -- uuid uniquename
  | PermanodeTargetPermaDir String String   -- uuid foldername

type PermandeClassificationItem = 
    PermanodeClassificationTag String String      -- uuid tag
  | PermanodeClassificationTimeline String String -- uuid timeline

type alias Permanode =
  { uuid : String
  , referenceDateTime : String
  , description : String
  , targets : List PermanodeTarget
  , classification : List PermandeClassificationItem
  }

type alias Model =
  { primaryViewId : PrimaryViewId
  , searchPattern : String
  , statusBar : String
  , permanodes : List Permanode
  , timelines : List String
  , searchResultsPermanodes : List Permanode
  , permanodeOnFocus : Maybe Permanode
  }

type Msg
  = PermanodesFromAPI (Result Http.Error (List Permanode))
  | TimelinesFromAPI (Result Http.Error (List String))
  | RefreshPermanodesFromServer
  | BringPermanodeToFocus Permanode
  | ClearPermanodeOnFocus
  | IncomingStringForSearch String
  | OpenUniqueName String
  | OpenPermaDir String
  | IgnoreAnswer (Result Http.Error String)
  | OpenTargetFolder String
  | DisplayServerOutputInStatusBar (Result Http.Error String)
  | IncomingPrimaryViewName String



-- Functions

permanodeMatchesSearchUtilsProjectClassificationItem: PermandeClassificationItem -> String
permanodeMatchesSearchUtilsProjectClassificationItem item =
  case item of
    PermanodeClassificationTag uuid tag -> tag
    PermanodeClassificationTimeline uuid timeline -> timeline

permanodeMatchesSearch: String -> Permanode -> Bool
permanodeMatchesSearch searchPattern permanode 
  =  String.contains (String.toLower searchPattern) (String.toLower permanode.uuid)
  || String.contains (String.toLower searchPattern) (String.toLower permanode.referenceDateTime)
  || String.contains (String.toLower searchPattern) (String.toLower permanode.description)
  || List.any (\s -> String.contains (String.toLower searchPattern) (String.toLower s)) (List.map (\i -> permanodeMatchesSearchUtilsProjectClassificationItem(i) ) permanode.classification)

search : (List Permanode) -> String -> List Permanode
search permanodes searchPattern =
  if String.length searchPattern  <= 2
  then
    []
  else
    List.filter (permanodeMatchesSearch searchPattern) permanodes

permanodesComparison: Permanode -> Permanode -> Order
permanodesComparison p1 p2 = compare p1.referenceDateTime p2.referenceDateTime

tagExtractionReduceStep: PermandeClassificationItem -> (List String) -> (List String)
tagExtractionReduceStep item tags = 
  case item of
    PermanodeClassificationTag uuid tag -> List.append tags [tag]
    PermanodeClassificationTimeline uuid timeline -> tags

tagExtractionFromPermanode: Permanode -> List String
tagExtractionFromPermanode permanode = List.foldl tagExtractionReduceStep [] permanode.classification

extractTagsFromPermanodes: (List Permanode) -> (List String)
extractTagsFromPermanodes permanodes = List.concat (List.map (\p -> tagExtractionFromPermanode p) permanodes)

timelineExtractionReduceStep: PermandeClassificationItem -> (List String) -> (List String)
timelineExtractionReduceStep item timelines =
  case item of
    PermanodeClassificationTag uuid tag -> timelines
    PermanodeClassificationTimeline uuid timeline -> List.append timelines [timeline]

timelineExtractionFromPermanode: Permanode -> List String
timelineExtractionFromPermanode permanode = List.foldl timelineExtractionReduceStep [] permanode.classification

extractTimelinesFromPermanodes: (List Permanode) -> (List String)
extractTimelinesFromPermanodes permanodes = List.concat (List.map (\p -> timelineExtractionFromPermanode p) permanodes)


-- MAIN

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }



-- MODEL

initModel = 
  { primaryViewId = MainViewId
  , searchPattern = ""
  , statusBar = "-"
  , permanodes = []
  , timelines = []
  , searchResultsPermanodes = []
  , permanodeOnFocus = Nothing
  }

init : () -> (Model, Cmd Msg)
init _ = 
  ( initModel 
  , Cmd.batch [requestPermanodesFromServer, requestTimelinesFromServer]
  )



-- UPDATE

httpErrorToString: Http.Error -> String
httpErrorToString error = 
  case error of
    Http.BadUrl str -> str
    Http.Timeout -> "Timeout"
    Http.NetworkError -> "NetworkError" 
    Http.BadStatus int -> String.fromInt int 
    Http.BadBody str -> str

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    IncomingStringForSearch searchPattern ->
      ({ model |   primaryViewId = MainViewId
                 , searchPattern = String.trim searchPattern
                 , searchResultsPermanodes = search model.permanodes (String.trim searchPattern)
                 , permanodeOnFocus = Nothing
                 , statusBar = "-"
      }
      , Cmd.none
      )

    PermanodesFromAPI result ->
      case result of
        Ok perms ->
          ({ model | permanodes = perms } , Cmd.none)

        Err error -> ({ model | statusBar = httpErrorToString error }, Cmd.none)

    TimelinesFromAPI result ->
      case result of
        Ok timels ->
          ({ model | timelines = timels } , Cmd.none)

        Err error -> ({ model | statusBar = httpErrorToString error }, Cmd.none)

    RefreshPermanodesFromServer ->
      ( model
      , requestPermanodesFromServer
      )

    BringPermanodeToFocus permanode ->
      ({ model | permanodeOnFocus = Just permanode } , Cmd.none)

    ClearPermanodeOnFocus ->
      ({ model | permanodeOnFocus = Nothing } , Cmd.none)

    OpenUniqueName uniquename ->
      ( model
      , requestOpenUniqueName uniquename
      )

    OpenPermaDir foldername ->
      ( model
      , requestOpenPermaDir foldername
      )

    IgnoreAnswer result -> (model , Cmd.none)

    OpenTargetFolder mark -> 
      ( model
      , requestOpenTargetFolder mark
      )

    DisplayServerOutputInStatusBar result -> 
      case result of
        Ok message ->
          ({ model | statusBar = message }, Cmd.none)

        Err error ->
          ({ model | statusBar = httpErrorToString error }, Cmd.none)

    IncomingPrimaryViewName name ->
      case name of
        "main-view" -> 
          ({ model |  primaryViewId = MainViewId }
           , Cmd.none
          )
        "timeline-listing" -> 
          ({ model |  primaryViewId = TimelineListingViewId }
           , Cmd.none
          )
        "settings" -> 
          ({ model |  primaryViewId = SettingsViewId }
           , Cmd.none
          )
        _ -> 
          ({ model |  primaryViewId = MainViewId }
           , Cmd.none
          )



-- HTTP Requests

requestPermanodesFromServer =
  Http.get
      { url = "http://localhost:12350/data/permanodes"
      , expect = Http.expectJson PermanodesFromAPI permanodesDecoder
      }

requestTimelinesFromServer = 
  Http.get
      { url = "http://localhost:12350/data/timelines"
      , expect = Http.expectJson TimelinesFromAPI timelinesDecoder
      }

requestOpenUniqueName uniquename =
  Http.get
      { url = ("http://localhost:12350/command/open-unique-string/" ++ uniquename)
      , expect = Http.expectString DisplayServerOutputInStatusBar
      }

requestOpenPermaDir foldername =
  Http.get
      { url = ("http://localhost:12350/command/open-perma-dir/" ++ foldername)
      , expect = Http.expectString DisplayServerOutputInStatusBar
      }

requestOpenTargetFolder mark =
  Http.get
      { url = ("http://localhost:12350/command/open-target-folder/" ++ mark)
      , expect = Http.expectString DisplayServerOutputInStatusBar
      }



-- JSON Decoders

permanodeTargetTypeDecoder: Json.Decode.Decoder String
permanodeTargetTypeDecoder = (Json.Decode.field "type" Json.Decode.string)

permanodeTargetDecoderFromType: String -> Json.Decode.Decoder PermanodeTarget
permanodeTargetDecoderFromType type_ =
  case type_ of
    "lstore-directory-mark-BEE670D0" -> Json.Decode.map2 PermanodeFolderTarget (Json.Decode.field "uuid" Json.Decode.string) (Json.Decode.field "mark" Json.Decode.string)
    "url-EFB8D55B"                   -> Json.Decode.map2 PermanodeTargetUrl (Json.Decode.field "uuid" Json.Decode.string) (Json.Decode.field "url" Json.Decode.string)
    "unique-name-C2BF46D6"           -> Json.Decode.map2 PermanodeTargetUniqueName (Json.Decode.field "uuid" Json.Decode.string) (Json.Decode.field "name" Json.Decode.string)
    "perma-dir-11859659"             -> Json.Decode.map2 PermanodeTargetPermaDir (Json.Decode.field "uuid" Json.Decode.string) (Json.Decode.field "foldername" Json.Decode.string)
    _                 -> Json.Decode.fail ("Invalid target type: " ++ type_)

permanodeTargetDecoder: Json.Decode.Decoder PermanodeTarget
permanodeTargetDecoder =
  permanodeTargetTypeDecoder
    |> Json.Decode.andThen permanodeTargetDecoderFromType

permanodeTargetsDecoder: Json.Decode.Decoder (List PermanodeTarget)
permanodeTargetsDecoder = Json.Decode.list permanodeTargetDecoder

permanodeClassificationTypeDecoder: Json.Decode.Decoder String
permanodeClassificationTypeDecoder = (Json.Decode.field "type" Json.Decode.string)

permanodeClassificationDecoderFromType : String -> Json.Decode.Decoder PermandeClassificationItem
permanodeClassificationDecoderFromType type_ =
  case type_ of
    "tag-18303A17"      -> Json.Decode.map2 PermanodeClassificationTag (Json.Decode.field "uuid" Json.Decode.string) (Json.Decode.field "tag" Json.Decode.string)
    "timeline-329D3ABD" -> Json.Decode.map2 PermanodeClassificationTimeline (Json.Decode.field "uuid" Json.Decode.string) (Json.Decode.field "timeline" Json.Decode.string)
    _                   -> Json.Decode.fail ("Invalid target type: " ++ type_)

permanodeClassificationItemDecoder: Json.Decode.Decoder PermandeClassificationItem
permanodeClassificationItemDecoder =
  permanodeClassificationTypeDecoder
    |> Json.Decode.andThen permanodeClassificationDecoderFromType

permanodeClassificationItemsDecoder : Json.Decode.Decoder (List PermandeClassificationItem)
permanodeClassificationItemsDecoder = Json.Decode.list permanodeClassificationItemDecoder

permanodeDecoder: Json.Decode.Decoder Permanode
permanodeDecoder =
  Json.Decode.map5 Permanode
    (Json.Decode.field "uuid" Json.Decode.string)
    (Json.Decode.field "referenceDateTime" Json.Decode.string)
    (Json.Decode.field "description" Json.Decode.string)
    (Json.Decode.field "targets" permanodeTargetsDecoder)
    (Json.Decode.field "classification" permanodeClassificationItemsDecoder)

permanodesDecoder: Json.Decode.Decoder (List Permanode)
permanodesDecoder = Json.Decode.list permanodeDecoder

timelinesDecoder: Json.Decode.Decoder (List String)
timelinesDecoder = Json.Decode.list Json.Decode.string



-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW

permanodeTargetView: Permanode -> PermanodeTarget -> Html Msg
permanodeTargetView permanode permanodeTarget =
  case permanodeTarget of 
    PermanodeFolderTarget uuid mark -> div [] [ text ("Directory: mark: " ++ mark ++ " ") , button [ onClick (OpenTargetFolder mark) ] [ text "open" ] ]
    PermanodeTargetUrl uuid url -> div [] [ a [ Html.Attributes.attribute "href" url, Html.Attributes.attribute "target" "_blank" ] [ text url ] ]
    PermanodeTargetUniqueName uuid uniquename -> div [] [text ("Target: uniquename: " ++ uniquename) , button [ onClick (OpenUniqueName uniquename) ] [ text "open" ]]
    PermanodeTargetPermaDir uuid foldername -> div [] [text ("Perma Dir (foldername): " ++ foldername) , button [ onClick (OpenPermaDir foldername) ] [ text "open" ]]

permanodeTagWithOnCLickView: String -> Html Msg
permanodeTagWithOnCLickView tag = 
  button [ onClick (IncomingStringForSearch tag) ] [ text tag ]

permanodeTimelineWithOnCLickView: String -> Html Msg
permanodeTimelineWithOnCLickView timeline =
  button [ onClick (IncomingStringForSearch timeline) ] [ text timeline ]

permanodeClassificationItemView: PermandeClassificationItem -> Html Msg
permanodeClassificationItemView item =
  case item of
    PermanodeClassificationTag uuid tag -> permanodeTagWithOnCLickView tag
    PermanodeClassificationTimeline uuid timeline -> button [ onClick (IncomingStringForSearch timeline) ] [ text ("timeline: " ++ timeline) ]

permanodeListingView: Permanode -> Html Msg
permanodeListingView permanode =
  div []
  [ div [ Html.Attributes.style "padding" "1px", Html.Attributes.style "cursor" "pointer" , onClick (BringPermanodeToFocus permanode) ] [ text ("\u{2022} " ++ permanode.description) ]
  ]

permanodeFullDetailsView: Model -> Permanode -> Html Msg
permanodeFullDetailsView model permanode =
  div 
    [] 
    [
      div []
      [ h2  [ Html.Attributes.style "margin" "0px" ] [ text permanode.description ]
      , div [ Html.Attributes.style "color" "grey" ] [ text (permanode.referenceDateTime ++ " ( uuid: " ++ permanode.uuid ++ " )" ) ]
      ]
    , div [] (List.map (permanodeTargetView permanode) permanode.targets)
    , div [] (List.map permanodeClassificationItemView permanode.classification)
    ]

permanodesListingView: Model -> Html Msg
permanodesListingView model =
  div []
  [  div [] (List.map permanodeListingView (List.reverse (List.sortWith permanodesComparison model.searchResultsPermanodes)))
  ,  div [] (List.map permanodeTagWithOnCLickView (Set.toList (Set.fromList (extractTagsFromPermanodes model.searchResultsPermanodes))))
  ,  div [] (List.map permanodeTimelineWithOnCLickView (Set.toList (Set.fromList (extractTimelinesFromPermanodes model.searchResultsPermanodes))))
  ]

permanodeOnFocusView: Model -> Permanode -> Html Msg
permanodeOnFocusView model permanode =
  div []
  [ permanodeFullDetailsView model permanode
  , div [] [button [ onClick ClearPermanodeOnFocus ] [ text "Clear" ]]
  ]

mainSearchViewPermanodesArea: Model -> Html Msg
mainSearchViewPermanodesArea model =
  case model.permanodeOnFocus of
    Nothing        ->
      if List.length model.searchResultsPermanodes == 1
      then
        case (List.head model.searchResultsPermanodes) of
          Nothing -> div [] [] -- This never happens
          Just permanode -> permanodeOnFocusView model permanode
      else
        permanodesListingView model

    Just permanode -> permanodeOnFocusView model permanode

mainSearchViewGlobal : Model -> Html Msg
mainSearchViewGlobal model =
  div 
    [] 
    [ input [ placeholder "Search pattern", value model.searchPattern, onInput IncomingStringForSearch, Html.Attributes.style "width" "100%" ] []
    , div [] [ mainSearchViewPermanodesArea model ]
    ]

timelimeListingView: Model -> Html Msg
timelimeListingView model = div [] (List.map (\timeline -> div [] [(button [ onClick (IncomingStringForSearch timeline)] [ text timeline ])])  model.timelines)

settingsView: Model -> Html Msg
settingsView model = div [] [ button [ onClick RefreshPermanodesFromServer ] [ text "Refresh in-memory permanodes" ] ]

primarySwitchView: Model -> Html Msg
primarySwitchView model =
  case model.primaryViewId of
    MainViewId -> mainSearchViewGlobal model
    TimelineListingViewId -> timelimeListingView model
    SettingsViewId -> settingsView model


trueIfStringIsPrimaryViewIdEquivalent: PrimaryViewId -> String -> Bool
trueIfStringIsPrimaryViewIdEquivalent viewId str =
  case viewId of
    MainViewId -> str == "main-view"
    TimelineListingViewId -> str == "timeline-listing"
    SettingsViewId -> str == "settings"

view : Model -> Html Msg
view model =
  div 
    [ Html.Attributes.style "padding" "10px" ] 
    [ div [ Html.Attributes.style "color" "grey" ] [ text model.statusBar ]
    , select
        [ onInput IncomingPrimaryViewName ]
        [ option [ value "main-view" , Html.Attributes.selected (trueIfStringIsPrimaryViewIdEquivalent model.primaryViewId "main-view")] [ text "Main search" ]
        , option [ value "timeline-listing" , Html.Attributes.selected (trueIfStringIsPrimaryViewIdEquivalent model.primaryViewId "timeline-listing") ] [ text "Timelines" ]
        , option [ value "settings" , Html.Attributes.selected (trueIfStringIsPrimaryViewIdEquivalent model.primaryViewId "settings") ] [ text "Settings" ]
        ]
    , div [] [ primarySwitchView model ]
    ]



