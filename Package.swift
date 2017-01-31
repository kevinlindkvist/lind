import PackageDescription

let package = Package(
    name: "lind",
    targets: [ Target(name: "albovagen", dependencies: ["full"]) ],
    dependencies: [ .Package(url: "git@github.com:antitypical/Result.git", majorVersion: 3) ]
)
