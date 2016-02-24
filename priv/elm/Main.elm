module Main where

import Html exposing (div, button, text)
import Svg
import Html.Events exposing (onClick)
import Html.Widgets exposing (..)
import Html.Attributes exposing (..)
--import Svg exposing (..)
--import Svg.Attributes exposing (..)
-- import Graphics.Element exposing (..)
import String exposing (padLeft)
import StartApp.Simple as StartApp
import Http
-- import Json.Decode as Json exposing ((:=))
import Json.Decode as Json exposing (..)
import Task exposing (..)
--
-- getWatchState : Task Http.Error Watch
-- getWatchState = Http.get watch "http://localhost:8888/api/watch"
--
-- port fetchData : Task Http.Error (Watch)
-- port fetchData = getWatchState `Task.andThen` report
--
-- report n =
--   n.msec

      
current_msec : number
current_msec = 5

-- sendJson : Json.JsonValue -> Http.Request String
-- sendJson json = Http.request "POST" "http://localhost/jsonrpc" ( Json.toString " " json ) [("Content-Type", "application/json")]

-- import Json.Encode

main : Signal Html.Html
main = StartApp.start { model = model, view = view, update = update }

segments_digits : a -> String
segments_digits a = padLeft 8 '0' (toString a)

segments : a -> Svg.Svg
segments a =
  let props = { defaultSevenSegmentProperties | digits = segments_digits a}
      style = { defaultSevenSegmentStyle | textColor = "#DE2", backgroundColor = "#222" }
  in  sevenSegment props style

model : number
model = 0

digit_display : n -> Html.Html
digit_display n =
  div [ Html.Attributes.style [("width","200px"),("height", "70px")] ] [ segments n ]

view : Signal.Address Action -> a -> Html.Html
view address model =
  div []
    [ div [ ] [text "Stopwatch Sample" ]
    , digit_display model
--    , div [] [ text (toString fetchData) ]
    , button [ onClick address Start ] [ text "Start" ]
    , button [ onClick address Stop ] [ text "Stop" ]
    , button [ onClick address Clear ] [ text "Clear" ]]

type alias Watch = { msec : Int, ticks : Int, resolution : Int, running : Bool }

watch : Json.Decoder Watch
watch =
    Json.object4 Watch
      ("msec" := Json.int)
      ("ticks" := Json.int)
      ("resolution" := Json.int)
      ("running" := Json.bool)

type Action = Start | Stop | Clear

update : Action -> number -> number
update action model =
  case action of
    Start -> model + 1
    Stop -> model - 1
    Clear -> 0
