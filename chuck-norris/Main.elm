port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)
import Task


-- MODEL


type alias Model =
    { icon_url : String
    , id : String
    , value : String
    }


type Msg
    = FetchJoke
    | ReceiveJoke (Result Http.Error Model)


initialModel : Model
initialModel =
    { icon_url = ""
    , id = ""
    , value = ""
    }


apiEndpoint : String
apiEndpoint =
    "https://api.chucknorris.io/jokes/random"



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchJoke ->
            ( model, fetchJoke )

        ReceiveJoke (Ok joke) ->
            ( joke, Cmd.none )

        ReceiveJoke (Err _) ->
            ( model, Cmd.none )


fetchJoke : Cmd Msg
fetchJoke =
    Http.send ReceiveJoke (Http.get apiEndpoint jokeDecoder)


jokeDecoder : Decode.Decoder Model
jokeDecoder =
    decode Model
        |> required "icon_url" Decode.string
        |> required "id" Decode.string
        |> required "value" Decode.string



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "Chuck Norris Jokes" ]
        , viewJoke model
        , button [ onClick FetchJoke ] [ text "Get a new joke!" ]
        ]


viewJoke : Model -> Html Msg
viewJoke model =
    div []
        [ img [ src model.icon_url ] []
        , p [] [ text model.value ]
        ]


main =
    Html.program
        { init = ( initialModel, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions model =
    Sub.none
