module Controller exposing (..)

import Time exposing (Time, millisecond)
import String exposing (words, toInt)
import WebSocket
import Keyboard
import Char
import Model exposing (..)
import Config exposing (..)

update msg {state, message, score, roundStart, now} =
  case msg of
    None ->
      (Model state message score roundStart now, Cmd.none)
    Flip ->
      (Model state message score roundStart now,
        if state == Game then
          WebSocket.send server "flip"
        else
          Cmd.none)
    Tick next ->
      case state of
        PreGame ->
          (Model Game "FLIP THE COUGAR" score next next, Cmd.none)
        _ ->
          (Model state message score roundStart next, Cmd.none)
    Recv serverMsg ->
      case words serverMsg of
        [serverCmd, serverScoreStr] ->
          case toInt serverScoreStr of
            Ok serverScore ->
              case serverCmd of
                "go" ->
                  (Model PreGame "wait.." serverScore 0 0, Cmd.none)
                "over" ->
                  let gameOverMessage =
                    if serverScore > score then
                      "YOU FLIPPED THAT COUGER"
                    else
                      "YOU GOT FLIPPED"
                  in
                    (Model Pairing gameOverMessage serverScore now now, Cmd.none)
                _ ->
                  (Model Error "bad server verb" score 0 0, Cmd.none)
            Err errMsg ->
              (Model Error "bad server score" score 0 0, Cmd.none)
        _ ->
          (Model Error "bad server command string" score 0 0, Cmd.none)

mapKeyPress : Keyboard.KeyCode -> Msg
mapKeyPress key =
  case Char.fromCode key of
    ' ' ->
      Flip
    _ ->
      None
  
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    Time.every millisecond Tick,
    WebSocket.listen server Recv,
    Keyboard.presses mapKeyPress
  ]

