module Main exposing (..)

import Html exposing (..)
import RandomGif exposing (init, update, view)


main =
    Html.program
        { init = init "funny cats"
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
