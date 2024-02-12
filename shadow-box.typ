#import "@preview/oxifmt:0.2.0": strfmt

#let oxi-template = `
<svg width="{canvas-width}" height="{canvas-height}" xmlns="http://www.w3.org/2000/svg">
  <!-- Definitions for reusable components -->
  <defs>
    <filter
       id="shadow" >
      <feFlood
         flood-opacity="{flood-opacity}"
         flood-color="{flood-color}" />
      <feComposite
         in2="SourceGraphic"
         operator="in" />
      <feGaussianBlur
         stdDeviation="{blur}"
         result="blur" />
    </filter>
  </defs>

  <rect x="{x}" y="{y}" rx="{radius:?}" ry="{radius:?}" width="{width}" height="{height}" style="filter:url(#shadow)"/>
</svg>
`.text

#let shadow-box(
  content,
  shadow-fill: black,
  opacity: 0.5,
  dx: 0pt,
  dy: 0pt,
  radius: 0pt,
  blur: 10,
  blur-margin: 5,
  ..args,
) = {
  style(styles => layout(size => {
    let named = args.named()
    for key in ("width", "height") {
      if key in named and type(named.at(key)) == ratio {
        named.insert(key, size.at(key) * named.at(key))
      }
    }
    let radius = radius
    if type(radius) != ratio {
      radius = measure(h(radius), styles).width
    }
    let opts = (blur: blur, radius: radius)
    let shadow-fill = shadow-fill.rgb().components().map(el => el/100% * 255)
    opts.flood-color = strfmt("rgb({}, {}, {}, {})", ..shadow-fill)
    let content = box(content, radius: radius, ..named)
    let size = measure(content, styles)
    let margin = opts.blur * blur-margin * 1pt
    opts += (
      ..size, x: margin/2, y: margin/2,
      canvas-width: margin + size.width,
      canvas-height: margin + size.height,
      flood-opacity: opacity
    )
    let svg-shadow = image.decode(strfmt(oxi-template, ..opts), ..size)
    place(dx: dx, dy: dy, svg-shadow)
    content
  }))
}
