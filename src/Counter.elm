effect module Counter
    where { command = MyCmd, subscription = MySub }
    exposing
        ( counter
        , reset
        )

import Json.Decode as JD
import Dom.LowLevel as Dom
import Task exposing (Task)
import Process
import Platform


-- Subscriptions


type MySub msg
    = MySub (Int -> msg)


counter : (Int -> msg) -> Sub msg
counter tagger =
    subscription (MySub tagger)


subMap : (a -> b) -> MySub a -> MySub b
subMap f (MySub tagger) =
    MySub (tagger >> f)



-- Commands


type MyCmd msg
    = Reset


reset : Cmd msg
reset =
    command Reset


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ Reset =
    Reset



-- Effect Manager


type Msg
    = KeyCode Int


type alias State msg =
    { counter : Int
    , subs : List (MySub msg)
    , pid : Maybe Process.Id
    }


keyCode : JD.Decoder Int
keyCode =
    JD.field "keyCode" JD.int


init : Task Never (State msg)
init =
    Task.succeed
        { counter = 0
        , subs = []
        , pid = Nothing
        }


onEffects : Platform.Router msg Msg -> List (MyCmd msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs state =
    handleSubs router subs state
        |> Task.andThen (handleCmds router cmds)


{-| Helper to handle commands
-}
handleCmds : Platform.Router msg Msg -> List (MyCmd msg) -> State msg -> Task Never (State msg)
handleCmds router cmds state =
    case cmds of
        [] ->
            Task.succeed state

        -- All resets can be combined to one reset
        _ ->
            Task.succeed { state | counter = 0 }
                |> Task.andThen (emit router)


{-| Helper to handle subs
-}
handleSubs : Platform.Router msg Msg -> List (MySub msg) -> State msg -> Task Never (State msg)
handleSubs router subs state =
    case ( subs, state.pid ) of
        ( [], Nothing ) ->
            Task.succeed { state | subs = subs }

        ( [], Just pid ) ->
            Process.kill pid
                |> Task.andThen
                    (\_ -> Task.succeed { state | subs = subs, pid = Nothing })

        ( _, Nothing ) ->
            Process.spawn (Dom.onDocument "keydown" keyCode (\keycode -> Platform.sendToSelf router (KeyCode keycode)))
                |> Task.andThen
                    (\pid ->
                        Task.succeed { state | subs = subs, pid = Just pid }
                    )

        ( _, Just pid ) ->
            Task.succeed { state | subs = subs }


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router msg state =
    case msg of
        -- Up
        KeyCode 38 ->
            Task.succeed { state | counter = state.counter + 1 }
                |> Task.andThen (emit router)

        -- Down
        KeyCode 40 ->
            Task.succeed { state | counter = state.counter - 1 }
                |> Task.andThen (emit router)

        KeyCode _ ->
            Task.succeed state


{-| Helper to emit counter value to subs
-}
emit : Platform.Router msg Msg -> State msg -> Task Never (State msg)
emit router ({ subs, counter } as state) =
    subs
        |> List.map
            (\(MySub tagger) ->
                Platform.sendToApp router (tagger counter)
            )
        |> Task.sequence
        |> Task.andThen (\_ -> Task.succeed state)
