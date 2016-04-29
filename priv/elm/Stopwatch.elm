import Char
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Widgets exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json exposing ((:=))
import String
import Task exposing (..)
import Time exposing (..)
import Dict
import Svg exposing (Svg)

--CONSTANTS
stopwatchUrl = "http://localhost:8888/api/watch"

-- VIEW
view : Result (String, Model) Model -> Html
view result =
  let (errMsg, model) = 
    case result of
      Err tuple -> tuple
      Ok model -> ("", model)
  in
    div [] [ 
      div [style [("width", "200px"), ("height", "70px")]] [segments model.stopwatch]
    , button [onClick inputMailbox.address Start] [text "Start"]
    , button [onClick inputMailbox.address Stop] [text "Stop"]
    , button [onClick inputMailbox.address Clear] [text "Clear"]
    , select [ on "change" (Json.at ["target", "value"] Json.string) (\newRes -> Signal.message inputMailbox.address (resolutionToAction newRes)) ] 
      (resolutionOptions model.stopwatch.resolution)
    ]

segments : Stopwatch -> Svg
segments stopwatch =
  let props = { defaultSevenSegmentProperties | digits = segments_digits stopwatch, colonIndexes = [], pointIndexes = [ 5 ]}
      style = { defaultSevenSegmentStyle | textColor = "#DE2", backgroundColor = "#222" }
  in  sevenSegment props style

segments_digits : Stopwatch -> String
segments_digits stopwatch = 
  String.padLeft 8 '-' (toString ((toFloat stopwatch.msec) / 10))

resolutionOptions : Int -> List Html
resolutionOptions currentResolution = 
  List.map (\res -> option [value (toString res), selected (res == currentResolution)] [text (toString res)]) [10, 100, 1000]

resolutionToAction : String -> Action
resolutionToAction resolutionString = 
  case String.toInt resolutionString of
    Ok int -> Resolution int
    _ -> DoNothing

--MODELS

type alias Stopwatch = 
  { msec: Int
  , resolution: Int
  }

type alias Model = 
  { stopwatch : Stopwatch
  , version : Maybe String
  }

type Action = Start | Stop | Clear | Resolution Int | DoNothing

defaultModel : Model
defaultModel = 
  Model (Stopwatch 0 100) Nothing

-- WIRING

main =
  Signal.map view longPollMailbox.signal

longPollMailbox : Signal.Mailbox (Result (String, Model) Model)
longPollMailbox =
  Signal.mailbox (Ok defaultModel)

inputMailbox : Signal.Mailbox Action
inputMailbox = 
  Signal.mailbox DoNothing

port buttons : Signal (Task String String)
port buttons = 
    Signal.map controlPressed inputMailbox.signal

port stopwatch : Signal (Task x ())
port stopwatch =
  Signal.map extractModel longPollMailbox.signal
    |> Signal.map lookupStopWatch
    |> Signal.map (\task -> Task.toResult task `andThen` Signal.send longPollMailbox.address)

--MISC METHODS

controlPressed : Action -> Task String String
controlPressed action = 
  case action of
    Start -> controlRequest (Http.string """{ "running": true }""")
    Stop -> controlRequest (Http.string """{ "running": false }""")
    Clear -> controlRequest (Http.string """{ "ticks": 0 }""")
    Resolution newRes -> controlRequest (Http.string("""{ "resolution": """ ++ toString(newRes) ++ """ }"""))
    _ -> Task.succeed "no action required" 

controlRequest : Http.Body -> Task String String
controlRequest body = 
  let request = 
    { verb = "PUT"
    , headers = [("Accept", "application/json"), ("Content-Type", "application/json")]
    , url = stopwatchUrl
    , body = body
    }
  in
     Http.send Http.defaultSettings request
       |> Task.map (always "update successful")
       |> Task.mapError (always "update failed")

lookupStopWatch : Model -> Task (String, Model) Model
lookupStopWatch currentModel =
    longPoll (parseMsec currentModel.stopwatch) stopwatchUrl currentModel.version
      |> Task.map (\(stopwatch, version) -> Model stopwatch version) 
      |> Task.mapError (\errorMsg -> (errorMsg, currentModel))

parseMsec : Stopwatch -> Json.Decoder Stopwatch
parseMsec defaultStopwatch =
  Json.object2 Stopwatch
  (Json.map (Maybe.withDefault defaultStopwatch.msec) (Json.maybe ("msec" := Json.int)))
  (Json.map (Maybe.withDefault defaultStopwatch.resolution) (Json.maybe ("resolution" := Json.int)))

extractModel : Result (String, Model) Model -> Model
extractModel result =
  case result of
    Ok model -> model
    Err (msg, model) -> model

-- LONG POLLING

longPoll : Json.Decoder Stopwatch -> String -> Maybe String -> Task String (Stopwatch, Maybe String) 
longPoll decoder url versionHeader = 
  let request = 
    { verb = "GET"
    , headers = longPollHeaders versionHeader
    , url = url
    , body = Http.empty
    }
  in
     mapError (always "long poll request failed") (Http.send Http.defaultSettings request) `andThen` handleResponse decoder

longPollHeaders : Maybe String -> List (String, String)
longPollHeaders versionHeader = 
  let defaultHeader = ("Accept", "application/merge-patch+json")
  in
    case versionHeader of
      Nothing -> [defaultHeader]
      Just header -> (defaultHeader :: [("x-since-version", header), ("x-long-poll", "true")])

handleResponse : Json.Decoder Stopwatch -> Http.Response -> Task String (Stopwatch, Maybe String)
handleResponse decoder response = 
  let versionHeader = Dict.get "x-version" response.headers
  in
    case response.value of
      Http.Text str ->
        case Json.decodeString decoder str of
          Ok decoderModel -> 
            Task.succeed (decoderModel, versionHeader)
          Err msg -> Task.fail msg
      _ ->
        Task.fail "response wasn't a string"
