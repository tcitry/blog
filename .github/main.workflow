workflow "Push to master" {
  on = "push"
  resolves = [
    "publish-hugo-site",
  ]
}

action "hugo branch" {
  uses = "actions/bin/filter@master"
  args = "branch hugo"
}

action "publish-hugo-site" {
  needs = "hugo branch"
  uses = "tcitry/publish-hugo-site@master"
  env = {
    TARGET_REPO = "tcitry/tcitry.github.io"
  }
  secrets = ["TOKEN"]
}
