## Commits

The commit messages pushed to the central repo will follow this format: `[emoji] [action] #[item_id]: phrase`.
> Example: `🐛 Fixes #1111: Removed duplicates`

- `emoji`: Emojis are used to increase the version number automatically based on some predefined rules and following the [Semantic Versioning Specification (SemVer)](https://semver.org/). Adding an emoji is optional, although it's encouraged, especially when making any improvement that could be noticed by the end user. You're free to use an emoji not listed below. Be aware that in this case the commit message on its own won't trigger a new release.
- `action`: Single-word action, which should always be a verb in the present tense. Some examples: `Fix`, `Closes`, etc.
- `item_id`: ID of the DevOps work item. This will automatically link the commit with the referenced work item. **Do not forget to add the `#` before the ID.**
- `phrase`: All your commit messages should be written in English. Please start the first word of the sentence with a capital letter.

This naming convention ensures a clear commit history, automatic workitem linking, and automatic versioning. These are the emojis that are currently parsed by our CI/CD pipeline:
|Change type|Available Emojis|
|-|-|
|Major|💥 Introduce breaking changes.|
|Minor|✨ Introduce new features.<br/>🏗️ Make architectural changes.<br/>♻️ Refactor code.<br/>⚡️ Improve performance.<br/>👽️ Update code due to external API changes.|
|Patch|🚑️ Critical hotfix.<br/>🔒️ Fix security issues.<br/>🐛 Fix a bug.<br/>🥅 Catch errors.<br/>🔐 Add or update secrets.<br/>📌 Pin dependencies to specific versions.<br/>🔧 Add or update configuration files.<br/>🌐 Internationalization and localization.<br/>💬 Add or update text and literals.<br/>📝Add or update documentation.|

For more emojis, please check out [gitmoji](https://gitmoji.dev/). If you want a new emoji to be recognised by the CI/CD pipeline, you will need to add it to the [autoversionging script](./devops/scripts/get_autoversion_bump.py).
