port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)


type alias Model =
    { count : Int
    , increment : Int
    , decrement : Int
    }


type Msg
    = Increment
    | Decrement
    | NoOp


initialModel : Model
initialModel =
    { count = 0
    , increment = 0
    , decrement = 0
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model
                | count = model.count + 1
                , increment = model.increment + 1
              }
            , increment ()
            )

        Decrement ->
            ( { model
                | count = model.count - 1
                , decrement = model.decrement + 1
              }
            , Cmd.none
            )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (toString model.count) ]
        , button [ onClick Increment ] [ text "+" ]
        , h3 [] [ text ("- clicked " ++ toString model.decrement ++ " times") ]
        , h3 [] [ text ("+ clicked " ++ toString model.increment ++ " times") ]
        ]


main =
    Html.program
        { init = ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions model =
    jsMsgs mapJsMsg



-- INPUT PORTS


port jsMsgs : (Int -> msg) -> Sub msg


mapJsMsg : Int -> Msg
mapJsMsg int =
    case int of
        1 ->
            Increment

        _ ->
            NoOp



-- OUTPUT PORTS


port increment : () -> Cmd msg
