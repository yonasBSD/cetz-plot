#import "/src/lib.typ"

#import "@preview/tidy:0.4.3"
#import "@preview/t4t:0.3.2": is

#let show-function(fn, style-args) = {
  [
    #heading(fn.name, level: style-args.first-heading-level + 1)
    #label(style-args.label-prefix + fn.name + "()")
  ]
  let description = if is.sequence(fn.description) {
    fn.description.children
  } else {
    (fn.description,)
  }
  let parameter-index = description.position(e => {
    e.func() == heading and e.body == [parameters]
  })

  description = description.map(e => if e.func() == heading {
    let fields = e.fields()
    let label = fields.remove("label", default: none)
    heading(offset: style-args.first-heading-level + 1, fields.remove("body"), ..fields); [#label]
  } else { e })
  
  if parameter-index != none {
    description.slice(0, parameter-index).join()
  } else {
    description.join()
  }

  set heading(level: style-args.first-heading-level + 2)

  if fn.args.len() != 0 {
    block(breakable: style-args.break-param-descriptions, {
      heading("Parameters", level: style-args.first-heading-level + 2)
      (style-args.style.show-parameter-list)(fn, style-args.style.show-type)
    })

    for (name, info) in fn.args {
      let types = info.at("types", default: ())
      let description = info.at("description", default: "")
      if description == [] and style-args.omit-empty-param-descriptions { continue }
      (style-args.style.show-parameter-block)(
        name, types, description, 
        style-args,
        show-default: "default" in info, 
        default: info.at("default", default: none),
      )
    }
  }

  if parameter-index != none {
    description.slice(parameter-index+1).join()
  }
}

#let show-parameter-block(name, types, content, show-default: true, default: none, in-tidy: false, ..a) = {
  if type(types) != array {
    types = (types,)
  }
  stack(dir: ttb, spacing: 1em,
    // name <type>     Default: <default>
    block(breakable: false, width: 100%, stack(dir: ltr,
      [#text(weight: "bold", name + [:]) #types.map(tidy.styles.default.show-type.with(style-args: tidy.styles.default)).join(" or ")],
      if show-default {
        align(right)[
          Default: #raw(
            lang: "typc",
            // Tidy gives defaults as strings but outside of tidy we pass defaults as the actual values
            if in-tidy { default } else { repr(default) }
          )
        ]
      }
      )),
    // text
    block(inset: (left: .4cm), content)
  )
}

#let parse-show-module(path) = {
  tidy.show-module(
    tidy.parse-module(
      read(path),
      scope: (
        show-parameter-block: show-parameter-block,
        cetz: lib
      )
    ),
    first-heading-level: 1,
    show-outline: false,
    sort-functions: none,
  )
}
