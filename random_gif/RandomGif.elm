module RandomGif exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Task


type alias Model =
    { topic : String
    , gifUrl : String
    }


init : String -> ( Model, Cmd Msg )
init topic =
    let
        waitingUrl =
            "https://i.imgur.com/i6eXrfS.gif"
    in
    ( Model topic waitingUrl
    , getRandomGif topic
    )


type Msg
    = RequestMore
    | NewGif (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RequestMore ->
            ( model, getRandomGif model.topic )

        NewGif (Ok url) ->
            ( { model | gifUrl = url }, Cmd.none )

        NewGif (Err _) ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text model.topic ]
        , div [] [ img [ src model.gifUrl ] [] ]
        , button [ onClick RequestMore ] [ text "More please!" ]
        ]


getRandomGif : String -> Cmd Msg
getRandomGif topic =
    let
        url =
            "https://api.giphy.com/v1/gifs/random?api_key=87cbb5f764524e5389b3148dacb0f77f"
                ++ "&tag="
                ++ topic

        request =
            Http.get url decodeGifUrl
    in
    Http.send NewGif request


decodeGifUrl : Decode.Decoder String
decodeGifUrl =
    Decode.at [ "data", "image_url" ] Decode.string
