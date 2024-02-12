#import "/toolbox.typ": git-graph
#import git-graph: *
#set page(width: auto, height: auto, fill: black)

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