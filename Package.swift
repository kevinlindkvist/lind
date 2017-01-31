import PackageDescription

let package = Package(
    name: "lind",
    dependencies: [ .Package(url: "git@github.com:antitypical/Result.git", majorVersion: 3) ]
)
