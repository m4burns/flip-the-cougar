module View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)
import Config exposing (..)
import Style exposing (..)

view model =
  case model.state of
    Pairing ->
      div [] [
        img [ src "resources/cougar1.svg", bigCougar ] [],
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
          img [ src "resources/cougar2-in.svg", topCougar ] [],
          img [ src "resources/cougar2-out.svg", bottomCougar ] [],
          div [ scoreDisplay, onClick Flip ] [
            div [ scoreContent ] [
              div [] [
                text "Your score: ",
                text (toString model.score)
              ],
              div [] [
                text "You stand to win or lose: ",
                text (toString deltaScore)
              ],
              div [] [
                b [] [
                  text "Press SPACE to FLIP THE COUGAR!"
                ]
              ]
            ]
          ]
        ]
    Error ->
      div [] [
        b [] [ text "Error: " ],
        text model.message
      ]

