# How to contribute
Contributions are always welcome, however, to keep things consistent, please review the following guidelines.

## Update unit tests
If you change a core piece of functionality (i.e. in ```lib/*```) then ensure the corresponding unit tests in the ```spec``` folder are updated.

For more information on writing unit tests with RSpec, see https://relishapp.com/rspec

## Ensure RuboCop approves
Unless there's good reason, there should be no [RuboCop](https://github.com/bbatsov/rubocop) warnings for any code you submit a pull request for. Sensible exceptions will be made, but try to keep warnings to a minimum.

## Target the development branch
When opening a pull request, compare with the ```development``` branch, rather than ```master```. The master branch is aimed at being equal to the latest stable release; meaning all staged changes need to go into the ```development``` branch.
