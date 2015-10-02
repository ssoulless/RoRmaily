RoRmaily Version Naming Convention
----------------------------------
RoRmaily uses a basic **Semantic Versioning** that consists of 3 levels MAJOR.MINOR.PATCH (3 digits separated by dots):

* MAJOR version: This is when API has been changed in a manner that makes previous versions incompatible if users update.
* MINOR version: When new functionality is added in a way that will not break existing users code if they update.
* PATHC version: small changes such as bug fixes that are not adding new features and will not break current users code if they update.

For more information go to [Semantic Versioning docs](http://semver.org/). We are also following the Patterns provided by [RubyGems guides](http://guides.rubygems.org/patterns/) the oficial guidelines for Ruby gems conventions that is also based in Semantic Versioning.
