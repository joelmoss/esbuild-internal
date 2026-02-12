# esbuild-internal

Exports [esbuild](https://esbuild.github.io/) internal packages.

## Releasing

After a new release is created at github.com/joelmoss/esbuild, the internal packages can be updated with the following steps:

1. Execute `./update.sh ?` (without the 'v' prefix, eg. `./update.sh 0.17.19`) to update the internal packages and commit the changes.
2. Create `git tag "v${version}" [revision]` to create a git tag for the new version.
3. Push the changes and tags to the remote repository with `git push origin --tags`.

Note that the version should match the version of esbuild that was released at github.com/joelmoss/esbuild, and appended with the short commit hash. For example, if the latest release at github.com/joelmoss/esbuild is v0.17.19, and the commit hash is abc123, then the command to update the internal packages should be `./update.sh 0.17.19-abc123`.