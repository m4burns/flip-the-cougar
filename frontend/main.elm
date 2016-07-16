import Html.App as Html
import Model as Model
import View as View
import Controller as Controller

main =
  Html.program
    { init = Model.init
    , view = View.view
    , update = Controller.update
    , subscriptions = Controller.subscriptions
    }
