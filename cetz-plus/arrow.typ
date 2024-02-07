#import "@preview/cetz:0.2.0"
#import cetz.draw: *
#let _cetz-anchor = anchor


#let arrow-default-style = (
  body-size: (5, 2),
  head-size: (4, 2),
  direction: ltr,
)
#let arrow(pt, name: none, anchor: none, ..style) = {
  get-ctx(ctx => {
    move-to(pt)
    let style = resolve(
      ctx.style, merge: style.named(), root: "arrow", base: arrow-default-style
    )

    let dir-rotation-map = (
      ltr: 0deg,
      rtl: 180deg,
      ttb: 90deg,
      btt: -90deg,
    )
    let angle = dir-rotation-map.at(repr(style.direction))
    rotate(angle)
    if style.direction in (ttb, btt) {
      // Swap width and height
      style.body-size = style.body-size.rev()
      style.head-size = style.head-size.rev()
    }

    let (body-w, body-h) = style.body-size
    let (head-w, head-h) = style.head-size
    head-w += body-w
    let p = (
      body-north-west: (0, body-h/2),
      body-south-west: (0, -body-h/2),
      body-south-east: (body-w, -body-h/2),
      body-north-east: (body-w, body-h/2),
      head-north: (body-w, head-h),
      head-south: (body-w, -head-h),
      tip: (head-w, 0),
      base: (0,0),
      body-west: (0,0),
      body-east: (body-w, 0),
    )
    p.body-south = vector.lerp(p.body-south-west, p.body-south-east, 0.5)
    p.body-north = vector.lerp(p.body-north-west, p.body-north-east, 0.5)
    group(name: name, anchor: anchor, {
      merge-path(..style, {
        line((0,0), p.body-north-west, p.body-north-east, p.head-north, p.tip, name: "arrow-top")
        line((), p.head-south, p.body-south-east, p.body-south-west, (0,0), name: "arrow-bottom")
      })
      on-layer(-1, {
        // Put in groups so anchors automatically align with rotation
        group(name: "body", {
          rect(p.body-north-east, p.body-south-west, stroke: none, fill: none)
        })
        group(name: "head", {
          line(p.head-south, p.head-north, p.tip, name: "head", stroke: none, fill: none)
        })
      })
      for name in ("tip", "base") {
        _cetz-anchor(name, p.at(name))
      }
      for name in ("body", "head") {
        for-each-anchor(name, anchor => {
          _cetz-anchor(name + "-" + anchor, name + "." + anchor)
        })
      }
    })
  })
}

// Sample usage:
/*
#cetz.canvas({
  cetz.draw.content((), [hello world])
  arrow((), head-size: (6, 3), body-size: (6, 2), name: "arrow", anchor: "south", direction: rtl)
  for-each-anchor("arrow", anchor => {
    anchor = anchor.replace("-", "\n")
    content((), angle: -45deg, box(fill: rgb("#fff6"), inset: 0.1em, text(size: 8pt, anchor)))
  })
  circle("arrow.tip", radius: 0.1)
})

*/