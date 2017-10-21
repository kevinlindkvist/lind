import PackageDescription

let package = Package(
    name: "lind",
    targets: [ 
      Target(name: "FullSimple"), 
      Target(name: "Simple"),
      Target(name: "Untyped"),
      Target(name: "UntypedArithmetic"),
      Target(name: "Albovagen", dependencies: ["FullSimple"]),
      ],
      dependencies: [ 
      .Package(url: "git@github.com:kevinlindkvist/Parswift.git", majorVersion: 1),
      ]
)
