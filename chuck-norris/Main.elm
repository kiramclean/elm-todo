port module Main exposing (..)

import Html exposing (..)
import Html.Attributes
    exposing
        ( class
        )
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Encode


-- import Json.Decode.Pipeline exposing (decode, required)
-- MODEL


type alias Model =
    { icon_url : String
    , id : String
    , value : String
    }


type Msg
    = NewJoke
    | SetModel Model
    | NoOp


initialModel : Model
initialModel =
    { icon_url = ""
    , id = "0"
    , value = "No jokes yet."
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewJoke ->
            ( model, Cmd.none )

        SetModel model ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick NewJoke ] [ text "Get a new joke!" ]
        ]


main =
    Html.program
        { init = ( initialModel, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions model =
    storageInput mapStorageInput



-- INPUT PORTS


port storageInput : (Decode.Value -> msg) -> Sub msg



-- OUTPUT PORTS


port storage : Encode.Value -> Cmd msg



-- SUBSCRIPTIONS


mapStorageInput : Decode.Value -> Msg
mapStorageInput modelJson =
    case decodeJson modelJson of
        Ok model ->
            SetModel model

        Err errorMessage ->
            let
                _ =
                    Debug.log "Error in mapStorageInput:" errorMessage
            in
            NoOp


decodeJson : Decode.Value -> Result String Model
decodeJson modelJson =
    Decode.decodeValue modelDecoder modelJson


modelDecoder : Decode.Decoder Model
modelDecoder =
    decode Model
        |> required "icon_url" Decode.string
        |> required "id" Decode.string
        |> required "value" Decode.string
