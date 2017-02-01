import PackageDescription

let package = Package(
    name: "lind",
    targets: [ 
      Target(name: "full", dependencies: ["parser"]),
      Target(name: "simplytypedlambda", dependencies: ["parser"]),
      Target(name: "untypedlambda", dependencies: ["parser"]),
      Target(name: "untypedarithmetic", dependencies: ["parser"]),
      Target(name: "albovagen", dependencies: ["full"]),
      ],
      dependencies: [ .Package(url: "git@github.com:antitypical/Result.git", majorVersion: 3) ]
)
