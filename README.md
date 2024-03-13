# deploy-script

## Script options
| option | name        | value                                                                             |
|--------|-------------|-----------------------------------------------------------------------------------|
| -v     | version     | semantic versioning label (**required**): major, minor, patch or dry (to dry-run) |
| -m     | main_branch | name of repository main branch (**default master**): main, master, ...            |

## Publish

All the tagged commits generate a new version on scoped package https://www.npmjs.com/package/@zityhub/deploy-script.
To generate a new version you must use in the main branch `pnpm version [major|minor|patch]` to update the version and generate the expected tag.
Don't forgot to push the new commit and tag with `git push origin main --tags`, GitHub Actions will publish the package.
