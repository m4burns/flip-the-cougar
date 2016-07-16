module Style exposing (..)

import Html.Attributes exposing (..)

bigCougar =
  style
    [ ("width", "100vw"),
      ("height", "100vh"),
      ("maxWidth", "100vw"),
      ("maxHeight", "100vh"),
      ("margin", "auto"),
      ("position", "absolute"),
      ("top", "0"),
      ("bottom", "0"),
      ("left", "0"),
      ("right", "0") ]

topCougar =
  style
    [ ("width", "50vw"),
      ("maxHeight", "45vh"),
      ("maxWidth", "50vw"),
      ("margin", "auto"),
      ("position", "absolute"),
      ("top", "0"),
      ("left", "0"),
      ("zIndex", "-1") ]

bottomCougar =
  style
    [ ("width", "50vw"),
      ("maxHeight", "45vh"),
      ("maxWidth", "50vw"),
      ("margin", "auto"),
      ("position", "absolute"),
      ("bottom", "0"),
      ("right", "0"),
      ("zIndex", "-1") ]

scoreDisplay =
  style
    [ ("position", "absolute"),
      ("margin", "auto"),
      ("width", "100vw"),
      ("height", "100vh"),
      ("textAlign", "center"),
      ("display", "table"),
      ("top", "0"),
      ("bottom", "0"),
      ("left", "0"),
      ("right", "0"),
      ("zIndex", "1") ]

scoreContent =
  style
    [ ("display", "table-cell" ),
      ("verticalAlign", "middle" ),
      ("zIndex", "0") ]
