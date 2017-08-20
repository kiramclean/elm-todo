port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)


type alias Model =
    Int


type Msg
    = Increment
    | Send


initialModel : Model
initialModel =
    0


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( model + 1, Cmd.none )

        Send ->
            ( model, outbound model )


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text (model |> toString) ]
        , button [ onClick Send ] [ text "Send" ]
        ]


main =
    Html.program
        { init = ( initialModel, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions model =
    increment mapIncrement


mapIncrement : {} -> Msg
mapIncrement _ =
    Increment



-- INPUT PORTS


port increment : ({} -> msg) -> Sub msg



-- OUTPUT PORTS


port outbound : Int -> Cmd msg
