module View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)
import Config exposing (..)

bigCougar =
  style
    [ ("backgroundColor", "red") ]

view model =
  case model.state of
    Pairing ->
      div [ bigCougar ] [
        div [] [ text model.message ],
        div [] [ text "Waiting for an opponent..." ]
      ]
    PreGame ->
      div [] [ text "just a sec" ]
    Game ->
      let
        deltaTime = model.now - model.roundStart
        deltaScore = round ( 2^( deltaTime / timeDivisor ) )
      in
        div [] [
          div [] [ b [] [ text (toString deltaScore) ] ],
          div [] [ b [] [ text model.message ] ],
          button [ onClick Flip ] [ text "FLIP THE COUGAR" ]
        ]
    Error ->
      div [] [
        b [] [ text "Error: " ],
        text model.message
      ]

