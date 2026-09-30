#!/bin/zsh
# Commits the working tree as a new tagged release.
#
#   scripts/release.sh [patch|minor|major|X.Y.Z] "What changed"
#
# Bumps VERSION, runs the self-test, rebuilds download/Claude Deck.dmg, adds a CHANGELOG entry,
# commits, tags vX.Y.Z, pushes, and publishes a GitHub Release with the .dmg attached.
set -euo pipefail
cd "$(dirname "$0")/.."

BUMP=${1:-}
NOTES=${2:-}
if [[ -z "$BUMP" || -z "$NOTES" ]]; then
  echo "usage: scripts/release.sh [patch|minor|major|X.Y.Z] \"What changed\"" >&2
  exit 1
fi

CURRENT=$(tr -d '[:space:]' < VERSION)
IFS=. read -r MAJOR MINOR PATCH <<< "$CURRENT"
case "$BUMP" in
  patch) NEW="$MAJOR.$MINOR.$((PATCH + 1))" ;;
  minor) NEW="$MAJOR.$((MINOR + 1)).0" ;;
  major) NEW="$((MAJOR + 1)).0.0" ;;
  <->.<->.<->) NEW="$BUMP" ;;
  *) echo "✗ Version must be patch, minor, major or X.Y.Z (got '$BUMP')" >&2; exit 1 ;;
esac
TAG="v$NEW"

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "✗ Tag $TAG already exists" >&2; exit 1
fi
if [[ "$(git branch --show-current)" != "main" ]]; then
  echo "✗ Releases are made from main" >&2; exit 1
fi

echo "▸ Releasing $CURRENT → $NEW"
echo "$NEW" > VERSION

echo "▸ Running self-test"
swift build >/dev/null
if ! .build/debug/ClaudeDeck --selftest 2>&1 | tail -1 | grep -q "ALL PASSED"; then
  echo "$CURRENT" > VERSION
  echo "✗ Self-test failed; nothing was committed. Run .build/debug/ClaudeDeck --selftest to see why." >&2
  exit 1
fi

# The release commit will be the next one, so its build number is the current count + 1.
BUILD=$(( $(git rev-list --count HEAD) + 1 )) scripts/build_app.sh
mkdir -p download
cp "dist/Claude Deck.dmg" "download/Claude Deck.dmg"

echo "▸ Updating CHANGELOG.md"
ENTRY="## $TAG ($(date +%Y-%m-%d))"$'\n\n'"- $NOTES"$'\n'
if [[ -f CHANGELOG.md ]]; then
  { head -n 2 CHANGELOG.md; echo "$ENTRY"; tail -n +3 CHANGELOG.md; } > CHANGELOG.md.tmp
  mv CHANGELOG.md.tmp CHANGELOG.md
else
  printf '# Changelog\n\n%s' "$ENTRY" > CHANGELOG.md
fi

echo "▸ Committing and tagging $TAG"
git add -A
git commit -q -m "$TAG: $NOTES"
git tag -a "$TAG" -m "$TAG: $NOTES"
git push -q origin main "$TAG"

echo "▸ Publishing GitHub Release"
ASSET="$(mktemp -d)/Claude-Deck-$NEW.dmg"
cp "dist/Claude Deck.dmg" "$ASSET"
gh release create "$TAG" "$ASSET" --title "Claude Deck $NEW" --notes "$NOTES" --latest

echo "✓ Released $TAG"
