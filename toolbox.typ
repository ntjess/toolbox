#import "./cetz-plus/arrow.typ": arrow
#import "./cetz-plus/git-graph.typ"
#import "./shadow-box.typ": shadow-box

/// Create the SVG element as a string, embedding the video tag within it.
#let video-to-svg(video-path) = {
  let ext = video-path.split(".").last()
  let svg-template = ```
    <svg xmlns="http://www.w3.org/2000/svg">
    <foreignObject width="100%" height="100%">
        <video xmlns="http://www.w3.org/1999/xhtml" width="100%" height="100%" controls="" >
            <source src="{video-path}" type="video/{ext}" />
        </video>
    </foreignObject>
    </svg>
  ```.text
  svg-template.replace("{video-path}", video-path).replace(
    "{ext}", ext
  )
}
