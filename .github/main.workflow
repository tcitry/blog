workflow "Push to page" {
  on = "push"
  resolves = [
    "benmatselby/hugo-deploy-gh-pages@master",
  ]
}

action "hugo" {
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "benmatselby/hugo-deploy-gh-pages@master" {
  needs = "master"
  uses = "benmatselby/hugo-deploy-gh-pages@master"
  env = {
    TARGET_REPO = "tcitry/tcitry.github.io"
    HUGO_VERSION = "0.54.0"
  }
  secrets = ["TOKEN"]
}
