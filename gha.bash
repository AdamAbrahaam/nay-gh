#!/bin/bash

newPR () {
  eval "cd ~/repos/$4/"
  eval "git add ."
  eval "git commit -m ' #$3 $1'"
  eval "git push --set-upstream origin $2"

  pr_url=$(eval "gh pr create --title '#$3 $1' --body 'PR k #$3' --web")
  echo -e $pr_url
}

merge () {
  echo 'TODO'
}

read -p "repo (tool[T], eshop[E])?: " repo || exit 1
repo=$(tr '[:upper:]' '[:lower:]'<<<${repo})

case $repo in
  t | tool)
    repo='naytool'
    ;;
  e | eshop)
    repo='nayeshop'
    ;;
  *)
    exit 1
    ;;
esac

currentBranch=$(eval "cd ~/repos/$repo/ && git rev-parse --symbolic-full-name --abbrev-ref HEAD")
issue=(${currentBranch//-/ }[0])

read -p "action (new[N], merge[M])?: " action || exit 1
action=$(tr '[:upper:]' '[:lower:]'<<<${action})

read -p "branch (${currentBranch}?): " branch
[[ -z "$branch" ]] && branch=${currentBranch}

currentIssueTitle=$(eval "gh issue view https://github.com/peckadesign/$repo/issues/$issue --json title")
currentIssueTitle=$(eval "node -pe 'JSON.parse(process.argv[1]).title' '$currentIssueTitle'")
currentIssueTitle=$(echo "$currentIssueTitle" | cut -d "-" -f 2)

if [ $? -ne 0 ]; then
  currentIssueTitle=$(echo "$currentIssueTitle" | cut -d ":" -f 2)
fi

read -p "commit message ('$currentIssueTitle'?): " commit
[[ -z "$commit" ]] && commit=${currentIssueTitle}

case $action in
  n | new)
    newPR "$commit" "$branch" "$issue" "$repo"
    ;;
  m | merge)
    merge
    ;;
  *)
    exit 1
    ;;
esac

