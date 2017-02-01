import PackageDescription

let package = Package(
    name: "lind",
    targets: [ 
      Target(name: "FullSimple", dependencies: ["Parser"]),
      Target(name: "Simple", dependencies: ["Parser"]),
      Target(name: "Untyped", dependencies: ["Parser"]),
      Target(name: "UntypedArithmetic", dependencies: ["Parser"]),
      Target(name: "Albovagen", dependencies: ["FullSimple"]),
      ],
      dependencies: [ .Package(url: "git@github.com:antitypical/Result.git", majorVersion: 3) ]
)
