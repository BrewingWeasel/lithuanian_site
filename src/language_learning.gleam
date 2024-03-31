import gleam/uri.{type Uri}
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/effect.{type Effect}
import lustre/event
import modem
import plinth/javascript/console
import gleam/string
import gleam/list

pub fn main() {
  lustre.application(init, update, view)
}

pub type Route {
  Conjugation(word: Option(String), next_word: String)
  Guide(name: String)
  Home
}

fn init(_) -> #(Route, Effect(Msg)) {
  #(Home, modem.init(on_url_change))
}

fn on_url_change(uri: Uri) -> Msg {
  case uri.path_segments(uri.path) {
    ["conjugate", word] -> OnRouteChange(Conjugation(Some(word), ""))
    ["conjugate"] -> OnRouteChange(Conjugation(None, ""))
    ["guide", page] -> OnRouteChange(Guide(page))
    _ -> OnRouteChange(Home)
  }
}

pub type Msg {
  OnRouteChange(Route)
  UpdateText(String)
  Conjugate(String)
}

fn update(old_route: Route, msg: Msg) -> #(Route, Effect(Msg)) {
  case msg {
    OnRouteChange(route) -> #(route, effect.none())
    UpdateText(searching) -> {
      let assert Conjugation(word, _) = old_route
      #(Conjugation(word, searching), effect.none())
    }
    Conjugate(verb) -> {
      console.log(verb)
      let assert Ok(uri) = uri.parse("http://localhost:1234/conjugate/" <> verb)
      #(Conjugation(Some(verb), ""), modem.push(uri))
    }
  }
}

fn navigation_item(location: String, name: String) {
  html.a(
    [
      attribute.href("/" <> location),
      attribute.class(
        "hover:underline decoration-pink-500 decoration-2 hover:bg-violet-300/75 rounded-md py-1 px-2 drop-shadow-sm",
      ),
    ],
    [element.text(name)],
  )
}

type Tense {
  Present
  Past
  Future
  Subjunctive
  PastFrequentative
  Imperative
}

type Verb {
  VerbInfo(infinitive: String, pres3: String, past3: String)
}

fn draw_conjugations(verb: String) {
  let verb_info = get_verb_details(verb)
  html.div([attribute.class("flex justify-center")], [
    html.div([attribute.class("bg-violet-400 p-[0.15rem] rounded-md")], [
      html.table([attribute.class("table-auto")], [
        html.thead(
          [],
          list.map(["", "aš", "tu", "jis/ji", "mes", "jūs", "jie/jos"], fn(x) {
            html.th(
              [
                attribute.class(
                  "bg-violet-200 border border-violet-400 hover:bg-violet-300 px-6",
                ),
              ],
              [element.text(x)],
            )
          }),
        ),
        html.tbody(
          [attribute.class("text-center")],
          list.map(
            [Present, Past, Future, Subjunctive, PastFrequentative, Imperative],
            fn(tense) {
              html.tr([], [
                create_tense_table(tense),
                ..conjugate(verb: verb_info, with: tense)
                |> list.map(fn(x) {
                  html.td(
                    [
                      attribute.class(
                        "bg-violet-100 hover:bg-violet-200 border border-violet-300 px-1",
                      ),
                    ],
                    [element.text(x)],
                  )
                })
              ])
            },
          ),
        ),
      ]),
    ]),
  ])
}

fn create_tense_table(tense: Tense) {
  html.td(
    [
      attribute.class(
        "bg-violet-200 font-bold px-3 border border-violet-400 hover:bg-violet-300",
      ),
    ],
    [
      element.text(case tense {
        Present -> "Present"
        Past -> "Past"
        Future -> "Future"
        Subjunctive -> "Subjunctive"
        PastFrequentative -> "Past Frequentative"
        Imperative -> "Imperative"
      }),
    ],
  )
}

fn get_verb_details(verb: String) -> Verb {
  VerbInfo(infinitive: verb, past3: "ėjo", pres3: "eina")
}

type ConjugationGroup {
  FirstGroup
  SecondGroup
  ThirdGroup
}

fn conjugate(verb verb: Verb, with tense: Tense) -> List(String) {
  let conjugation_group = case string.last(verb.pres3) {
    Ok("a") -> FirstGroup
    Ok("i") -> SecondGroup
    _ -> ThirdGroup
  }
  let pres_ending = string.drop_right(verb.pres3, 1)
  let past_ending = string.drop_right(verb.past3, 1)
  let infintive_stem = string.drop_right(verb.infinitive, 2)
  case tense {
    Present -> {
      [
        pres_ending <> "u",
        case conjugation_group == ThirdGroup {
          True -> pres_ending <> "ai"
          False -> pres_ending <> "i"
        },
        verb.pres3,
        verb.pres3 <> "me",
        verb.pres3 <> "te",
        verb.pres3,
      ]
    }
    Past -> {
      [
        case conjugation_group == ThirdGroup {
          True -> past_ending <> "iau"
          False -> past_ending <> "au"
        },
        case conjugation_group == ThirdGroup {
          True -> past_ending <> "ei"
          False -> past_ending <> "ai"
        },
        verb.past3,
        verb.past3 <> "me",
        verb.past3 <> "te",
        verb.past3,
      ]
    }
    Future -> {
      // TODO: short vowel change
      [
        infintive_stem <> "siu",
        infintive_stem <> "si",
        infintive_stem <> "s",
        infintive_stem <> "sime",
        infintive_stem <> "site",
        infintive_stem <> "s",
      ]
    }
    PastFrequentative -> {
      [
        infintive_stem <> "davau",
        infintive_stem <> "davai",
        infintive_stem <> "davo",
        infintive_stem <> "davome",
        infintive_stem <> "davote",
        infintive_stem <> "davo",
      ]
    }
    Imperative -> {
      [
        "-",
        infintive_stem <> "k",
        "te" <> verb.pres3,
        infintive_stem <> "kime",
        infintive_stem <> "kite",
        "te" <> verb.pres3,
      ]
    }
    Subjunctive -> {
      [
        infintive_stem <> "čiau",
        infintive_stem <> "tum",
        infintive_stem <> "tų",
        infintive_stem <> "tumėme",
        infintive_stem <> "tumėte",
        infintive_stem <> "tų",
      ]
    }
  }
}

fn view(route: Route) -> Element(Msg) {
  // html.div([attribute.class("bg-violet-800 text-violet-100 h-screen")], [
  html.div([attribute.class("bg-violet-100 text-violet-600 h-screen")], [
    html.nav([attribute.class("bg-violet-300/50 px-3 py-2")], [
      html.div([attribute.class("space-x-3")], [
        navigation_item("home", "Home"),
        navigation_item("guide/intro", "Guide"),
        navigation_item("conjugate", "Conjugation"),
      ]),
    ]),
    case route {
      Home -> html.h1([], [])
      Conjugation(verb, searching) ->
        html.div([attribute.class("my-5")], [
          html.div([attribute.class("flex justify-center text-base")], [
            html.input([
              attribute.class(
                "rounded-l-full bg-violet-200 text-violet-800 py-2 px-4 shadow-md",
              ),
              attribute.value(searching),
              event.on_input(UpdateText),
            ]),
            html.button(
              [
                attribute.class(
                  "rounded-r-full bg-violet-400 text-slate-50 py-2 px-3 shadow-md",
                ),
                event.on_click(Conjugate(searching)),
              ],
              [element.text("Conjugate")],
            ),
          ]),
          case verb {
            Some(v) ->
              html.div([], [
                html.div([attribute.class("flex justify-center")], [
                  html.h1(
                    [
                      attribute.class(
                        "text-3xl font-extrabold text-violet-900 my-3 drop-shadow-sm hover:drop-shadow-md",
                      ),
                    ],
                    [element.text(v)],
                  ),
                ]),
                draw_conjugations(v),
              ])
            None ->
              html.div([], [
                html.h2([], [element.text("Check out these verbs:")]),
                html.a([attribute.href("/conjugate/imti")], [
                  element.text("imti"),
                ]),
              ])
          },
        ])
      Guide(page) -> html.h1([], [element.text("You're on " <> page)])
    },
  ])
}
