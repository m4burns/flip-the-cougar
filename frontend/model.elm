module Model exposing (..)

import Time exposing (Time)

type State = Pairing | PreGame | Game | Error

type alias Model = {
  state : State,
  message : String,
  score : Int,
  roundStart : Time,
  now : Time
}

type Msg = Flip
         | Tick Time
         | Recv String
         
init : (Model, Cmd Msg)
init =
  ({ state = Pairing,
     message = "",
     score = 0,
     roundStart = 0,
     now = 0 },
   Cmd.none)
