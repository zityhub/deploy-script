# deploy-script

## Script options
| option | name        | value                                                                             |
|--------|-------------|-----------------------------------------------------------------------------------|
| -v     | version     | semantic versioning label (**required**): major, minor, patch or dry (to dry-run) |
| -m     | main_branch | name of repository main branch (**default master**): main, master, ...            |

## Publish

We are currently publishing the npm packages inside GitHub Packages.
All the tagged commits generate a package which is stored inside the private registry and make it available to other projects.
To generate a new version you must use in the master branch `pnpm version [major|minor|patch]` to update the version and generate the expected tag.
Don't forgot to push the new commit and tag with `git push origin main --tags`, CircleCI will make the magic (build, test and publish).
