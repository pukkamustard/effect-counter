module Main exposing (..)

import Counter


--

import Return exposing (Return)


--

import Html as H
import Html.Attributes as HA
import Html.Events as HE


main : Program Never Model Msg
main =
    H.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    Int


init : Return Msg Model
init =
    0
        |> Return.singleton



-- UPDATE


type Msg
    = Counter Int
    | Reset


update : Msg -> Model -> Return Msg Model
update msg model =
    case msg of
        Counter value ->
            value
                |> Return.singleton

        Reset ->
            model
                |> Return.singleton
                |> Return.command (Counter.reset)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Counter.counter Counter



-- VIEW


view : Model -> H.Html Msg
view model =
    H.div []
        [ H.div [ HA.id "counter" ] [ model |> toString |> H.text ]
        , H.button [ HA.id "reset", HE.onClick Reset ] [ H.text "Reset" ]
        ]
