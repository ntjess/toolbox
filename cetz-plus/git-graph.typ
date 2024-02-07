#import "@preview/cetz:0.2.0"
#let d = cetz.draw

#let offset(anchor, x: 0, y: 0) = {
  (v => cetz.vector.add(v, (x, y)), anchor)
}
#let default-colors = (red, orange, yellow, green, blue, purple, fuchsia, gray)
#let color-boxed(..args) = {
  set text(0.8em)
  box(
    inset: (y: 0.25em, x: 0.1em),
    fill: yellow.lighten(80%),
    stroke: black + 0.5pt,
    radius: 0.2em,
    ..args
  )
}
#let _layers = (
  LANES: -4,
  BRANCH: -3,
  GRAPH: -2,
  COMMIT: 1,
  TAG: 1,
)

#let _git-graph-defaults = (
  default-branch-colors: default-colors,
  branches: (:),
  active-branch: "main",
  commit-id: 0,
  commit-spacing: 0.8,
  ref-branch-map: (:),
  lane-spacing: 2,
  lane-style: (
    stroke: (paint: gray, dash: "dashed")
  ),
  graph-style: (
    stroke: (thickness: 0.25em),
    radius: 0.25
  ),
  commit-style: (
    decorator: color-boxed,
    spacing: 0.8,
    angle: 45deg,
  ),
  tag-style: (
    decorator: color-boxed.with(fill: blue.lighten(75%), stroke: black),
    angle: -45deg
  ),
)

#let _is-empty(content) = {
  content == "" or content == [] or content.has("text") and content.text == ""
}

#let graph-props(func) = {
  d.get-ctx(ctx => {
    let props = ctx.git-graph
    props.ctx = ctx
    func(props)
  })
}

#let set-graph-props(func) = {
  d.set-ctx(ctx => {
    ctx.git-graph = func(ctx.git-graph)
    ctx
  })
}

#let branch-props(func, branch: auto) = {
  graph-props(props => {
    let branch = branch
    if branch == auto {
      branch = props.active-branch
    }
    if branch not in props.branches {
      panic("Branch `" + branch + "` does not exist")
    }
    let sub-props = props.branches.at(branch)
    props.name = branch
    func(props + sub-props)
  })
}

#let background-lanes() = {
  graph-props(props => {
    for (name, branch-props) in props.branches.pairs() {
      let (ctx, latest-commit) = cetz.coordinate.resolve(props.ctx, "head")
      let end = offset(name, y: latest-commit.at(1) - props.commit-spacing)
      d.on-layer(_layers.LANES, d.line(name, end, ..props.lane-style, anchor: "north"))
    }
  })
}

#let _branch-line(src, dst, color) = {
  // Easier than a merge line since src is guaranteed to be left of dst
  graph-props(props => {
    let ctx = props.ctx
    let (ctx, a, b) = cetz.coordinate.resolve(ctx, src, dst)
    assert(
      a.at(0) < b.at(0) and a.at(1) >= b.at(1),
      message: "source branch must start before destination branch"
    )
    let radius = props.graph-style.radius
    let stroke = (stroke: (paint: color, ..props.graph-style.stroke))
    d.line(offset(b, y: -b.at(1)), b, ..stroke)
    d.merge-path(..stroke, {
    d.line(
      src, (b.at(0) - radius, a.at(1)),
    )
    d.arc((), start: 90deg, delta: -90deg, radius: radius)
    })
  })
}

#let branch(name, color: auto, colors: default-colors) = {
  if type(name) != str {
    name = name.text
  }
  set-graph-props(props => {
    let branches = props.branches
    if name in branches {
      panic("Branch `" + name + "` already exists")
    }
    let color = color
    let n-cur = branches.len()
    if color == auto {
      color = colors.at(calc.rem(n-cur, colors.len()))
    }
    branches.insert(name, (fill: color, lane: n-cur))
    props.branches = branches
    props.head = name
    props.active-branch = name
    props
  })
  let styled(..args) = {
    set text(weight: "bold", fill: white)
    rect(radius: 0.25em, ..args)
  }
  branch-props(props => {
    d.content((props.lane * props.lane-spacing, 0), styled(name, fill: props.branches.at(name).fill), name: name, anchor: "west")
  })
  branch-props(props => {
    let new-head = name
    if props.commit-id > 0 {
      let (_, head-pos, lane-pos) = cetz.coordinate.resolve(props.ctx, "head", name)
      let join-loc = (lane-pos.at(0), head-pos.at(1) - props.commit-spacing)
      if head-pos.at(1) < 0 {
        d.on-layer(-props.lane + _layers.BRANCH, _branch-line("head", join-loc, props.fill))
      }
      new-head = (lane-pos.at(0), head-pos.at(1))
    }
    d.anchor("head", new-head)
    d.anchor(name + "/head", new-head)
  })
}

#let checkout(branch) = {
  set-graph-props(props => {
    if branch not in props.branches {
      panic("Branch `" + branch + "` does not exist")
    }
    props.active-branch = branch
    props
  })

  d.get-ctx(ctx => {
    d.anchor("head", branch + "/head")
  })
}

#let commit(message, branch: auto) = {
  if branch != auto {
    checkout(branch)
  }
  set-graph-props(props => {
    props.commit-id = props.commit-id + 1
    props.ref-branch-map.insert(str(props.commit-id), props.active-branch)
    props
  })
  let on-graph = d.on-layer.with(_layers.GRAPH)
  let on-branch = d.on-layer.with(_layers.BRANCH)
  branch-props(props => {
    let txt = props.commit-style.at("decorator")(message)
    let (_, lane-pos) = cetz.coordinate.resolve(props.ctx, "head")
    d.anchor("head", (lane-pos.at(0), -props.commit-id * props.commit-spacing))
    on-graph(d.content("head", circle(fill: props.fill, radius: 0.5em), name: "circ"))
    on-branch(
      d.line(props.name, "head", stroke: (paint: props.fill, ..props.graph-style.stroke))
    )
    if not _is-empty(message) {
      let rot = props.commit-style.at("angle")
      d.content("circ.south-west", txt, anchor: "east", angle: rot)
    }
  })
  graph-props(props => {
    d.anchor(props.active-branch + "/head", "head")
    d.anchor("commit-id-" + str(props.commit-id), "head")
  })

}

#let tag(message) = {
  graph-props(props => {
    let txt = props.tag-style.at("decorator")(message)
    let rot = props.tag-style.at("angle")
    d.content("head", txt, anchor: "west", angle: rot, padding: 0.75em)
  })
}

#let _merge-line(src, dest, color) = {
  // A line with a quarter-circle turn from src to dest branch
  let radius = 0.5em
  graph-props(props => {
    let ctx = props.ctx
    let (ctx, a, b) = cetz.coordinate.resolve(ctx, src, dest)
    assert(
      calc.abs(a.at(1)) < calc.abs(b.at(1)),
      message: "Destination branch must be below source branch"
    )
    let radius = props.graph-style.radius
    let p = d.merge-path(stroke: (paint: color, ..props.graph-style.stroke), {
      d.line(src, (a.at(0), b.at(1) + radius))
      if a.at(0) < b.at(0) {
        d.arc((), start: 180deg, delta: 90deg, radius: radius)
      } else {
        d.arc((), start: 0deg, delta: -90deg, radius: radius)
      }
      d.line((), b)
    })
    d.on-layer(_layers.BRANCH, p)
  })
}

#let merge(commit-id, message: []) = {
  commit(message)
  d.on-layer(_layers.GRAPH, d.circle((), radius: 0.35em, fill: white, stroke: none))
  graph-props(props => {
    let commit-id = commit-id
    let refs = props.ref-branch-map
    if commit-id.replace("/head", "") in props.branches {
      commit-id = commit-id + "/head"
      refs.insert(commit-id, commit-id.split("/").at(0))
    } else if commit-id not in refs {
      panic("Commit ref `" + commit-id + "` does not exist")
    }
    let src-branch = refs.at(commit-id)
    if src-branch == props.active-branch {
      panic(
        "Cannot merge branch into itself. head is already at `" + src-branch
        + "`, and commit `" + commit-id + "` belongs to the same branch.
        Perhaps you forgot to checkout a different branch before merging?"
      )
    }
    let branch-props = props.branches.at(src-branch)
    _merge-line(commit-id, "head", branch-props.fill)
  })

}


#let git-graph(graph, name: none, ..style) = {
  d.set-ctx(ctx => {
    ctx.git-graph = _git-graph-defaults
    ctx
  })
  d.group(name: name, graph)
}

// Usage:
/*
#cetz.canvas({
  git-graph({
    branch[main]
    commit[initial commit]
    branch[feature]
    branch[feature2]

    // Or pass branch instead of checking out
    commit(branch: "feature")[commit 1]
    commit(branch: "feature2")[commit 2]
    // git-graph remembers its branch if none is specified
    commit[commit 3]
    
    checkout("main")
    branch[hotfix]
    commit[bugfix]


    checkout("feature")
    merge("hotfix", message: [apply hotfix])

    checkout("main")
    merge("feature", message: [merge feature])
    tag[v1.0.0]
    
    checkout("feature2")
    merge("main")
    commit[commit 4]

    checkout("main")
    merge("feature2")
    tag[v2.0.0rc1]

    background-lanes()
  })
})
*/