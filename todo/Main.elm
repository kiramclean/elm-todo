port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, onCheck, onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode


type alias Todo =
    { title : String
    , completed : Bool
    , editing : Bool
    , id : Int
    }


type FilterState
    = All
    | Active
    | Completed


type alias Model =
    { todos : List Todo
    , todo : Todo
    , filter : FilterState
    , nextId : Int
    }


type Msg
    = Add
    | Complete Todo
    | Uncomplete Todo
    | Delete Todo
    | UpdateField String
    | ClearCompleted
    | SetModel Model
    | Filter FilterState


initialModel : Model
initialModel =
    { todos =
        [ { title = "Buy more bananas"
          , completed = False
          , editing = False
          , id = 1
          }
        ]
    , todo = { newTodo | id = 2 }
    , filter = All
    , nextId = 3
    }


newTodo : Todo
newTodo =
    { title = ""
    , completed = False
    , editing = False
    , id = 0
    }



--- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Add ->
            let
                newModel =
                    { model
                        | todos = model.todo :: model.todos
                        , todo = { newTodo | id = model.nextId }
                        , nextId = model.nextId + 1
                    }
            in
            ( newModel
            , sendToStorage newModel
            )

        Complete todo ->
            let
                updateTodo thisTodo =
                    if thisTodo.id == todo.id then
                        { todo | completed = True }
                    else
                        thisTodo

                newModel =
                    { model
                        | todos = List.map updateTodo model.todos
                    }
            in
            ( newModel
            , sendToStorage newModel
            )

        Uncomplete todo ->
            let
                updateTodo thisTodo =
                    if thisTodo.id == todo.id then
                        { thisTodo | completed = False }
                    else
                        thisTodo

                newModel =
                    { model
                        | todos = List.map updateTodo model.todos
                    }
            in
            ( newModel
            , sendToStorage newModel
            )

        Delete todo ->
            let
                newModel =
                    { model
                        | todos =
                            List.filter
                                (\mappedTodo -> todo.id /= mappedTodo.id)
                                model.todos
                    }
            in
            ( newModel
            , sendToStorage newModel
            )

        UpdateField value ->
            let
                todo =
                    model.todo

                updatedTodo =
                    { todo | title = value }

                newModel =
                    { model | todo = updatedTodo }
            in
            ( newModel
            , sendToStorage newModel
            )

        ClearCompleted ->
            let
                newModel =
                    { model
                        | todos =
                            List.filter
                                (\todo -> todo.completed == False)
                                model.todos
                    }
            in
            ( newModel
            , sendToStorage newModel
            )

        SetModel newModel ->
            ( newModel, Cmd.none )

        Filter filterState ->
            let
                newModel =
                    { model | filter = filterState }
            in
            ( newModel
            , sendToStorage newModel
            )


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Decode.succeed msg
            else
                Decode.fail "not the right keycode"
    in
    on "keydown" (keyCode |> Decode.andThen isEnter)


filteredTodos : Model -> List Todo
filteredTodos model =
    let
        matchesFilter =
            case model.filter of
                All ->
                    \_ -> True

                Active ->
                    \todo -> todo.completed == False

                Completed ->
                    \todo -> todo.completed == True
    in
    List.filter matchesFilter model.todos



--- VIEW


view : Model -> Html Msg
view model =
    div []
        [ node "style" [ type_ "text/css" ] [ text styles ]
        , section [ class "todoapp" ]
            [ header [ class "header" ]
                [ h1 [] [ text "todos" ]
                , input
                    [ class "new-todo"
                    , placeholder "What needs to be done?"
                    , value model.todo.title
                    , autofocus True
                    , onInput UpdateField
                    , onEnter Add
                    ]
                    []
                ]
            , section [ class "main" ]
                [ ul [ class "todo-list" ]
                    (List.map todoView (filteredTodos model))
                ]
            , footer [ class "footer" ]
                [ span [ class "todo-count" ]
                    [ strong
                        []
                        [ text
                            (List.filter
                                (\todo -> todo.completed == False)
                                model.todos
                                |> List.length
                                |> toString
                            )
                        ]
                    , text " item(s) left"
                    ]
                , ul [ class "filters" ]
                    [ filterItemView model All
                    , filterItemView model Active
                    , filterItemView model Completed
                    ]
                , button
                    [ class "clear-completed"
                    , onClick ClearCompleted
                    ]
                    [ text "Clear completed" ]
                ]
            ]
        ]


todoView : Todo -> Html Msg
todoView todo =
    let
        handleComplete =
            case todo.completed of
                True ->
                    \_ -> Uncomplete todo

                False ->
                    \_ -> Complete todo
    in
    li [ classList [ ( "completed", todo.completed ) ] ]
        [ div [ class "view" ]
            [ input
                [ class "toggle"
                , type_ "checkbox"
                , checked todo.completed
                , onCheck handleComplete
                ]
                []
            , label [] [ text todo.title ]
            , button
                [ class "destroy"
                , onClick (Delete todo)
                ]
                []
            ]
        ]


filterItemView : Model -> FilterState -> Html Msg
filterItemView model filterState =
    li []
        [ a
            [ classList [ ( "selected", model.filter == filterState ) ]
            , href "#"
            , onClick (Filter filterState)
            ]
            [ text (filterState |> toString) ]
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


mapStorageInput : Decode.Value -> Msg
mapStorageInput modelJson =
    let
        model =
            initialModel
    in
    SetModel model


sendToStorage : Model -> Cmd Msg
sendToStorage model =
    encodeJson model |> storage



-- JSON ENCODING


encodeJson : Model -> Encode.Value
encodeJson model =
    Encode.object
        [ ( "todos", Encode.list (List.map encodeTodo model.todos) )
        , ( "todo", encodeTodo model.todo )
        , ( "filter", encodeFilterState model.filter )
        , ( "nextId", Encode.int model.nextId )
        ]


encodeTodo : Todo -> Encode.Value
encodeTodo todo =
    Encode.object
        [ ( "title", Encode.string todo.title )
        , ( "completed", Encode.bool todo.completed )
        , ( "editing", Encode.bool todo.editing )
        , ( "id", Encode.int todo.id )
        ]


encodeFilterState : FilterState -> Encode.Value
encodeFilterState filterState =
    Encode.string (filterState |> toString)



-- INPUT PORTS


port storageInput : (Decode.Value -> msg) -> Sub msg



-- OUTPUT PORTS


port storage : Encode.Value -> Cmd msg


styles : String
styles =
    """
    html,
    body {
      margin: 0;
      padding: 0;
    }

    button {
      margin: 0;
      padding: 0;
      border: 0;
      background: none;
      font-size: 100%;
      vertical-align: baseline;
      font-family: inherit;
      font-weight: inherit;
      color: inherit;
      -webkit-appearance: none;
      appearance: none;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }

    body {
      font: 14px 'Helvetica Neue', Helvetica, Arial, sans-serif;
      line-height: 1.4em;
      background: #f5f5f5;
      color: #4d4d4d;
      min-width: 230px;
      max-width: 550px;
      margin: 0 auto;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
      font-weight: 300;
    }

    :focus {
      outline: 0;
    }

    .hidden {
      display: none;
    }

    .todoapp {
      background: #fff;
      margin: 130px 0 40px 0;
      position: relative;
      box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2),
      0 25px 50px 0 rgba(0, 0, 0, 0.1);
    }

    .todoapp input::-webkit-input-placeholder {
      font-style: italic;
      font-weight: 300;
      color: #e6e6e6;
    }

    .todoapp input::-moz-placeholder {
      font-style: italic;
      font-weight: 300;
      color: #e6e6e6;
    }

    .todoapp input::input-placeholder {
      font-style: italic;
      font-weight: 300;
      color: #e6e6e6;
    }

    .todoapp h1 {
      position: absolute;
      top: -155px;
      width: 100%;
      font-size: 100px;
      font-weight: 100;
      text-align: center;
      color: rgba(175, 47, 47, 0.15);
      -webkit-text-rendering: optimizeLegibility;
      -moz-text-rendering: optimizeLegibility;
      text-rendering: optimizeLegibility;
    }

    .new-todo,
    .edit {
      position: relative;
      margin: 0;
      width: 100%;
      font-size: 24px;
      font-family: inherit;
      font-weight: inherit;
      line-height: 1.4em;
      border: 0;
      color: inherit;
      padding: 6px;
      border: 1px solid #999;
      box-shadow: inset 0 -1px 5px 0 rgba(0, 0, 0, 0.2);
      box-sizing: border-box;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }

    .new-todo {
      padding: 16px 16px 16px 60px;
      border: none;
      background: rgba(0, 0, 0, 0.003);
      box-shadow: inset 0 -2px 1px rgba(0,0,0,0.03);
    }

    .main {
      position: relative;
      z-index: 2;
      border-top: 1px solid #e6e6e6;
    }

    .toggle-all {
      text-align: center;
      border: none; /* Mobile Safari */
      opacity: 0;
      position: absolute;
    }

    .toggle-all + label {
      width: 60px;
      height: 34px;
      font-size: 0;
      position: absolute;
      top: -52px;
      left: -13px;
      -webkit-transform: rotate(90deg);
      transform: rotate(90deg);
    }

    .toggle-all + label:before {
      content: '❯';
      font-size: 22px;
      color: #e6e6e6;
      padding: 10px 27px 10px 27px;
    }

    .toggle-all:checked + label:before {
      color: #737373;
    }

    .todo-list {
      margin: 0;
      padding: 0;
      list-style: none;
    }

    .todo-list li {
      position: relative;
      font-size: 24px;
      border-bottom: 1px solid #ededed;
    }

    .todo-list li:last-child {
      border-bottom: none;
    }

    .todo-list li.editing {
      border-bottom: none;
      padding: 0;
    }

    .todo-list li.editing .edit {
      display: block;
      width: 506px;
      padding: 12px 16px;
      margin: 0 0 0 43px;
    }

    .todo-list li.editing .view {
      display: none;
    }

    .todo-list li .toggle {
      text-align: center;
      width: 40px;
      /* auto, since non-WebKit browsers doesn't support input styling */
      height: auto;
      position: absolute;
      top: 0;
      bottom: 0;
      margin: auto 0;
      border: none; /* Mobile Safari */
      -webkit-appearance: none;
      appearance: none;
    }

    .todo-list li .toggle {
      opacity: 0;
    }

    .todo-list li .toggle + label {
      /*
      Firefox requires `#` to be escaped - https://bugzilla.mozilla.org/show_bug.cgi?id=922433
      IE and Edge requires *everything* to be escaped to render, so we do that instead of just the `#` - https://developer.microsoft.com/en-us/microsoft-edge/platform/issues/7157459/
      */
      background-image: url('data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A//www.w3.org/2000/svg%22%20width%3D%2240%22%20height%3D%2240%22%20viewBox%3D%22-10%20-18%20100%20135%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22none%22%20stroke%3D%22%23ededed%22%20stroke-width%3D%223%22/%3E%3C/svg%3E');
      background-repeat: no-repeat;
      background-position: center left;
    }

    .todo-list li .toggle:checked + label {
      background-image: url('data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A//www.w3.org/2000/svg%22%20width%3D%2240%22%20height%3D%2240%22%20viewBox%3D%22-10%20-18%20100%20135%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22none%22%20stroke%3D%22%23bddad5%22%20stroke-width%3D%223%22/%3E%3Cpath%20fill%3D%22%235dc2af%22%20d%3D%22M72%2025L42%2071%2027%2056l-4%204%2020%2020%2034-52z%22/%3E%3C/svg%3E');
    }

    .todo-list li label {
      word-break: break-all;
      padding: 15px 15px 15px 60px;
      display: block;
      line-height: 1.2;
      transition: color 0.4s;
    }

    .todo-list li.completed label {
      color: #d9d9d9;
      text-decoration: line-through;
    }

    .todo-list li .destroy {
      display: none;
      position: absolute;
      top: 0;
      right: 10px;
      bottom: 0;
      width: 40px;
      height: 40px;
      margin: auto 0;
      font-size: 30px;
      color: #cc9a9a;
      margin-bottom: 11px;
      transition: color 0.2s ease-out;
    }

    .todo-list li .destroy:hover {
      color: #af5b5e;
    }

    .todo-list li .destroy:after {
      content: '×';
    }

    .todo-list li:hover .destroy {
      display: block;
    }

    .todo-list li .edit {
      display: none;
    }

    .todo-list li.editing:last-child {
      margin-bottom: -1px;
    }

    .footer {
      color: #777;
      padding: 10px 15px;
      height: 20px;
      text-align: center;
      border-top: 1px solid #e6e6e6;
    }

    .footer:before {
      content: '';
      position: absolute;
      right: 0;
      bottom: 0;
      left: 0;
      height: 50px;
      overflow: hidden;
      box-shadow: 0 1px 1px rgba(0, 0, 0, 0.2),
      0 8px 0 -3px #f6f6f6,
      0 9px 1px -3px rgba(0, 0, 0, 0.2),
      0 16px 0 -6px #f6f6f6,
      0 17px 2px -6px rgba(0, 0, 0, 0.2);
    }

    .todo-count {
      float: left;
      text-align: left;
    }

    .todo-count strong {
      font-weight: 300;
    }

    .filters {
      margin: 0;
      padding: 0;
      list-style: none;
      position: absolute;
      right: 0;
      left: 0;
    }

    .filters li {
      display: inline;
    }

    .filters li a {
      color: inherit;
      margin: 3px;
      padding: 3px 7px;
      text-decoration: none;
      border: 1px solid transparent;
      border-radius: 3px;
    }

    .filters li a:hover {
      border-color: rgba(175, 47, 47, 0.1);
    }

    .filters li a.selected {
      border-color: rgba(175, 47, 47, 0.2);
    }

    .clear-completed,
    html .clear-completed:active {
      float: right;
      position: relative;
      line-height: 20px;
      text-decoration: none;
      cursor: pointer;
    }

    .clear-completed:hover {
      text-decoration: underline;
    }

    .info {
      margin: 65px auto 0;
      color: #bfbfbf;
      font-size: 10px;
      text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5);
      text-align: center;
    }

    .info p {
      line-height: 1;
    }

    .info a {
      color: inherit;
      text-decoration: none;
      font-weight: 400;
    }

    .info a:hover {
      text-decoration: underline;
    }

    /*
    Hack to remove background from Mobile Safari.
    Can't use it globally since it destroys checkboxes in Firefox
    */
    @media screen and (-webkit-min-device-pixel-ratio:0) {
      .toggle-all,
      .todo-list li .toggle {
        background: none;
      }

      .todo-list li .toggle {
        height: 40px;
      }
    }

    @media (max-width: 430px) {
      .footer {
        height: 50px;
      }

      .filters {
        bottom: 10px;
      }
    }
"""
